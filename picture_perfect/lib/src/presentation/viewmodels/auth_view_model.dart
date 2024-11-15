import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/core/utils/auth_result.dart';
import 'package:picture_perfect/src/data/repositories/auth_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _repository;
  AuthStatus _status = AuthStatus.initial;
  User? _user;
  String? _errorMessage;

  AuthViewModel(this._repository) {
    _init();
  }

  void _init() {
    _repository.authStateChanges.listen((User? user) {
      _user = user;
      _status = user != null 
          ? AuthStatus.authenticated 
          : AuthStatus.unauthenticated;
      notifyListeners();
    });
  }

  AuthStatus get status => _status;
  User? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  Future<bool> signIn(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signInWithEmailAndPassword(email, password);

    switch (result) {
      case AuthSuccess():
        return true;
      case AuthFailure(message: final message):
        _status = AuthStatus.error;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    final result = await _repository.signUpWithEmailAndPassword(email, password);

    switch (result) {
      case AuthSuccess():
        return true;
      case AuthFailure(message: final message):
        _status = AuthStatus.error;
        _errorMessage = message;
        notifyListeners();
        return false;
    }
  }

  Future<void> signOut() async {
    await _repository.signOut();
    _status = AuthStatus.unauthenticated;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}