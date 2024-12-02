import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/data/models/user_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/profile/edit_profile_widget.dart';
import 'package:picture_perfect/src/presentation/widgets/profile/profile_settings_widget.dart';
import 'package:provider/provider.dart';

class DynamicScaffold extends StatefulWidget {
  final Widget child;
  const DynamicScaffold({super.key, required this.child});

  @override
  State<DynamicScaffold> createState() => _ScaffoldWithBottomNavbarState();
}

class _ScaffoldWithBottomNavbarState extends State<DynamicScaffold> {
  int _calculatedSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    switch (location) {
      case '/home':
        return 0;
      case '/create_poll':
        return 1;
      case '/profile':
        return 2;
      default:
        return 0;
    }
  }

  // Generates a dynamic AppBar based on the current route
  PreferredSizeWidget _buildDynamicAppBar(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final authViewModel = context.watch<AuthViewModel>();

    // If not authenticated and on profile page, redirect to login
    if (!authViewModel.isAuthenticated && location == '/profile') {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/login');
      });
      return AppBar(title: const Text('Redirecting...'));
    }

    // If user is loading, show loading state
    if (authViewModel.isLoading) {
      return AppBar(title: const CircularProgressIndicator());
    }

    final user = authViewModel.currentUser;
    if (user == null && location == '/profile') {
      return AppBar(title: const Text('Please login'));
    }

    switch (location) {
      case '/home':
        return AppBar(title: const Text('Home'));
      case '/profile':
        return AppBar(
          title: Text(user?.name ?? 'Profile'),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditProfile(context, user!),
            ),
            IconButton(
              onPressed: () => _showProfileSettings(context),
              icon: const Icon(Icons.settings),
            ),
          ],
        );
      case '/create_poll':
        return AppBar(
          title: const Text('Create Poll'),
        );
      default:
        return AppBar(title: const Text('Picture Perfect'));
    }
  }

  void _onItemTapped(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go('/home');
        break;
      case 1:
        context.go('/create_poll');
        break;
      case 2:
        context.go('/profile');
    }
  }

  void _showEditProfile(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => EditProfileSheet(user: user),
    );
  }

  void _showProfileSettings(BuildContext context) {
    showModalBottomSheet(
        context: context, builder: (context) => EditSettingsSheet());
  }

  @override
  Widget build(BuildContext context) {
    // Check if screen width is large enough for side nav
    final isDesktop = MediaQuery.of(context).size.width > 768;

    if (isDesktop) {
      return Row(
        children: [
          // Side Navigation
          NavigationRail(
            selectedIndex: _calculatedSelectedIndex(context),
            onDestinationSelected: (index) => _onItemTapped(context, index),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home),
                label: Text('Home'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle),
                label: Text('Create'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: Text('Profile'),
              ),
            ],
          ),
          // Main Content
          Expanded(
            child: Scaffold(
              appBar: _buildDynamicAppBar(context),
              body: Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: 600),
                  child: widget.child,
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile layout
    return Scaffold(
      appBar: _buildDynamicAppBar(context),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _calculatedSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Create'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

/*
*
* Profile Page
* */
