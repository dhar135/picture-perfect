import 'package:flutter/material.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/spash_page.dart';
import 'package:picture_perfect/src/presentation/pages/home/home_page.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(
      builder: (context, viewModel, _) {
        switch (viewModel.status) {
          case AuthStatus.initial:
            return const SplashPage();
          case AuthStatus.authenticated:
            return const HomePage();
          case AuthStatus.authenticating:
          case AuthStatus.unauthenticated:
          case AuthStatus.error:
            return const LoginPage();
        }
      },
    );
  }
}
