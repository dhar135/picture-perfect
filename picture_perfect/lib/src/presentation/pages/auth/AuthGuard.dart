import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(builder: (context, authProvider, _) {
      if (!authProvider.isAuthenticated) {
        // Redirect to login if not authenticated
        return const LoginPage();
      }
      return child;
    });
  }
}
