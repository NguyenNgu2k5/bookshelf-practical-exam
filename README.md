# BookShelf

Flutter Android app using Firebase Authentication and Cloud Firestore.

- Firebase project: `bookshelf-practical-exam-1027`
- Android application ID: `com.example.bookshelf`
- Firestore database: `(default)` in `asia-southeast1` (Singapore)

`lib/firebase_options.dart` and `android/app/google-services.json` are generated client-side Firebase configuration. Regenerate them with `dart pub global run flutterfire_cli:flutterfire configure --project bookshelf-practical-exam-1027 --platforms android` after Firebase is enabled for the project.

`firebase.json` configures Email/Password and points Firestore to `firestore.rules`. Deploy both with `npx firebase-tools deploy --only auth,firestore:rules --project bookshelf-practical-exam-1027`.

## Build and checks

Run `flutter pub get`, then `flutter build apk --release`. The coursework APK uses a debug signing key.

With an Android emulator connected as `emulator-5554`, run:

```text
firebase emulators:exec --config firebase.emulator.json --only auth,firestore --project bookshelf-practical-exam-1027 "flutter test integration_test/bookshelf_test.dart -d emulator-5554 --reporter expanded"
```

These checks use local Firebase emulators. They cover Rules validation and account isolation, duplicate books, stale edits after deletion, favorite preservation, search and the Detail edit flow.

`test_support/check_live_rules.py` also checks the published Rules with client credentials. Set `BOOKSHELF_TEST_PASSWORD` to the grader test account password before running it. It creates only temporary audit documents and one temporary account and removes them in `finally`.
