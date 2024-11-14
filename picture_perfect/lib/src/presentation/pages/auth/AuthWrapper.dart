import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/spash_page.dart';
import 'package:picture_perfect/src/presentation/pages/home/home_page.dart';
import 'package:picture_perfect/src/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        // Show splash screen while checking initial auth state
        if (authProvider.status == AuthStatus.initial) {
          return const SplashPage();
        }
        
        // Show login page if not authenticated
        if (!authProvider.isAuthenticated) {
          return const LoginPage();
        }
        
        // Show home page if authenticated
        return const HomePage();
      },
    );
  }
}
