import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/notification_provider.dart';
import '../../../core/router/app_router.dart';


class NotificationBadge extends ConsumerWidget {
  final Color? color;
  final double size;

  const NotificationBadge({
    super.key,
    this.color,
    this.size = 24.0,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(notificationProvider).unreadCount;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: Icon(Icons.notifications_none, color: color ?? Colors.grey.shade600, size: size),
          onPressed: () {
            context.router.push(const NotificationsRoute());
          },
        ),
        if (unreadCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.error,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 16,
                minHeight: 16,
              ),
              child: Center(
                child: Text(
                  unreadCount > 9 ? '9+' : unreadCount.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onError,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
