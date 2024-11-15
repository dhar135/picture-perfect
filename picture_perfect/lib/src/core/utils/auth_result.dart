import 'package:firebase_auth/firebase_auth.dart';

sealed class AuthResult {
  const AuthResult();
}

final class AuthSuccess extends AuthResult {
  final User? user;
  const AuthSuccess(this.user);
}

final class AuthFailure extends AuthResult {
  final String message;
  const AuthFailure(this.message);
}
