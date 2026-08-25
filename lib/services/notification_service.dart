import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/notification.dart';

class NotificationResponse {
  final List<AppNotification> notifications;
  final int unreadCount;

  NotificationResponse({required this.notifications, required this.unreadCount});
}

class NotificationService {
  final Dio _dio;

  NotificationService(this._dio);

  Future<NotificationResponse> getNotifications() async {
    final response = await _dio.get('/notifications');
    final data = response.data;
    
    final notificationsList = (data['notifications'] as List)
        .map((e) => AppNotification.fromJson(e))
        .toList();
        
    return NotificationResponse(
      notifications: notificationsList,
      unreadCount: data['unreadCount'] ?? 0,
    );
  }

  Future<void> markAllAsRead() async {
    await _dio.patch('/notifications/read-all');
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch('/notifications/$id/read');
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(ref.watch(dioProvider));
});
