import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../models/notification.dart';
import '../../../../services/notification_service.dart';

class NotificationState {
  final List<AppNotification> notifications;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationState({
    this.notifications = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  NotificationState copyWith({
    List<AppNotification>? notifications,
    int? unreadCount,
    bool? isLoading,
    String? error,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: error, // Error goes away if not passed, by design, unless we pass null
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  final NotificationService _service;

  NotificationNotifier(this._service) : super(NotificationState()) {
    fetchNotifications();
  }

  Future<void> fetchNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _service.getNotifications();
      state = state.copyWith(
        isLoading: false,
        notifications: response.notifications,
        unreadCount: response.unreadCount,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> markAsRead(String id) async {
    try {
      await _service.markAsRead(id);
      
      // Optimistic UI update
      final updatedList = state.notifications.map((n) {
        if (n.id == id && !n.isRead) {
          return AppNotification(
            id: n.id,
            recipientId: n.recipientId,
            title: n.title,
            message: n.message,
            type: n.type,
            isRead: true,
            createdAt: n.createdAt,
          );
        }
        return n;
      }).toList();
      
      final currentUnread = state.unreadCount;
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: currentUnread > 0 ? currentUnread - 1 : 0,
      );
    } catch (e) {
      // Fetch again if fails
      fetchNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _service.markAllAsRead();
      
      // Optimistic UI update
      final updatedList = state.notifications.map((n) {
        return AppNotification(
          id: n.id,
          recipientId: n.recipientId,
          title: n.title,
          message: n.message,
          type: n.type,
          isRead: true,
          createdAt: n.createdAt,
        );
      }).toList();
      
      state = state.copyWith(
        notifications: updatedList,
        unreadCount: 0,
      );
    } catch (e) {
      fetchNotifications();
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref.watch(notificationServiceProvider));
});
