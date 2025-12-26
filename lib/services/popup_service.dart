import 'package:flutter/material.dart';
import 'package:skillbox/models/notification.dart';

class PopupService {
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  static void showPopup(NotificationModel notification, {Duration duration = const Duration(seconds: 4)}) {
    final ctx = navigatorKey.currentState?.overlay?.context;
    if (ctx == null) return;

    // Show a top-aligned toast-like dialog
    showGeneralDialog(
      context: ctx,
      barrierDismissible: true,
      barrierLabel: '',
      barrierColor: Colors.transparent,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8.0),
            child: _NotificationCard(notification: notification),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final offset = Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(animation);
        return SlideTransition(
          position: offset,
          child: FadeTransition(opacity: animation, child: child),
        );
      },
    );

    // Auto dismiss after [duration]
    Future.delayed(duration, () {
      try {
        if (navigatorKey.currentState != null && navigatorKey.currentState!.canPop()) {
          navigatorKey.currentState!.pop();
        }
      } catch (_) {}
    });
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  const _NotificationCard({required this.notification});

  Color _colorForType(String type) {
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

  @override
  Widget build(BuildContext context) {
    final bg = _colorForType(notification.type);

    return Material(
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16.0),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8.0),
          boxShadow: [
            BoxShadow(color: Colors.black26, blurRadius: 6.0, offset: Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.title,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 6),
            Text(
              notification.message,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
