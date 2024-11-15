/// Picture Perfect Application
///
/// The main entry point for the Picture Perfect application. This app is a Flutter
/// application that uses Firebase for backend services and follows a MVVM architecture pattern.
///
/// The application initializes Firebase, sets up dependency injection using Provider pattern,
/// and configures the main routing system.
///
/// Features:
/// * Firebase integration
/// * Authentication system
/// * Protected routes using AuthGuard
/// * Dark theme implementation
/// * MVVM architecture
///
/// Routes:
/// * /login - Login page
/// * /signup - Sign up page
/// * /home - Protected home page
/// * /create - Protected poll creation page
/// * /explore - Protected explore page
/// * /profile - Protected profile page
///
/// Dependencies:
/// * firebase_core
/// * provider
/// * flutter
///
/// The app uses [AuthWrapper] as the initial route to handle authentication state
/// and [AuthGuard] to protect routes that require authentication.
library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/firebase_options.dart';
import 'package:picture_perfect/src/data/repositories/auth_repository.dart';
import 'package:picture_perfect/src/data/repositories/user_repository.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_guard.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_wrapper.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/signup_page.dart';
import 'package:picture_perfect/src/presentation/pages/create/create_poll_page.dart';
import 'package:picture_perfect/src/presentation/pages/explore/explore_page.dart';
import 'package:picture_perfect/src/presentation/pages/profile/profile_page.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/app_theme.dart';
import 'src/presentation/pages/home/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepository = AuthRepository();
  final userRepository = UserRepository();

  await authRepository.signOut();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepository: authRepository,
            userRepository: userRepository,
          ),
        ),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Picture Perfect',
      theme: AppTheme.darkTheme,
      home: const AuthWrapper(),
      routes: {
        '/login': (context) => const LoginPage(),
        '/signup': (context) => const SignupPage(),
        // Protected routes
        '/home': (context) => const AuthGuard(child: HomePage()),
        '/create': (context) => const AuthGuard(child: CreatePollPage()),
        '/explore': (context) => const AuthGuard(child: ExplorePage()),
        '/profile': (context) => const AuthGuard(child: ProfilePage()),
      },
    );
  }
}

// AuthGuard Widget to protect routes
