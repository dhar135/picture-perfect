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
import 'package:picture_perfect/src/core/router/app_router.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/data/repositories/auth_repository.dart';
import 'package:picture_perfect/src/data/repositories/poll_repository.dart';
import 'package:picture_perfect/src/data/repositories/user_repository.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_guard.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_wrapper.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:provider/provider.dart';

import 'src/core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.init();
  AppLogger.info('Starting Picture Perfect app...');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppLogger.info('Firebase initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.error('Failed to initialize Firebase', e, stackTrace);
  }

  final authRepository = AuthRepository();
  final userRepository = UserRepository();
  final pollRepository = PollRepository();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthViewModel(
            authRepository,
          ),
        ),
        ChangeNotifierProvider(create: (_) => PollViewModel(pollRepository)),
        ChangeNotifierProvider(create: (_) => UserViewModel(userRepository)),
        Provider<UserRepository>(create: (_) => UserRepository())
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      // Sign out when app is closed
      context.read<AuthViewModel>().signOut(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Picture Perfect',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
