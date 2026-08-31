import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_colors.dart';
import '../providers/notification_provider.dart';
import '../widgets/states.dart';
import '../widgets/responsive_container.dart';

@RoutePage()
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificationProvider);

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          if (state.notifications.isNotEmpty && state.unreadCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8, top: 4),
              child: Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: () {
                    ref.read(notificationProvider.notifier).markAllAsRead();
                  },
                  icon: Icon(Icons.done_all, color: Theme.of(context).colorScheme.primary),
                  label: Text('Mark all read', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
                ),
              ),
            ),
          Expanded(
            child: ResponsiveContainer(
              maxWidth: 1000,
              child: RefreshIndicator(
                onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
                child: _buildBody(context, state, ref),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context, NotificationState state, WidgetRef ref) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            Text(state.error!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(notificationProvider.notifier).fetchNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (state.notifications.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.notifications_off_outlined,
        title: 'You\'re all caught up',
        message: 'There are no new notifications at this time.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: state.notifications.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final notification = state.notifications[index];
        return _NotificationCard(
          notification: notification,
          onTap: () {
            if (!notification.isRead) {
              ref.read(notificationProvider.notifier).markAsRead(notification.id);
            }
          },
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final dynamic notification;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (notification.type) {
      case 'LEAVE_APPROVED':
        return Icons.check_circle_outline;
      case 'LEAVE_REJECTED':
        return Icons.cancel_outlined;
      case 'ATTENDANCE_WARNING':
        return Icons.warning_amber_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  Color _getIconColor(BuildContext context) {
    switch (notification.type) {
      case 'LEAVE_APPROVED':
        return VelocityColors.success;
      case 'LEAVE_REJECTED':
        return VelocityColors.error;
      case 'ATTENDANCE_WARNING':
        return VelocityColors.warning;
      default:
        return Theme.of(context).colorScheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: notification.isRead ? Theme.of(context).colorScheme.surface : Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _getIconColor(context).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(_getIcon(), color: _getIconColor(context), size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            style: TextStyle(
                              fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Text(
                          DateFormat('MMM d, h:mm a').format(notification.createdAt),
                          style: TextStyle(
                            color: Theme.of(context).unselectedWidgetColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      notification.message,
                      style: TextStyle(
                        color: Theme.of(context).textTheme.bodySmall?.color,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (!notification.isRead) ...[
                const SizedBox(width: 8),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
