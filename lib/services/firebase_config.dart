import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    // Replace with your Firebase configuration
    // Get this from Firebase Console -> Project Settings -> General -> Your apps
    return const FirebaseOptions(
      // apiKey: "AIzaSyC0kCDZ5epdncfWw_EYyXSf91Sbb6QFza4",
      // authDomain: "your-project-id.firebaseapp.com",
      // projectId: "your-project-id",
      // storageBucket: "your-project-id.appspot.com",
      // messagingSenderId: "your-sender-id",
      // appId: "your-app-id",
      apiKey: "AIzaSyC0kCDZ5epdncfWw_EYyXSf91Sbb6QFza4",
      authDomain: "finorix-b7326.firebaseapp.com",
      projectId: "finorix-b7326",
      storageBucket: "finorix-b7326.appspot.com",
      messagingSenderId: "904961918715",
      appId: "1:904961918715:android:43f37fe3f1afe2961ad25e",
    );
  }
}
