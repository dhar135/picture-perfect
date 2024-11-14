import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home'),
        actions: [_buildLogoutButton()],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add your login form widgets here
                const Text(
                  'Home Page',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signOut();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error signing out: ${e.toString()}')),
      );
    }
  }

  Widget _buildLogoutButton() {
    return ElevatedButton(
      onPressed: _signOut,
      child: const Text('Logout'),
    );
  }
}
