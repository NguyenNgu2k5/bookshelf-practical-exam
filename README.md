# BookShelf

Flutter Android app using Firebase Authentication and Cloud Firestore.

- Firebase project: `bookshelf-practical-exam-1027`
- Android application ID: `com.example.bookshelf`
- Firestore database: `(default)` in `asia-southeast1` (Singapore)

`lib/firebase_options.dart` and `android/app/google-services.json` are generated client-side Firebase configuration. Regenerate them with `dart pub global run flutterfire_cli:flutterfire configure --project bookshelf-practical-exam-1027 --platforms android` after Firebase is enabled for the project.

`firebase.json` configures Email/Password and points Firestore to `firestore.rules`. Deploy both with `npx firebase-tools deploy --only auth,firestore:rules --project bookshelf-practical-exam-1027`.

