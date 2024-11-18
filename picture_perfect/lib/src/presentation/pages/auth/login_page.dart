import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/theme/app_theme.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/auth_view_model.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // Stateful Properties
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Consumer<AuthViewModel>(
      builder: (BuildContext context, AuthViewModel viewModel, Widget? child) {
        return Scaffold(
          body: SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //TODO: Add app logo

                      // App Name
                      Text(
                        'Picture Perfect',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.secondary,
                        ),
                      ).gradient(),
                      const SizedBox(height: 48),

                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          labelStyle:
                              TextStyle(color: theme.colorScheme.secondary),
                          prefixIcon: Icon(
                            Icons.email,
                            color: theme.colorScheme.secondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.secondary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.secondary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        style: theme.textTheme.bodyMedium,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle:
                              TextStyle(color: theme.colorScheme.secondary),
                          prefixIcon: Icon(
                            Icons.lock,
                            color: theme.colorScheme.secondary,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.secondary),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                BorderSide(color: theme.colorScheme.secondary),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: theme.colorScheme.secondary,
                              width: 2,
                            ),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: theme.colorScheme.secondary,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Login Button
                      Consumer<AuthViewModel>(
                        builder: (context, viewModel, child) {
                          return ElevatedButton(
                            onPressed: viewModel.isLoading
                                ? null
                                : () => _handleLogin(context, viewModel),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.all(16),
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.scaffoldBackgroundColor,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            child: viewModel.isLoading
                                ? const CircularProgressIndicator(
                                    strokeWidth: 2)
                                : const Text('Login'),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sign Up Link
                      TextButton(
                        onPressed: () {
                          context.go('/signup');
                        },
                        child: Text(
                          "Don't have an account? Sign up",
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                      ),
                      if (viewModel.error != null)
                        Text(
                          viewModel.error!,
                          style: theme.textTheme.bodyMedium,
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleLogin(BuildContext context, AuthViewModel viewModel) {
    if (_formKey.currentState!.validate()) {
      viewModel.signIn(
          _emailController.text, _passwordController.text, context);
    }
  }
}
