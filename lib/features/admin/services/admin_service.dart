import 'package:dio/dio.dart';
import '../../../core/utils/error_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/user.dart';
import '../../../models/attendance.dart';
import '../../../models/leave.dart';

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  Future<Map<String, dynamic>> getDashboardStats() async {
    final approvedRes = await _dio.get('/employees?status=APPROVED');
    final pendingRes = await _dio.get('/employees?status=PENDING');
    final pendingLeavesRes = await _dio.get('/leaves?status=PENDING');
    final pendingAttendanceRes = await _dio.get('/attendance/pending-approvals');

    Map<String, dynamic>? settingsData;
    bool isServerOnline = true;
    try {
      final settingsRes = await _dio.get('/settings');
      settingsData = settingsRes.data;
    } catch (e) {
      isServerOnline = false;
    }

    return {
      'approvedEmployees': (approvedRes.data as List).length,
      'pendingEmployees': (pendingRes.data as List).length,
      'pendingLeaves': (pendingLeavesRes.data as List).length,
      'pendingAttendance': (pendingAttendanceRes.data as List).length,
      'settings': settingsData,
      'isServerOnline': isServerOnline,
    };
  }

  Future<List<User>> getEmployees() async {
    final response = await _dio.get('/employees');
    final data = response.data as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<void> updateEmployeeStatus(String id, String status) async {
    await _dio.patch('/employees/$id/status', data: {'status': status});
  }

  Future<List<Leave>> getPendingLeaves() async {
    final response = await _dio.get('/leaves?status=PENDING');
    final data = response.data as List;
    return data.map((e) => Leave.fromJson(e)).toList();
  }

  Future<void> approveLeave(String id, String status, String remarks) async {
    await _dio.patch('/leaves/$id', data: {'status': status, 'remarks': remarks});
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(dioProvider));
});
