import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/data/models/user_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
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
      case '/profile':
        return 1;
      default:
        return 0;
    }
  }

  // Generates a dynamic AppBar based on the current route
  PreferredSizeWidget _buildDynamicAppBar(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    final userViewModel = context.watch<UserViewModel>();
    // If user is null or loading, show loading or error state
    if (userViewModel.isLoading) {
      return AppBar(title: CircularProgressIndicator());
    }

    if (userViewModel.error != null) {
      return AppBar(title: Text('Error: ${userViewModel.error}'));
    }

    // Use the user from the ViewModel instead of a stream
    final user = userViewModel.user;

    if (user == null) {
      return AppBar(title: Text('No user data available'));
    }

    switch (location) {
      case '/home':
        return AppBar(
          title: const Text('Home'),
        );
      case '/profile':
        return PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: AppBar(
              title: Text(user.name ?? 'Profile'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _showEditProfile(context, user),
                ),
                IconButton(
                    onPressed: () => _showProfileSettings(context),
                    icon: const Icon(Icons.settings)),
              ],
            ));
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
        context.go('/profile');
        break;
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
    return Scaffold(
      appBar: _buildDynamicAppBar(context),
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outlined),
              activeIcon: Icon(Icons.person),
              label: 'Profile')
        ],
        currentIndex: _calculatedSelectedIndex(context),
        onTap: (index) => _onItemTapped(context, index),
      ),
    );
  }
}

/*
*
* Profile Page
* */
