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
      'status': ?status,
      'type': ?type,
      'employeeId': ?employeeId,
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
    if (employeeId.isEmpty) {
      return LeaveBalance(
        employee: {},
        balances: {
          'CASUAL': LeaveBalanceDetail(allowed: 12, taken: 0, remaining: 12),
          'SICK': LeaveBalanceDetail(allowed: 12, taken: 0, remaining: 12),
          'COMPENSATORY': LeaveBalanceDetail(
            allowed: 0,
            taken: 0,
            remaining: 0,
            earned: 0,
            used: 0,
          ),
        },
      );
    }
    try {
      final response = await _dio.get('/leaves/balance/$employeeId');
      return LeaveBalance.fromJson(response.data);
    } catch (_) {
      return LeaveBalance(
        employee: {'id': employeeId},
        balances: {
          'CASUAL': LeaveBalanceDetail(allowed: 12, taken: 0, remaining: 12),
          'SICK': LeaveBalanceDetail(allowed: 12, taken: 0, remaining: 12),
          'COMPENSATORY': LeaveBalanceDetail(
            allowed: 0,
            taken: 0,
            remaining: 0,
            earned: 0,
            used: 0,
          ),
        },
      );
    }
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

final employeeLeaveBalanceProvider = FutureProvider.autoDispose
    .family<LeaveBalance, String>((ref, employeeId) {
      if (employeeId.isEmpty) {
        return Future.value(LeaveBalance(employee: {}, balances: {}));
      }
      return ref.watch(leaveServiceProvider).getLeaveBalance(employeeId);
    });
