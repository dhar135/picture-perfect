import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class AuthGuard extends StatelessWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthViewModel>(builder: (context, viewModel, _) {
      if (!viewModel.isAuthenticated) {
        // Redirect to login if not authenticated
        return const LoginPage();
      }
      return child;
    });
  }
}
