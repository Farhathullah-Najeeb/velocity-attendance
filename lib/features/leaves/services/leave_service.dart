import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/leave.dart';

class LeaveService {
  final Dio _dio;

  LeaveService(this._dio);

  Future<void> applyLeave(String type, String fromDate, String toDate, String reason) async {
    await _dio.post('/leaves/apply', data: {
      'type': type,
      'fromDate': fromDate,
      'toDate': toDate,
      'reason': reason,
    });
  }

  Future<List<Leave>> getLeaves({String? status, String? type, String? employeeId}) async {
    final response = await _dio.get('/leaves', queryParameters: {
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (employeeId != null) 'employeeId': employeeId,
    });
    final data = response.data as List;
    return data.map((e) => Leave.fromJson(e)).toList();
  }

  Future<void> approveLeave(String id, String remarks) async {
    await _dio.patch('/leaves/$id/approve', data: {
      'remarks': remarks,
    });
  }

  Future<void> rejectLeave(String id, String remarks) async {
    await _dio.patch('/leaves/$id/reject', data: {
      'remarks': remarks,
    });
  }

  Future<LeaveBalance> getLeaveBalance(String employeeId) async {
    final response = await _dio.get('/leaves/balance/$employeeId');
    return LeaveBalance.fromJson(response.data);
  }

  Future<void> cancelLeave(String id) async {
    await _dio.patch('/leaves/$id/cancel');
  }

  Future<void> revokeLeave(String id, String remarks) async {
    await _dio.patch('/leaves/$id/revoke', data: {
      'remarks': remarks,
    });
  }
}

final leaveServiceProvider = Provider<LeaveService>((ref) {
  return LeaveService(ref.watch(dioProvider));
});
