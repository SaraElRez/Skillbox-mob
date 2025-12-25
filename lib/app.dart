import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:skillbox/widgets/launcher.dart';
import 'theme/app_theme.dart';
import 'providers/user_provider.dart';
import 'providers/notification_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProxyProvider<UserProvider, NotificationProvider>(
          create: (_) => NotificationProvider(),
          update: (_, userProvider, notificationProvider) {
            notificationProvider?.updateUserProvider(userProvider);
            return notificationProvider!;
          },
        ),
      ],
      child: MaterialApp(
        title: 'SkillBox',
        theme: AppTheme.lightTheme,    // Light Theme
        darkTheme: AppTheme.darkTheme, // Dark Theme
        themeMode: ThemeMode.system,   // Auto (system based)
        debugShowCheckedModeBanner: false,
        home: const LauncherScreen(),
      ),
    );
  }
}