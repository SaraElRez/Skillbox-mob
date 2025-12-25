import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbox/providers/user_provider.dart';
import 'package:skillbox/services/api_service.dart';
import 'package:skillbox/screens/auth/login_screen.dart';
import 'package:skillbox/widgets/scaffold_with_nav.dart';
import '../models/user.dart';

class LauncherScreen extends StatefulWidget {
  const LauncherScreen({super.key});

  @override
  State<LauncherScreen> createState() => _LauncherScreenState();
}

class _LauncherScreenState extends State<LauncherScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _restoreUser();
  }

  Future<void> _restoreUser() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token != null) {
      // call /api/me to validate and fetch user
      final response = await ApiService.getCurrentUser(token);

      if (!response.containsKey('error')) {
        // build user model
        final user = User.fromJson(response);
        Provider.of<UserProvider>(context, listen: false).setUser(user);
      } else {
        // token invalid -> remove it
        await prefs.remove('token');
      }
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final userProvider = Provider.of<UserProvider>(context);
    final isLoggedIn = userProvider.isLoggedIn;

    return isLoggedIn ? const ScaffoldWithNav(initialIndex: 0) : const LoginScreen();
  }
}
