import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:skillbox/models/notification.dart';
import 'package:skillbox/models/user.dart';
import '../services/notification_service.dart';
import '../services/pusher_service.dart';
import '../services/popup_service.dart';
import '../services/api_service.dart';
import 'user_provider.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  final PusherService _pusherService = PusherService();
  UserProvider? _userProvider;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  NotificationProvider() {
    _initializePusher();
    loadNotifications();
    loadUnreadCount();
  }

  void updateUserProvider(UserProvider userProvider) {
    _userProvider = userProvider;
  }

  void _initializePusher() {
    _pusherService.initialize();
    
    // Listen for new notifications
    _pusherService.onNotificationReceived = (notification) {
      _notifications.insert(0, notification);
      _unreadCount++;
      notifyListeners();
      
      // Show toast
      _showNotificationToast(notification);

      // Also show popup using global navigator key (toast-like)
      PopupService.showPopup(notification);

       // If approval notification, refresh user to get new role.
       if (notification.type.toLowerCase() == 'accept') {
         _refreshUserFromServer();
       }
    };
  }

  Future<void> _refreshUserFromServer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null || _userProvider == null) return;

      final me = await ApiService.getCurrentUser(token);
      if (!me.containsKey('error')) {
        _userProvider!.setUser(User.fromJson(me));
      }
    } catch (_) {
      // swallow errors; best-effort refresh
    }
  }

  void _showNotificationToast(NotificationModel notification) {
    Fluttertoast.showToast(
      msg: '${notification.title}\n${notification.message}',
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.TOP,
      backgroundColor: _getColorForType(notification.type),
      textColor: Colors.white,
      fontSize: 16.0,
    );
  }

  Color _getColorForType(String type) {
    switch (type.toLowerCase()) {
      case 'success':
        return Colors.green;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  Future<void> loadNotifications({bool unreadOnly = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await NotificationService.getNotifications(
        limit: 50,
        unreadOnly: unreadOnly,
      );
    } catch (e) {
      print('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadUnreadCount() async {
    try {
      _unreadCount = await NotificationService.getUnreadCount();
      notifyListeners();
    } catch (e) {
      print('Error loading unread count: $e');
    }
  }

  Future<void> markAsRead(int notificationId) async {
    final success = await NotificationService.markAsRead(notificationId);
    
    if (success) {
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1 && !_notifications[index].isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }
      await loadNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    final success = await NotificationService.markAllAsRead();
    
    if (success) {
      _unreadCount = 0;
      await loadNotifications();
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    final success = await NotificationService.deleteNotification(notificationId);
    
    if (success) {
      final notification = _notifications.firstWhere(
        (n) => n.id == notificationId,
        orElse: () => _notifications.first,
      );
      
      if (!notification.isRead) {
        _unreadCount = (_unreadCount - 1).clamp(0, double.infinity).toInt();
      }
      
      _notifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _pusherService.disconnect();
    super.dispose();
  }
}