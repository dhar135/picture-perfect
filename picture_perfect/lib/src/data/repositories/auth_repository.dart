import 'package:firebase_auth/firebase_auth.dart';
import 'package:picture_perfect/src/core/utils/auth_result.dart';

class AuthRepository {
  final FirebaseAuth _auth;

  AuthRepository({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signInWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthSuccess(result.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_getErrorMessage(e.code));
    }
  }

  Future<AuthResult> signUpWithEmailAndPassword(
    String email,
    String password,
  ) async {
    try {
      final result = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthSuccess(result.user!);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_getErrorMessage(e.code));
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<AuthResult> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      return const AuthSuccess(null);
    } on FirebaseAuthException catch (e) {
      return AuthFailure(_getErrorMessage(e.code));
    }
  }

  Future<AuthResult> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return const AuthFailure('No user signed in');

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoURL);
      return AuthSuccess(user);
    } catch (e) {
      return const AuthFailure('Failed to update profile');
    }
  }

  String _getErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No user found with this email.';
      case 'wrong-password':
        return 'Wrong password provided.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'weak-password':
        return 'The password provided is too weak.';
      case 'email-already-in-use':
        return 'An account already exists for this email.';
      default:
        return 'An error occurred. Please try again.';
    }
  }
}