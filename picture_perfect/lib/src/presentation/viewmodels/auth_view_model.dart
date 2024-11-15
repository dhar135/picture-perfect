// lib/presentation/viewmodels/auth_view_model.dart
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/foundation.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';
import 'package:picture_perfect/src/core/utils/auth_result.dart';
import 'package:picture_perfect/src/core/utils/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/user_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  final UserRepository _userRepository;

  AuthStatus _status = AuthStatus.initial;
  auth.User? _firebaseUser;
  UserModel? _user;
  String? _errorMessage;

  AuthViewModel({
    required AuthRepository authRepository,
    required UserRepository userRepository,
  })  : _authRepository = authRepository,
        _userRepository = userRepository {
    _init();
  }

  // Getters
  AuthStatus get status => _status;
  auth.User? get firebaseUser => _firebaseUser;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // Initialize auth state listener
  void _init() {
    _authRepository.authStateChanges.listen((auth.User? firebaseUser) async {
      _firebaseUser = firebaseUser;

      if (firebaseUser == null) {
        _status = AuthStatus.unauthenticated;
        _user = null;
        notifyListeners();
        return;
      }

      _status = AuthStatus.authenticating;
      notifyListeners();

      // Fetch user data from Firestore
      final result = await _userRepository.getUserById(firebaseUser.uid);

      if (result case Success(data: final userData)) {
        _user = userData;
        _status = AuthStatus.authenticated;
      } else {
        // If user document doesn't exist, create it
        final createResult = await _userRepository.createUser(firebaseUser);

        if (createResult case Success(data: final newUser)) {
          _user = newUser;
          _status = AuthStatus.authenticated;
        } else {
          _errorMessage = switch (createResult) {
            Failure(message: final message) => message,
            _ => 'Failed to create user'
          };
          _status = AuthStatus.error;
        }
      }

      notifyListeners();
    });
  }

  // Sign in with email and password
  Future<bool> signIn(String email, String password) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.signInWithEmailAndPassword(
        email.trim(),
        password.trim(),
      );

      switch (result) {
        case AuthSuccess():
          // The auth state listener (_init) will handle setting the user and status
          return true;

        case AuthFailure(message: final message):
          _status = AuthStatus
              .unauthenticated; // Change to unauthenticated on failure
          _errorMessage = message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _status =
          AuthStatus.unauthenticated; // Change to unauthenticated on error
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign up with email and password
// In AuthViewModel class
  Future<bool> signUp(String email, String password, {String? name}) async {
    try {
      _status = AuthStatus.authenticating;
      _errorMessage = null;
      notifyListeners();

      final result = await _authRepository.signUpWithEmailAndPassword(
        email.trim(),
        password.trim(),
      );

      switch (result) {
        case AuthSuccess(user: final firebaseUser):
          if (firebaseUser == null) {
            _status = AuthStatus.unauthenticated;
            _errorMessage = 'Failed to create user account';
            notifyListeners();
            return false;
          }
          final userResult = await _userRepository.createUser(firebaseUser);

          switch (userResult) {
            case Success(data: final userData):
              _user = userData;
              _firebaseUser = firebaseUser;
              _status = AuthStatus.authenticated;
              notifyListeners();
              return true;

            case Failure(message: final message):
              _status = AuthStatus.unauthenticated;
              _errorMessage = message;
              notifyListeners();
              await firebaseUser.delete();
              return false;
          }

        case AuthFailure(message: final message):
          _status = AuthStatus.unauthenticated;
          _errorMessage = message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _status = AuthStatus.unauthenticated;
      _errorMessage = 'An unexpected error occurred';
      notifyListeners();
      return false;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      final result = await _authRepository.signOut();
      _status = AuthStatus.unauthenticated;
      _user = null;
      _firebaseUser = null;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error signing out';
      notifyListeners();
    }
  }

  // Update user profile
  Future<bool> updateProfile({
    String? name,
    String? bio,
    String? website,
  }) async {
    if (_firebaseUser == null) return false;

    try {
      // Update Auth profile if name is provided
      if (name != null) {
        final authResult = await _authRepository.updateProfile(
          displayName: name,
        );

        if (authResult case AuthFailure()) {
          return false;
        }
      }

      // Update Firestore profile
      final result = await _userRepository.updateProfile(
        userId: _firebaseUser!.uid,
        name: name,
        bio: bio,
        website: website,
      );

      switch (result) {
        case Success(data: final updatedUser):
          _user = updatedUser;
          notifyListeners();
          return true;
        case Failure(message: final message):
          _errorMessage = message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to update profile';
      notifyListeners();
      return false;
    }
  }

  // Password reset
  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      final result = await _authRepository.sendPasswordResetEmail(email.trim());

      switch (result) {
        case AuthSuccess():
          return true;
        case AuthFailure(message: final message):
          _errorMessage = message;
          notifyListeners();
          return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to send password reset email';
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
