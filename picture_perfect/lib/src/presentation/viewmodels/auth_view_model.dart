import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';
import 'package:picture_perfect/src/core/utils/auth_result.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/core/utils/result.dart';
import 'package:picture_perfect/src/data/repositories/user_repository.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:provider/provider.dart';

import '../../data/models/user_model.dart';
import '../../data/repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;
  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;
  AuthStatus _status = AuthStatus.initial;

  AuthViewModel(this._authRepository) {
    AppLogger.info('Initializing AuthViewModel');

    _authRepository.authStateChanges.listen((user) {
      if (user != null) {
        AppLogger.info('User authenticated: ${user.email}');
        _currentUser = UserModel.fromFirebaseUser(user);

        AppLogger.info('User Info: ${currentUser?.toJson()}');
        _status = AuthStatus.authenticated;
      } else {
        AppLogger.info('User unauthenticated');
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
    AppLogger.error('Error set: $error');
    notifyListeners();

    Timer(const Duration(seconds: 3), () {
      AppLogger.debug('Clearing error after 3 seconds');
      _error = null;
      notifyListeners();
    });
  }

  void _clearError() {
    AppLogger.debug('Clearing error');
    _error = null;
    notifyListeners();
  }

  void _navigateAfterAuth(BuildContext context, bool success) {
    AppLogger.info('_navigateAfterAuth called with success: $success');
    if (context.mounted) {
      if (success) {
        AppLogger.info('Navigating to /home');
        context.go('/home');
      }
    }
  }

  // Sign in Method
  Future<void> signIn(
      String email, String password, BuildContext context) async {
    AppLogger.info('Attempting to sign in with email: $email');
    _status = AuthStatus.authenticating;
    _setLoading(true);
    _clearError();
    notifyListeners();

    try {
      final result =
          await _authRepository.signInWithEmailAndPassword(email, password);

      if (result is AuthSuccess && context.mounted) {
        AppLogger.info('Sign in successful for email: $email');
        _status = AuthStatus.authenticated;

        final userViewModel = context.read<UserViewModel>();
        // Load user Profile on sign in
        await userViewModel.loadUserProfile(_currentUser!.id);

        if (context.mounted) {
          _navigateAfterAuth(context, true);
        }
      } else if (result is AuthFailure) {
        AppLogger.warning(
            'Sign in failed for email: $email with message: ${result.message}');
        _status = AuthStatus.unauthenticated;
        _setError(result.message);
      }
    } catch (e) {
      AppLogger.error('Exception during sign in: $e');
      _status = AuthStatus.error;
      _setError(e.toString());
    } finally {
      AppLogger.debug('Sign in process completed');
      _setLoading(false);
    }
  }

  // Sign up Method
  // In AuthViewModel
  Future<void> signUp(
      String email, String password, BuildContext context) async {
    AppLogger.info('Attempting to sign up with email: $email');
    _status = AuthStatus.authenticating;
    _setLoading(true);
    _clearError();

    try {
      final result =
          await _authRepository.signUpWithEmailAndPassword(email, password);

      if (result is AuthSuccess && context.mounted) {
        // Get the Firebase user
        final firebaseUser = result.user;

        // Create user in Firestore using UserRepository
        final userRepository = context.read<UserRepository>();
        final userResult = await userRepository.createUser(firebaseUser!);

        if (userResult is Success<UserModel>) {
          AppLogger.info('Sign up successful for email: $email');
          _currentUser = userResult.data;
          _status = AuthStatus.authenticated;

          if (context.mounted) {
            await context
                .read<UserViewModel>()
                .loadUserProfile(_currentUser!.id);
            if (context.mounted) {
              _navigateAfterAuth(context, true);
            }
          }
        } else if (userResult is Failure<UserModel>) {
          // Handle Firestore user creation failure
          AppLogger.warning(
              'Failed to create user in Firestore: ${userResult.message}');
          _status = AuthStatus.error;
          _setError('Failed to complete user registration');
        }
      } else if (result is AuthFailure) {
        AppLogger.warning(
            'Sign up failed for email: $email with message: ${result.message}');
        _status = AuthStatus.unauthenticated;
        _setError(result.message);
      }
    } catch (e) {
      AppLogger.error('Exception during sign up: $e');
      _status = AuthStatus.error;
      _setError(e.toString());
    } finally {
      AppLogger.debug('Sign up process completed');
      _setLoading(false);
    }
  }

  // Sign Out method
  Future<void> signOut(BuildContext context) async {
    AppLogger.info('Attempting to sign out');
    _setLoading(true);
    _clearError();

    try {
      await _authRepository.signOut();
      AppLogger.info('Sign out successful');
      _currentUser = null;
      _status = AuthStatus.unauthenticated;
      if (context.mounted) {
        AppLogger.info('Navigating to /login');
        context.go('/login');
      }
    } catch (e) {
      AppLogger.error('Exception during sign out: $e');
      _setError(e.toString());
    } finally {
      AppLogger.debug('Sign out process completed');
      _setLoading(false);
    }
  }
}
