import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';
import 'package:picture_perfect/src/core/utils/auth_result.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  AuthStatus _status = AuthStatus.initial;

  AuthViewModel(this._authRepository) {
    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        _currentUser = UserModel(
          id: user.uid,
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
      } else {
        _currentUser = null;
        _status = AuthStatus.unauthenticated;
      }
      notifyListeners();
    });
  }

  // Getters
  String? get error => _error;
  bool get isLoading => _isLoading;
  UserModel? get currentUser => _currentUser;
  bool get isAuthenticated => _status == AuthStatus.authenticated;
  AuthStatus get status => _status;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    _status = AuthStatus.error;
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      _error = null;
      notifyListeners();
    });
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }

  // Function to handle navigation
  void _navigateAfterAuth(BuildContext context, bool success) {
    if (context.mounted) {
      if (success) {
        context.go('/home');
      }
    }
  }

  // Sign in Method
  Future<void> signIn(
      String email, String password, BuildContext context) async {
    _status = AuthStatus.authenticating;
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final result =
          await _authRepository.signInWithEmailAndPassword(email, password);

      if (result is AuthSuccess) {
        _status = AuthStatus.authenticated;
        if (context.mounted) {
          context.go('/home');
        }
      } else if (result is AuthFailure) {
        _status = AuthStatus.unauthenticated;
        _setError(result.message);
      }
    } catch (e) {
      _status = AuthStatus.error;
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sign up Method
  Future<void> signUp(
      String email, String password, BuildContext context) async {
    _status = AuthStatus.authenticating;
    _setLoading(true);
    _clearError();

    try {
      final result =
          await _authRepository.signUpWithEmailAndPassword(email, password);

      if (result is AuthSuccess) {
        _status = AuthStatus.authenticated;
        if (context.mounted) {
          context.go('/home');
        }
      } else if (result is AuthFailure) {
        _status = AuthStatus.unauthenticated;
        _setError(result.message);
      }
    } catch (e) {
      _status = AuthStatus.error;
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  // Sign Out method
  Future<void> signOut(BuildContext context) async {
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      if (context.mounted) {
        context.go('/login');
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }
}
