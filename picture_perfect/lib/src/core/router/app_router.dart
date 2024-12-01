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
            pageBuilder: (context, state) => CustomTransitionPage(
              name: state.matchedLocation,
              key: state.pageKey,
              child: HomePage(),
              transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) {
                return fadeTransition(
                    context, animation, secondaryAnimation, child);
              },
            ),
          ),
          GoRoute(
            path: '/create_poll',
            pageBuilder: (context, state) => CustomTransitionPage(
              name: state.matchedLocation,
              key: state.pageKey,
              child: CreatePollPage(),
              transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) {
                return fadeTransition(
                    context, animation, secondaryAnimation, child);
              },
            ),
          ),
          GoRoute(
            path: '/explore',
            builder: (context, state) => const ExplorePage(),
          ),
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => CustomTransitionPage(
              name: state.matchedLocation,
              key: state.pageKey,
              child: ProfilePage(),
              transitionsBuilder: (BuildContext context,
                  Animation<double> animation,
                  Animation<double> secondaryAnimation,
                  Widget child) {
                return fadeTransition(
                    context, animation, secondaryAnimation, child);
              },
            ),
          ),
          GoRoute(
              path: '/profile/:userId',
              pageBuilder: (context, state) {
                final userId = state.pathParameters['userId'];
                return CustomTransitionPage(
                  name: state.matchedLocation,
                  key: state.pageKey,
                  child: ProfilePage(userId: userId),
                  transitionsBuilder: (BuildContext context,
                      Animation<double> animation,
                      Animation<double> secondaryAnimation,
                      Widget child) {
                    return fadeTransition(
                        context, animation, secondaryAnimation, child);
                  },
                );
              }),
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

  // Custom transition styles for GoRouter
  static Widget defaultTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1.0, 0.0), // Slide from right
        end: Offset.zero,
      ).animate(animation),
      child: child,
    );
  }

// Fade transition
  static Widget fadeTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return FadeTransition(
      opacity: animation,
      child: child,
    );
  }

// Scale transition
  static Widget scaleTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return ScaleTransition(
      scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
      child: child,
    );
  }

// Rotation transition
  static Widget rotationTransition(
      BuildContext context,
      Animation<double> animation,
      Animation<double> secondaryAnimation,
      Widget child) {
    return RotationTransition(
      turns: Tween<double>(begin: 0.0, end: 1.0).animate(animation),
      child: child,
    );
  }
}
