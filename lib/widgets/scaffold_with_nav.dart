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
      const HomeScreen(),
      if (!isWorker) const ServicesScreen(),
      const ConversationsScreen(),
      if (isClient) const PortfolioSubmitScreen(),
      const ProfileScreen(),
    ];

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
        title: const Text(
          "SkillBox",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFF00BCD4),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, size: 26),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, notificationProvider, child) {
              final unreadCount = notificationProvider.unreadCount;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: badges.Badge(
                  showBadge: unreadCount > 0,
                  badgeContent: Text(
                    unreadCount > 99 ? '99+' : unreadCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  badgeStyle: const badges.BadgeStyle(
                    badgeColor: Colors.red,
                    padding: EdgeInsets.all(5),
                  ),
                  position: badges.BadgePosition.topEnd(top: 0, end: 3),
                  child: IconButton(
                    icon: const Icon(Icons.notifications, size: 26),
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

      // Professional Drawer
      drawer: Drawer(
        child: Column(
          children: [
            // Drawer Header with Gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF00BCD4),
                    const Color(0xFF0097A7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF00BCD4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Guest',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role ?? 'User',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    isSelected: safeIndex == 0,
                    onTap: () {
                      _onItemTapped(0);
                      Navigator.pop(context);
                    },
                  ),
                  if (!isWorker)
                    _buildDrawerItem(
                      icon: Icons.design_services_rounded,
                      title: 'Services',
                      isSelected: safeIndex == 1,
                      onTap: () {
                        _onItemTapped(1);
                        Navigator.pop(context);
                      },
                    ),
                  _buildDrawerItem(
                    icon: Icons.chat_rounded,
                    title: 'Conversations',
                    isSelected: safeIndex == (isWorker ? 1 : (isClient ? 2 : 2)),
                    onTap: () {
                      _onItemTapped(isWorker ? 1 : (isClient ? 2 : 2));
                      Navigator.pop(context);
                    },
                  ),
                  if (isClient)
                    _buildDrawerItem(
                      icon: Icons.upload_file_rounded,
                      title: 'Apply to be Worker',
                      isSelected: safeIndex == 3,
                      onTap: () {
                        _onItemTapped(3);
                        Navigator.pop(context);
                      },
                    ),
                  _buildDrawerItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    isSelected: safeIndex == (isWorker ? 2 : (isClient ? 4 : 3)),
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

            // Logout Button
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey[200]!, width: 1),
                ),
              ),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Colors.red,
                    size: 22,
                  ),
                ),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                tileColor: Colors.transparent,
              ),
            ),
          ],
        ),
      ),

      body: widget.body ?? screens[safeIndex],

      // Bottom Navigation Bar
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: safeIndex,
        onTap: _onItemTapped,
        selectedItemColor: const Color(0xFF00BCD4),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        backgroundColor: Colors.white,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 11,
        ),
        items: isWorker
            ? const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_rounded),
                  label: "Home",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.chat_rounded),
                  label: "Chats",
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.person_rounded),
                  label: "Profile",
                ),
              ]
            : isClient
                ? const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.design_services_rounded),
                      label: "Services",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_rounded),
                      label: "Chats",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.upload_file_rounded),
                      label: "Apply",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded),
                      label: "Profile",
                    ),
                  ]
                : const [
                    BottomNavigationBarItem(
                      icon: Icon(Icons.home_rounded),
                      label: "Home",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.design_services_rounded),
                      label: "Services",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.chat_rounded),
                      label: "Chats",
                    ),
                    BottomNavigationBarItem(
                      icon: Icon(Icons.person_rounded),
                      label: "Profile",
                    ),
                  ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00BCD4).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF00BCD4)
                : const Color(0xFF00BCD4).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? Colors.white : const Color(0xFF00BCD4),
            size: 22,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? const Color(0xFF00BCD4) : Colors.black87,
          ),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}