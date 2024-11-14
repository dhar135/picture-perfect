// Authentication state management

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

enum AuthStatus {
  initial,
  authenticated,
  unauthenticated,
  authenticating,
  error
}

class AuthProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  // Getters
  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Constructor - Listen to auth state changes
  AuthProvider() {
    _auth.authStateChanges().listen((User? user) {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
      } else {
        _user = user;
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case 'user-not-found':
          _errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          _errorMessage = 'Wrong password provided.';
          break;
        case 'user-disabled':
          _errorMessage = 'This account has been disabled.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        default:
          _errorMessage = 'No Account Found';
      }
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );

      return true;
    } on FirebaseAuthException catch (e) {
      _status = AuthStatus.error;
      switch (e.code) {
        case 'weak-password':
          _errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          _errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          _errorMessage = 'Invalid email address.';
          break;
        default:
          _errorMessage = 'An error occurred. Please try again.';
      }
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out. Please try again.';
      notifyListeners();
    }
  }

  // Password reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return true;
    } on FirebaseAuthException catch (e) {
      _errorMessage = e.code == 'user-not-found'
          ? 'No user found with this email.'
          : 'Error sending password reset email. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Update user profile
  Future<bool> updateProfile({String? displayName, String? photoURL}) async {
    try {
      if (_user == null) return false;

      await _user!.updateDisplayName(displayName);
      await _user!.updatePhotoURL(photoURL);
      
      // Refresh user data
      _user = _auth.currentUser;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Error updating profile. Please try again.';
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}