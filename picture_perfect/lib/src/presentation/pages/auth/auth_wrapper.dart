import 'package:flutter/material.dart';
import 'package:picture_perfect/src/core/enum/auth_status.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/splash_page.dart';
import 'package:picture_perfect/src/presentation/pages/home/home_page.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/user_view_model.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();

    // Call this after the first frame is rendered to ensure providers are ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeUserState();
    });
  }

  void _initializeUserState() {
    final authViewModel = context.read<AuthViewModel>();
    final userViewModel = context.read<UserViewModel>();

    final userId = authViewModel.currentUser?.id;
    if (userId != null) {
      userViewModel.loadUserProfile(userId);
    }
  }

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
