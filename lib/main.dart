import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

const _pine = Color(0xFF183E38);
const _paper = Color(0xFFF5F2EA);
const _coral = Color(0xFFE27B52);
const _ink = Color(0xFF202925);
const _muted = Color(0xFF69756F);
final _messengerKey = GlobalKey<ScaffoldMessengerState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Object? startupError;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    startupError = error;
  }
  runApp(BookShelfApp(startupError: startupError));
}

class BookShelfApp extends StatelessWidget {
  const BookShelfApp({super.key, this.startupError});

  final Object? startupError;

  @override
  Widget build(BuildContext context) {
    final colors = ColorScheme.fromSeed(
      seedColor: _pine,
      surface: _paper,
    ).copyWith(primary: _pine, secondary: _coral);
    return MaterialApp(
      title: 'BookShelf',
      scaffoldMessengerKey: _messengerKey,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: colors,
        scaffoldBackgroundColor: _paper,
        appBarTheme: const AppBarTheme(
          backgroundColor: _paper,
          foregroundColor: _ink,
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE4E6DF)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: _pine, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 15,
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: _pine,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineMedium: TextStyle(
            color: _ink,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.8,
          ),
          titleLarge: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          titleMedium: TextStyle(color: _ink, fontWeight: FontWeight.w600),
          bodyMedium: TextStyle(color: _muted, height: 1.45),
        ),
      ),
      home: startupError == null
          ? const _AuthGate()
          : _StartupError(error: startupError!),
    );
  }
}

class _StartupError extends StatelessWidget {
  const _StartupError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Text(
          'Firebase setup is incomplete.\n\n$error',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return _StartupError(error: snapshot.error!);
        }
        final user = snapshot.data;
        return user == null ? const _HomeScreen() : _BookListScreen(user: user);
      },
    );
  }
}

class _HomeScreen extends StatelessWidget {
  const _HomeScreen();

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_rounded, color: _pine),
          SizedBox(width: 9),
          Text('BookShelf'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => _openAuth(context, register: false),
          child: const Text('Login'),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilledButton.tonal(
            onPressed: () => _openAuth(context, register: true),
            child: const Text('Register'),
          ),
        ),
      ],
    ),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(22, 18, 22, 32),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(26),
                  decoration: BoxDecoration(
                    color: _pine,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.auto_stories_rounded,
                        color: Color(0xFFFFC88D),
                        size: 36,
                      ),
                      const SizedBox(height: 26),
                      const Text(
                        'BookShelf',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 38,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.2,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Your books, your reading rhythm.',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Keep the books you own and the ones you want to read together in one calm, personal place.',
                        style: TextStyle(color: Colors.white70, height: 1.55),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'A little more order for your next chapter.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 14),
                const _FeatureCard(
                  icon: Icons.library_books_outlined,
                  title: 'Track your books',
                  detail: 'Keep your personal collection close at hand.',
                ),
                const SizedBox(height: 10),
                const _FeatureCard(
                  icon: Icons.swap_vert_rounded,
                  title: 'Sort by status',
                  detail: 'See what is next, in progress, or finished.',
                ),
                const SizedBox(height: 10),
                const _FeatureCard(
                  icon: Icons.star_outline_rounded,
                  title: 'Rate your favorites',
                  detail: 'Save a rating and notes for each book.',
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  static void _openAuth(BuildContext context, {required bool register}) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => _AuthScreen(register: register)),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.detail,
  });

  final IconData icon;
  final String title;
  final String detail;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE8E7E0)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 17, vertical: 7),
      leading: CircleAvatar(
        backgroundColor: const Color(0xFFE8F0EA),
        foregroundColor: _pine,
        child: Icon(icon),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleMedium),
      subtitle: Text(detail),
    ),
  );
}

class _AuthScreen extends StatefulWidget {
  const _AuthScreen({required this.register});

  final bool register;

  @override
  State<_AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<_AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _submitted = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  String? _emailError(String? value) {
    final email = value?.trim() ?? '';
    if (email.isEmpty) return 'Email is required';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  String? _passwordError(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (widget.register && value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _confirmError(String? value) {
    if (value == null || value.isEmpty) return 'Confirm password is required';
    if (value != _password.text) return 'Passwords do not match';
    return null;
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _error = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      if (widget.register) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        _messengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Registration successful')),
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } on FirebaseAuthException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? error.code);
      }
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heading = widget.register ? 'Register' : 'Login';
    return Scaffold(
      appBar: AppBar(title: Text(heading)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 500),
              child: Card(
                color: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: Color(0xFFE8E7E0)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: _submitted
                        ? AutovalidateMode.onUserInteraction
                        : AutovalidateMode.disabled,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          heading,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 7),
                        Text(
                          widget.register
                              ? 'Create an account for your personal shelf.'
                              : 'Sign in to your personal shelf.',
                        ),
                        const SizedBox(height: 22),
                        TextFormField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          autofillHints: const [AutofillHints.email],
                          decoration: const InputDecoration(labelText: 'Email'),
                          validator: _emailError,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _password,
                          obscureText: true,
                          textInputAction: widget.register
                              ? TextInputAction.next
                              : TextInputAction.done,
                          autofillHints: [
                            widget.register
                                ? AutofillHints.newPassword
                                : AutofillHints.password,
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Password',
                          ),
                          validator: _passwordError,
                          onChanged: (_) => setState(() {}),
                          onFieldSubmitted: (_) {
                            if (!widget.register) _submit();
                          },
                        ),
                        if (widget.register) ...[
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _confirm,
                            obscureText: true,
                            textInputAction: TextInputAction.done,
                            decoration: const InputDecoration(
                              labelText: 'Confirm password',
                            ),
                            validator: _confirmError,
                            onChanged: (_) => setState(() {}),
                            onFieldSubmitted: (_) => _submit(),
                          ),
                        ],
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: _busy ? null : _submit,
                          child: _busy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(heading),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class Book {
  const Book({
    required this.id,
    required this.userId,
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.favorite,
    required this.notes,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final bool favorite;
  final String notes;
  final Timestamp createdAt;

  factory Book.fromDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();
    return Book(
      id: document.id,
      userId: data['userId'] as String,
      title: data['title'] as String,
      author: data['author'] as String,
      genre: data['genre'] as String,
      status: data['status'] as String,
      rating: data['rating'] as int?,
      favorite: data['favorite'] as bool,
      notes: data['notes'] as String? ?? '',
      createdAt: data['createdAt'] as Timestamp,
    );
  }
}

class BookDraft {
  const BookDraft({
    required this.title,
    required this.author,
    required this.genre,
    required this.status,
    required this.rating,
    required this.notes,
  });

  final String title;
  final String author;
  final String genre;
  final String status;
  final int? rating;
  final String notes;

  Map<String, dynamic> toMap({
    required String id,
    required String uid,
    required Object createdAt,
    bool favorite = false,
  }) {
    final data = <String, dynamic>{
      'id': id,
      'userId': uid,
      'title': title,
      'author': author,
      'genre': genre,
      'status': status,
      'favorite': favorite,
      'notes': notes,
      'createdAt': createdAt,
    };
    if (rating != null) data['rating'] = rating;
    return data;
  }
}

String _normalizedPart(String value) => value
    .trim()
    .toLowerCase()
    .replaceAll('%', '%25')
    .replaceAll('/', '%2F')
    .replaceAll('_', '%5F');

String _bookId(String uid, String title, String author) =>
    '${uid}__${_normalizedPart(title)}__${_normalizedPart(author)}';

class BookStore {
  BookStore(this.uid);

  final String uid;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _books =>
      _db.collection('books');

  Stream<List<Book>> watchBooks() => _books
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Book.fromDocument).toList());

  Future<String> add(BookDraft draft) async {
    final id = _bookId(uid, draft.title, draft.author);
    final reference = _books.doc(id);
    final added = await _db.runTransaction((transaction) async {
      final existing = await transaction.get(reference);
      if (existing.exists) return false;
      transaction.set(
        reference,
        draft.toMap(id: id, uid: uid, createdAt: FieldValue.serverTimestamp()),
      );
      return true;
    });
    if (!added) throw _DuplicateBookException();
    return id;
  }

  Future<String> update(Book original, BookDraft draft) async {
    final id = _bookId(uid, draft.title, draft.author);
    final oldReference = _books.doc(original.id);
    final newReference = _books.doc(id);
    final updated = await _db.runTransaction<bool?>((transaction) async {
      final current = await transaction.get(oldReference);
      if (!current.exists) return null;
      if (id != original.id) {
        final existing = await transaction.get(newReference);
        if (existing.exists) return false;
      }
      transaction.set(
        newReference,
        draft.toMap(
          id: id,
          uid: uid,
          createdAt: current.data()!['createdAt'],
          favorite: current.data()!['favorite'] as bool,
        ),
      );
      if (id != original.id) transaction.delete(oldReference);
      return true;
    });
    if (updated == null) throw StateError('This book no longer exists');
    if (!updated) throw _DuplicateBookException();
    return id;
  }

  Future<void> setFavorite(Book book, bool favorite) =>
      _books.doc(book.id).update({'favorite': favorite});

  Future<void> delete(Book book) => _books.doc(book.id).delete();
}

class _DuplicateBookException implements Exception {
  @override
  String toString() => 'A book with this title and author already exists.';
}

class _BookListScreen extends StatefulWidget {
  const _BookListScreen({required this.user});

  final User user;

  @override
  State<_BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<_BookListScreen> {
  late final BookStore _store = BookStore(widget.user.uid);
  late final Stream<List<Book>> _books = _store.watchBooks();
  final _search = TextEditingController();
  String _genre = 'All';
  String _status = 'All';
  bool _favoritesOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _showError(Object error) {
    final message = error is FirebaseException
        ? error.message ?? error.code
        : error.toString();
    _messengerKey.currentState?.showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
    } catch (error) {
      _showError(error);
    }
  }

  Future<void> _toggleFavorite(Book book) async {
    try {
      await _store.setFavorite(book, !book.favorite);
    } catch (error) {
      _showError(error);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('BookShelf'),
            Text(
              widget.user.email ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _logout,
            icon: const Icon(Icons.logout_rounded, size: 18),
            label: const Text('Logout'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => _AddBookScreen(store: _store),
          ),
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Book'),
        backgroundColor: _pine,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: StreamBuilder<List<Book>>(
          stream: _books,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load books: ${snapshot.error}'),
                ),
              );
            }
            final allBooks = [...?snapshot.data];
            final query = _search.text.trim().toLowerCase();
            final books =
                allBooks.where((book) {
                  return (_genre == 'All' || book.genre == _genre) &&
                      (_status == 'All' || book.status == _status) &&
                      (!_favoritesOnly || book.favorite) &&
                      (query.isEmpty ||
                          book.title.toLowerCase().contains(query) ||
                          book.author.toLowerCase().contains(query));
                }).toList()..sort((a, b) {
                  final byTitle = a.title.toLowerCase().compareTo(
                    b.title.toLowerCase(),
                  );
                  return byTitle != 0
                      ? byTitle
                      : a.author.toLowerCase().compareTo(
                          b.author.toLowerCase(),
                        );
                });
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 100),
              children: [
                _filterCard(context),
                const SizedBox(height: 12),
                _summaryCard(context, books),
                const SizedBox(height: 16),
                if (books.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 36),
                    child: Center(child: Text('No books found')),
                  )
                else
                  ...books.map(
                    (book) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _BookTile(
                        book: book,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                _DetailScreen(store: _store, book: book),
                          ),
                        ),
                        onFavorite: () => _toggleFavorite(book),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    ),
  );

  Widget _filterCard(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: const BorderSide(color: Color(0xFFE8E7E0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        children: [
          TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              labelText: 'Search title or author',
              prefixIcon: Icon(Icons.search_rounded),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_genre),
                  initialValue: _genre,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Genre',
                    isDense: true,
                  ),
                  items: ['All', 'Fiction', 'Non-Fiction', 'Academic', 'Other']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => _genre = value ?? 'All'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  key: ValueKey(_status),
                  initialValue: _status,
                  isExpanded: true,
                  decoration: const InputDecoration(
                    labelText: 'Status',
                    isDense: true,
                  ),
                  items: ['All', 'To Read', 'Reading', 'Finished']
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      )
                      .toList(),
                  onChanged: (value) =>
                      setState(() => _status = value ?? 'All'),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            dense: true,
            title: const Text('Favorites only'),
            value: _favoritesOnly,
            onChanged: (value) => setState(() => _favoritesOnly = value),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () => setState(() {
                _genre = 'All';
                _status = 'All';
                _favoritesOnly = false;
                _search.clear();
              }),
              icon: const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Clear'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _summaryCard(BuildContext context, List<Book> books) {
    final counts = <String, int>{};
    for (final book in books) {
      counts.update(book.status, (oldCount) => oldCount + 1, ifAbsent: () => 1);
    }
    const statusOrder = ['To Read', 'Reading', 'Finished'];
    final statuses = counts.keys.toList()
      ..sort((a, b) {
        final byCount = counts[b]!.compareTo(counts[a]!);
        return byCount != 0
            ? byCount
            : statusOrder.indexOf(a).compareTo(statusOrder.indexOf(b));
      });
    return Card(
      color: const Color(0xFFE8F0EA),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(17, 14, 17, 13),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 22,
              runSpacing: 6,
              children: [
                Text(
                  'Books: ${books.length}',
                  style: const TextStyle(
                    color: _pine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  'Favorites: ${books.where((book) => book.favorite).length}',

                  style: const TextStyle(
                    color: _pine,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            if (statuses.isNotEmpty) ...[
              const SizedBox(height: 8),
              for (final status in statuses)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('$status: ${counts[status]}'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({
    required this.book,
    required this.onTap,
    required this.onFavorite,
  });

  final Book book;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: const BorderSide(color: Color(0xFFE8E7E0)),
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(book.author),
                  const SizedBox(height: 9),
                  Wrap(
                    spacing: 7,
                    runSpacing: 6,
                    children: [
                      _Tag(label: book.genre),
                      _Tag(label: book.status),
                    ],
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            tooltip: book.favorite
                ? 'Remove from favorites'
                : 'Add to favorites',
            onPressed: onFavorite,
            icon: Icon(
              book.favorite ? Icons.star_rounded : Icons.star_border_rounded,
              color: book.favorite ? _coral : _muted,
            ),
          ),
        ],
      ),
    ),
  );
}

class _Tag extends StatelessWidget {
  const _Tag({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFFF1F2ED),
      borderRadius: BorderRadius.circular(30),
    ),
    child: Text(
      label,
      style: Theme.of(context).textTheme.labelMedium?.copyWith(color: _pine),
    ),
  );
}

class _AddBookScreen extends StatelessWidget {
  const _AddBookScreen({required this.store});

  final BookStore store;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Add Book')),
    body: SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 30),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: _BookForm(
              onSave: store.add,
              onSaved: (_) {
                _messengerKey.currentState?.showSnackBar(
                  const SnackBar(content: Text('Book added')),
                );
                Navigator.of(context).pop();
              },
            ),
          ),
        ),
      ),
    ),
  );
}

class _BookForm extends StatefulWidget {
  const _BookForm({
    super.key,
    required this.onSave,
    this.initial,
    this.onSaved,
    this.showSubmitButton = true,
  });

  final Future<String> Function(BookDraft draft) onSave;
  final Book? initial;
  final ValueChanged<String>? onSaved;
  final bool showSubmitButton;

  @override
  State<_BookForm> createState() => _BookFormState();
}

class _BookFormState extends State<_BookForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.initial?.title ?? '');
  late final _author = TextEditingController(
    text: widget.initial?.author ?? '',
  );
  late final _rating = TextEditingController(
    text: widget.initial?.rating?.toString() ?? '',
  );
  late final _notes = TextEditingController(text: widget.initial?.notes ?? '');
  late String _genre = widget.initial?.genre ?? '';
  late String _status = widget.initial?.status ?? '';
  bool _submitted = false;
  bool _busy = false;
  String? _message;

  @override
  void dispose() {
    _title.dispose();
    _author.dispose();
    _rating.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (_busy) return;
    setState(() {
      _submitted = true;
      _message = null;
    });
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    final ratingText = _rating.text.trim();
    try {
      final id = await widget.onSave(
        BookDraft(
          title: _title.text,
          author: _author.text,
          genre: _genre,
          status: _status,
          rating: ratingText.isEmpty ? null : int.parse(ratingText),
          notes: _notes.text,
        ),
      );
      if (!mounted) return;
      if (widget.initial == null) {
        _title.clear();
        _author.clear();
        _rating.clear();
        _notes.clear();
        _formKey.currentState!.reset();
        setState(() {
          _genre = '';
          _status = '';
          _submitted = false;
          _message = 'Book added';
        });
      } else {
        setState(() => _message = 'Book updated');
      }
      widget.onSaved?.call(id);
    } catch (error) {
      if (mounted) {
        final message = error is FirebaseException
            ? error.message ?? error.code
            : error.toString();
        setState(() => _message = message);
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Card(
    color: Colors.white,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(22),
      side: const BorderSide(color: Color(0xFFE8E7E0)),
    ),
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Form(
        key: _formKey,
        autovalidateMode: _submitted
            ? AutovalidateMode.onUserInteraction
            : AutovalidateMode.disabled,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              controller: _title,
              textCapitalization: TextCapitalization.sentences,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Title'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Title is required';
                }
                if (value.runes.length > 100) {
                  return 'Title must be at most 100 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _author,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'Author'),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Author is required';
                }
                if (value.runes.length > 60) {
                  return 'Author must be at most 60 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _genre,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Genre'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Choose genre')),
                DropdownMenuItem(value: 'Fiction', child: Text('Fiction')),
                DropdownMenuItem(
                  value: 'Non-Fiction',
                  child: Text('Non-Fiction'),
                ),
                DropdownMenuItem(value: 'Academic', child: Text('Academic')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) => setState(() => _genre = value ?? ''),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please choose a genre'
                  : null,
            ),
            const SizedBox(height: 13),
            DropdownButtonFormField<String>(
              initialValue: _status,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Status'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Choose status')),
                DropdownMenuItem(value: 'To Read', child: Text('To Read')),
                DropdownMenuItem(value: 'Reading', child: Text('Reading')),
                DropdownMenuItem(value: 'Finished', child: Text('Finished')),
              ],
              onChanged: (value) => setState(() => _status = value ?? ''),
              validator: (value) => value == null || value.isEmpty
                  ? 'Please choose a status'
                  : null,
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _rating,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: false,
                signed: false,
              ),
              decoration: const InputDecoration(
                labelText: 'Rating (optional)',
                hintText: '0 to 5',
              ),
              validator: (value) {
                final rating = value?.trim() ?? '';
                if (rating.isEmpty) return null;
                final parsed = int.tryParse(rating);
                if (parsed == null || parsed < 0 || parsed > 5) {
                  return 'Rating must be a whole number from 0 to 5';
                }
                return null;
              },
            ),
            const SizedBox(height: 13),
            TextFormField(
              controller: _notes,
              minLines: 3,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
              validator: (value) => (value?.runes.length ?? 0) > 300
                  ? 'Notes must be at most 300 characters'
                  : null,
            ),
            if (widget.showSubmitButton) ...[
              const SizedBox(height: 19),
              FilledButton(
                onPressed: _busy ? null : submit,
                child: _busy
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Add Book'),
              ),
            ],
            if (_message != null) ...[
              const SizedBox(height: 12),
              Text(
                _message!,
                style: TextStyle(
                  color: _message == 'Book added' || _message == 'Book updated'
                      ? _pine
                      : Theme.of(context).colorScheme.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    ),
  );
}

class _DetailScreen extends StatefulWidget {
  const _DetailScreen({required this.store, required this.book});

  final BookStore store;
  final Book book;

  @override
  State<_DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<_DetailScreen> {
  late String _docId = widget.book.id;
  bool _editing = false;
  bool _saving = false;
  Book? _editBook;
  final _editFormKey = GlobalKey<_BookFormState>();

  Future<String> _saveBook(BookDraft draft) async {
    setState(() => _saving = true);
    try {
      final id = await widget.store.update(_editBook!, draft);
      if (mounted) {
        setState(() {
          _docId = id;
          _editing = false;
        });
      }
      return id;
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _toggleFavorite(Book book) async {
    try {
      await widget.store.setFavorite(book, !book.favorite);
    } catch (error) {
      final message = error is FirebaseException
          ? error.message ?? error.code
          : error.toString();
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  Future<void> _delete(Book book) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete book?'),
        content: const Text('This book will be removed from your shelf.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await widget.store.delete(book);
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      final message = error is FirebaseException
          ? error.message ?? error.code
          : error.toString();
      _messengerKey.currentState?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final reference = FirebaseFirestore.instance
        .collection('books')
        .doc(_docId);
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: !_saving,
          title: const Text('Detail'),
          actions: [
            if (_editing) ...[
              TextButton(
                onPressed: _saving
                    ? null
                    : () => setState(() => _editing = false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: _saving
                    ? null
                    : () => _editFormKey.currentState?.submit(),
                child: const Text('Save'),
              ),
              const SizedBox(width: 8),
            ],
          ],
        ),
        body: SafeArea(
          child: _editing
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 560),
                      child: _BookForm(
                        key: _editFormKey,
                        initial: _editBook!,
                        showSubmitButton: false,
                        onSave: _saveBook,
                      ),
                    ),
                  ),
                )
              : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: reference.snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Could not load book: ${snapshot.error}'),
                      );
                    }
                    final data = snapshot.data?.data();
                    if (data == null) {
                      return const Center(child: Text('No books found'));
                    }
                    final book = _bookFromData(snapshot.data!.id, data);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: Card(
                            color: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(22),
                              side: const BorderSide(color: Color(0xFFE8E7E0)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(22),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    book.title,
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium,
                                  ),
                                  const SizedBox(height: 5),
                                  Text(book.author),
                                  const SizedBox(height: 22),
                                  _DetailRow(label: 'Genre', value: book.genre),
                                  _DetailRow(
                                    label: 'Status',
                                    value: book.status,
                                  ),
                                  _DetailRow(
                                    label: 'Rating',
                                    value:
                                        book.rating?.toString() ?? 'Not rated',
                                  ),
                                  _DetailRow(
                                    label: 'Notes',
                                    value: book.notes.isEmpty
                                        ? '—'
                                        : book.notes,
                                  ),
                                  const SizedBox(height: 17),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () =>
                                              _toggleFavorite(book),
                                          icon: Icon(
                                            book.favorite
                                                ? Icons.star_rounded
                                                : Icons.star_border_rounded,
                                          ),
                                          label: Text(
                                            book.favorite
                                                ? 'Favorite'
                                                : 'Add favorite',
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          onPressed: () => _delete(book),
                                          icon: const Icon(
                                            Icons.delete_outline_rounded,
                                          ),
                                          label: const Text('Delete'),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  FilledButton.tonal(
                                    onPressed: () => setState(() {
                                      _editBook = book;
                                      _editing = true;
                                    }),
                                    child: const Text('Edit'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }

  Book _bookFromData(String id, Map<String, dynamic> data) => Book(
    id: id,
    userId: data['userId'] as String,
    title: data['title'] as String,
    author: data['author'] as String,
    genre: data['genre'] as String,
    status: data['status'] as String,
    rating: data['rating'] as int?,
    favorite: data['favorite'] as bool,
    notes: data['notes'] as String? ?? '',
    createdAt: data['createdAt'] as Timestamp,
  );
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 15),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: _muted),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: _ink),
        ),
      ],
    ),
  );
}
