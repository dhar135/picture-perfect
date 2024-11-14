import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/firebase_options.dart';
import 'package:picture_perfect/src/presentation/pages/auth/AuthGuard.dart';
import 'package:picture_perfect/src/presentation/pages/auth/AuthWrapper.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/signup_page.dart';
import 'package:picture_perfect/src/presentation/pages/create/create_poll_page.dart';
import 'package:picture_perfect/src/presentation/pages/explore/explore_page.dart';
import 'package:picture_perfect/src/presentation/pages/profile/profile_page.dart';
import 'package:provider/provider.dart';
import 'src/core/theme/app_theme.dart';
import 'src/presentation/pages/home/home_page.dart';
import 'src/presentation/providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
        create: (_) => AuthProvider(),
        child: MaterialApp(
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
        ));
  }
}

// AuthGuard Widget to protect routes
