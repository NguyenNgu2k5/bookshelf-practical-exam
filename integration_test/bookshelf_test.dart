import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:bookshelf/firebase_options.dart';
import 'package:bookshelf/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late FirebaseFirestore db;
  late FirebaseAuth auth;
  late String uid;
  late BookStore store;
  const password = 'Audit123!';

  BookDraft draft(String title, {int? rating, String notes = ''}) => BookDraft(
    title: title,
    author: 'Audit Author',
    genre: 'Fiction',
    status: 'To Read',
    rating: rating,
    notes: notes,
  );
  Future<Book> readBook(String id) async {
    final rows = await db
        .collection('books')
        .where('userId', isEqualTo: uid)
        .get(const GetOptions(source: Source.server));
    return Book.fromDocument(rows.docs.singleWhere((d) => d.id == id));
  }

  String part(String s) => s
      .trim()
      .toLowerCase()
      .replaceAll('%', '%25')
      .replaceAll('/', '%2F')
      .replaceAll('_', '%5F');
  Future<void> write(Map<String, dynamic> changes, {String? forcedId}) async {
    final data = draft(
      'Rules valid',
    ).toMap(id: '', uid: uid, createdAt: Timestamp.now())..addAll(changes);
    final id =
        forcedId ??
        '${uid}__${part(data['title'] as String)}__${part(data['author'] as String)}';
    data['id'] = id;
    await db.collection('books').doc(id).set(data);
  }

  final denied = throwsA(
    isA<FirebaseException>().having((e) => e.code, 'code', 'permission-denied'),
  );

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    auth = FirebaseAuth.instance;
    await auth.useAuthEmulator('10.0.2.2', 9095);
    db = FirebaseFirestore.instance;
    db.settings = const Settings(persistenceEnabled: false);
    db.useFirestoreEmulator('10.0.2.2', 8085);
    final user = await auth.createUserWithEmailAndPassword(
      email: 'audit-primary@example.com',
      password: password,
    );
    uid = user.user!.uid;
    store = BookStore(uid);
  });

  testWidgets('Rules reject every invalid field and forged duplicate ID', (
    tester,
  ) async {
    for (final bad in <Map<String, dynamic>>[
      {'title': ''},
      {'title': '   '},
      {'title': 'T' * 101},
      {'author': ''},
      {'author': '   '},
      {'author': 'A' * 61},
      {'genre': 'Invalid'},
      {'status': 'Invalid'},
      {'rating': -1},
      {'rating': 6},
      {'rating': 1.5},
      {'rating': '5'},
      {'notes': 'N' * 301},
      {'userId': 'someone-else'},
    ]) {
      await expectLater(write(bad), denied, reason: bad.keys.join(','));
    }
    await write({
      'title': 'T' * 100,
      'author': 'A' * 60,
      'notes': 'N' * 300,
      'rating': 0,
    });
    await write({'title': 'Boundary five', 'rating': 5});
    await write({});
    await expectLater(write({}, forcedId: '${uid}__forged_duplicate'), denied);
    await expectLater(
      db.collection('books').doc('${uid}__missing_title').set({
        'id': '${uid}__missing_title',
        'userId': uid,
      }),
      denied,
    );
    final one = await store.add(draft('Case duplicate'));
    await expectLater(
      store.add(draft('cASE DUPLICATE')),
      throwsA(isA<Exception>()),
    );
    expect((await readBook(one)).title, 'Case duplicate');
  });

  testWidgets('Updating a deleted book never recreates it, including rename', (
    tester,
  ) async {
    final id = await store.add(draft('Deleted book'));
    final original = await readBook(id);
    await store.delete(original);
    await expectLater(
      store.update(original, draft('Deleted book', notes: 'stale')),
      throwsStateError,
    );
    await expectLater(
      store.update(original, draft('Renamed deleted book')),
      throwsStateError,
    );
    expect((await db.collection('books').doc(id).get()).exists, isFalse);
  });

  testWidgets(
    'Edit keeps current favorite and creation time; rename is atomic',
    (tester) async {
      final id = await store.add(draft('Edit original', rating: 4));
      final original = await readBook(id);
      await store.setFavorite(original, true);
      await store.update(original, draft('Edit original', notes: 'updated'));
      final edited = await readBook(id);
      expect(edited.favorite, isTrue);
      expect(edited.rating, isNull);
      expect(edited.createdAt, original.createdAt);
      final target = await store.add(draft('Existing target'));
      await expectLater(
        store.update(edited, draft('Existing target')),
        throwsA(isA<Exception>()),
      );
      expect((await db.collection('books').doc(id).get()).exists, isTrue);
      expect((await db.collection('books').doc(target).get()).exists, isTrue);
      final renamed = await store.update(
        edited,
        draft('Edit renamed', notes: 'renamed'),
      );
      expect((await db.collection('books').doc(id).get()).exists, isFalse);
      expect((await readBook(renamed)).favorite, isTrue);
    },
  );

  testWidgets('Search keeps focus; edit validates, saves and cancels', (
    tester,
  ) async {
    final id = await store.add(draft('Widget original'));
    await tester.pumpWidget(const BookShelfApp());
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'widget');
    await tester.pumpAndSettle();
    expect(find.text('Widget original'), findsOneWidget);
    expect(find.text('Books: 1'), findsOneWidget);
    await tester.tap(find.text('Widget original'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), '');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();
    expect(find.text('Title is required'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField).at(0), 'Widget renamed');
    await tester.tap(find.text('Save'));
    await tester.pump();
    final cancel = find.widgetWithText(TextButton, 'Cancel');
    if (cancel.evaluate().isNotEmpty) {
      expect(tester.widget<TextButton>(cancel).onPressed, isNull);
      final scopes = tester.widgetList<PopScope>(find.byType(PopScope));
      expect(scopes.any((p) => !p.canPop), isTrue);
    }
    await tester.pumpAndSettle();
    expect(find.text('Widget renamed'), findsOneWidget);
    expect(find.text('Edit'), findsOneWidget);
    expect((await db.collection('books').doc(id).get()).exists, isFalse);
    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).at(0), 'Should not save');
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.text('Widget renamed'), findsOneWidget);
    expect(find.text('Should not save'), findsNothing);
  });

  testWidgets(
    'Different users and visitors cannot read or write another shelf',
    (tester) async {
      await tester.pumpWidget(const SizedBox());
      final id = await store.add(draft('Private book'));
      await auth.signOut();
      await expectLater(
        db
            .collection('books')
            .doc(id)
            .get(const GetOptions(source: Source.server)),
        denied,
      );
      await expectLater(write({}), denied);
      final other = await auth.createUserWithEmailAndPassword(
        email: 'audit-other@example.com',
        password: password,
      );
      await expectLater(
        db
            .collection('books')
            .doc(id)
            .get(const GetOptions(source: Source.server)),
        denied,
      );
      await expectLater(
        db.collection('books').doc(id).update({'notes': 'intrusion'}),
        denied,
      );
      await expectLater(db.collection('books').doc(id).delete(), denied);
      final rows = await db
          .collection('books')
          .where('userId', isEqualTo: other.user!.uid)
          .get();
      expect(rows.docs, isEmpty);
      final second = BookStore(other.user!.uid);
      await second.add(draft('Private book'));
      expect((await second.watchBooks().first).length, 1);
    },
  );
}
