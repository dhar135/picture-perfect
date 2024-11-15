import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_guard.dart';
import 'package:picture_perfect/src/presentation/pages/auth/auth_wrapper.dart';
import 'package:picture_perfect/src/presentation/pages/auth/login_page.dart';
import 'package:picture_perfect/src/presentation/pages/auth/signup_page.dart';
import 'package:picture_perfect/src/presentation/pages/create/create_poll_page.dart';
import 'package:picture_perfect/src/presentation/pages/explore/explore_page.dart';
import 'package:picture_perfect/src/presentation/pages/home/home_page.dart';
import 'package:picture_perfect/src/presentation/pages/profile/profile_page.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:provider/provider.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const AuthWrapper(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/signup',
        builder: (context, state) => const SignupPage(),
      ),
      // Protected routes
      ShellRoute(
        builder: (context, state, child) => AuthGuard(child: child),
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: '/create',
            builder: (context, state) => const CreatePollPage(),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExplorePage(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
    redirect: (BuildContext context, GoRouterState state) {
      final authViewModel = context.read<AuthViewModel>();
      final isAuthenticated = authViewModel.isAuthenticated;
      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/signup';
      final isInitialRoute = state.matchedLocation == '/';

      // If not authenticated and trying to access protected route
      if (!isAuthenticated && !isAuthRoute && !isInitialRoute) {
        return '/login';
      }

      // If authenticated and trying to access auth routes
      if (isAuthenticated && (isAuthRoute || isInitialRoute)) {
        return '/home';
      }

      // If not authenticated and trying to access auth routes, allow it
      if (!isAuthenticated && isAuthRoute) {
        return null;
      }

      return null;
    },
  );
}
