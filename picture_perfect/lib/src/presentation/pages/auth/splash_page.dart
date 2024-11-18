import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    checkAuthState();
  }

  Future<void> checkAuthState() async {
    final authViewModel = context.read<AuthViewModel>();
    // Simulate a delay for splash screen if needed
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    if (authViewModel.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
