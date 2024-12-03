library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/firebase_options.dart';
import 'package:picture_perfect/src/core/router/app_router.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/data/repositories/auth_repository.dart';
import 'package:picture_perfect/src/data/repositories/poll_repository.dart';
import 'package:picture_perfect/src/data/repositories/user_repository.dart';
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

  final authViewModel = AuthViewModel(authRepository);
  final userViewModel = UserViewModel(userRepository);

  await authViewModel.initializeAuthState();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: authViewModel),
        ChangeNotifierProvider.value(value: userViewModel),
        ChangeNotifierProvider(create: (_) => PollViewModel(pollRepository)),
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
  Widget build(BuildContext context) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Picture Perfect',
      theme: AppTheme.lightTheme,
      routerConfig: AppRouter.router,
    );
  }
}
