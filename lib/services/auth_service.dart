// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';

// class AuthService extends ChangeNotifier {
//   final FirebaseAuth _auth = FirebaseAuth.instance;
//   User? _user;
//   bool _isLoading = false;

//   User? get currentUser => _user;
//   bool get isLoading => _isLoading;
//   bool get isAuthenticated => _user != null;

//   AuthService() {
//     _auth.authStateChanges().listen((User? user) {
//       _user = user;
//       notifyListeners();
//     });
//   }

//   Future<bool> signInAnonymously() async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final result = await _auth.signInAnonymously();
//       _user = result.user;
//       return true;
//     } catch (e) {
//       print('Error signing in anonymously: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> signInWithEmailPassword(String email, String password) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final result = await _auth.signInWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       _user = result.user;
//       return true;
//     } catch (e) {
//       print('Error signing in: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<bool> createUserWithEmailPassword(
//       String email, String password) async {
//     try {
//       _isLoading = true;
//       notifyListeners();

//       final result = await _auth.createUserWithEmailAndPassword(
//         email: email,
//         password: password,
//       );
//       _user = result.user;
//       return true;
//     } catch (e) {
//       print('Error creating user: $e');
//       return false;
//     } finally {
//       _isLoading = false;
//       notifyListeners();
//     }
//   }

//   Future<void> signOut() async {
//     await _auth.signOut();
//     _user = null;
//     notifyListeners();
//   }
// }

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? _user;
  bool _isLoading = false;
  bool _isInitializing = true;

  User? get currentUser => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitializing => _isInitializing;

  AuthService() {
    _initializeAuth();
  }

  void _initializeAuth() {
    // Listen to auth state changes
    _auth.authStateChanges().listen((User? user) {
      print('Auth state changed: ${user?.uid ?? 'null'}');
      _user = user;
      _isInitializing = false;
      notifyListeners();
    });

    // Set initial user state
    _user = _auth.currentUser;
    if (_user != null) {
      print('Initial user found: ${_user!.uid}');
      _isInitializing = false;
      notifyListeners();
    }
  }

  Future<bool> signInAnonymously() async {
    try {
      _setLoading(true);
      print('Attempting anonymous sign-in...');

      final result = await _auth.signInAnonymously();
      _user = result.user;

      print('Anonymous sign-in successful: ${_user?.uid}');
      return true;
    } catch (e) {
      print('Error signing in anonymously: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> signInWithEmailPassword(String email, String password) async {
    try {
      _setLoading(true);
      print('Attempting email sign-in for: $email');

      final result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;

      print('Email sign-in successful: ${_user?.uid}');
      return true;
    } catch (e) {
      print('Error signing in with email: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createUserWithEmailPassword(
      String email, String password) async {
    try {
      _setLoading(true);
      print('Attempting to create user for: $email');

      final result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      _user = result.user;

      print('User creation successful: ${_user?.uid}');
      return true;
    } catch (e) {
      print('Error creating user: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      print('Signing out user: ${_user?.uid}');
      await _auth.signOut();
      _user = null;
      notifyListeners();
      print('Sign out successful');
    } catch (e) {
      print('Error signing out: $e');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }
}
