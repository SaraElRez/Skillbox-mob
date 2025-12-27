import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:badges/badges.dart' as badges;

import 'package:skillbox/screens/notification/notification_screen.dart';
import 'package:skillbox/screens/auth/login_screen.dart';
import 'package:skillbox/screens/chat/conversations_screen.dart';

// 👉 Add your screens
import 'package:skillbox/screens/home/home_screen.dart';
import 'package:skillbox/screens/services/services_screen.dart';
import 'package:skillbox/screens/profile/profile_screen.dart';
import 'package:skillbox/screens/portfolio/portfolio_submit_screen.dart';

import '../providers/notification_provider.dart';
import '../providers/user_provider.dart';

class ScaffoldWithNav extends StatefulWidget {
  final int initialIndex;

  // NEW: body parameter
  final Widget? body;

  const ScaffoldWithNav({
    super.key,
    this.initialIndex = 0,
    this.body,
  });

  @override
  State<ScaffoldWithNav> createState() => _ScaffoldWithNavState();
}

class _ScaffoldWithNavState extends State<ScaffoldWithNav> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserProvider>(context).user;
    final role = user?.role.toLowerCase() ?? '';
    final isWorker = role == 'worker';
    final isClient = role == 'client';

    final screens = <Widget>[
      const HomeScreen(), // always first
      if (!isWorker) const ServicesScreen(),
      const ConversationsScreen(),
      if (isClient) const PortfolioSubmitScreen(),
      const ProfileScreen(),
    ];

    // If role changed and current index is now out of range, clamp it safely.
    final maxIndex = screens.length - 1;
    final safeIndex = _selectedIndex.clamp(0, maxIndex);
    if (safeIndex != _selectedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedIndex = safeIndex;
          });
        }
      });
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("SkillBox"),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;

              return Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: badges.Badge(
                  showBadge: unreadCount > 0,
                  badgeContent: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(6),
                  ),
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  child: IconButton(
                    icon: const Icon(Icons.notifications),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationsScreen(),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // 👉 Drawer
      drawer: Drawer(
        child: Column(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),

            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  ListTile(
                    leading: const Icon(Icons.home),
                    title: const Text('Home'),
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  if (!isWorker)
                    ListTile(
                      leading: const Icon(Icons.design_services),
                      title: const Text('Services'),
                      onTap: () {
                        _onItemTapped(1);
                        Navigator.pop(context);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.chat),
                    title: const Text('Conversations'),
                    onTap: () {
                      _onItemTapped(isWorker ? 1 : (isClient ? 2 : 2));
                      Navigator.pop(context);
                    },
                  ),
                  if (isClient)
                    ListTile(
                      leading: const Icon(Icons.upload_file),
                      title: const Text('Apply to be Worker'),
                      onTap: () {
                        _onItemTapped(3);
                        Navigator.pop(context);
                      },
                    ),
                  ListTile(
                    leading: const Icon(Icons.person),
                    title: const Text('Profile'),
                    onTap: () {
                      if (isWorker) {
                        _onItemTapped(2);
                      } else if (isClient) {
                        _onItemTapped(4);
                      } else {
                        _onItemTapped(3);
                      }
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),

            const Divider(),

            // Logout
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const LoginScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // 👉 Body
      body: widget.body ?? screens[safeIndex],

      // 👉 Bottom Navigation
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed, // Important: shows all labels
        items: isWorker
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat),
                  label: "Chats",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person),
                  label: "Profile",
                ),
              ]
            : isClient
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.design_services),
                      label: "Services",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: "Chats",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.upload_file),
                      label: "Apply",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: "Profile",
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.design_services),
                      label: "Services",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat),
                      label: "Chats",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person),
                      label: "Profile",
                    ),
                  ],
      ),
    );
  }
}