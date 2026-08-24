import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/attendance.dart';

class AttendanceService {
  final Dio _dio;

  AttendanceService(this._dio);

  Future<void> checkIn(double lat, double lng, [String? address]) async {
    await _dio.post('/attendance/check-in', data: {
      'latitude': lat,
      'longitude': lng,
      'address': address,
    });
  }

  Future<void> checkOut(double lat, double lng, [String? address]) async {
    await _dio.post('/attendance/check-out', data: {
      'latitude': lat,
      'longitude': lng,
      'address': address,
    });
  }

  Future<List<Attendance>> getPendingApprovals() async {
    final response = await _dio.get('/attendance/pending-approvals');
    final data = response.data as List;
    return data.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<void> approveAttendance(String id, String remarks, String penaltyType) async {
    await _dio.patch('/attendance/$id/approve', data: {
      'remarks': remarks,
      'penaltyType': penaltyType,
    });
  }

  Future<void> rejectAttendance(String id, String remarks) async {
    await _dio.patch('/attendance/$id/reject', data: {
      'remarks': remarks,
    });
  }

  Future<void> applyPenalty(String id, String penaltyType) async {
    await _dio.patch('/attendance/$id/penalty', data: {
      'penaltyType': penaltyType,
    });
  }

  Future<List<Attendance>> getLiveMonitoring(String? date) async {
    final response = await _dio.get('/attendance/wfh-overtime-locations', queryParameters: {
      if (date != null) 'date': date,
    });
    final data = response.data as List;
    return data.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<List<Attendance>> getHistory(String employeeId, {String? startDate, String? endDate}) async {
    final response = await _dio.get('/attendance/history/$employeeId', queryParameters: {
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    });
    final data = response.data as List;
    return data.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getWeeklyReport({String? employeeId}) async {
    final response = await _dio.get('/attendance/weekly-report', queryParameters: {
      if (employeeId != null) 'employeeId': employeeId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMonthlyReport({String? employeeId}) async {
    final response = await _dio.get('/attendance/monthly-report', queryParameters: {
      if (employeeId != null) 'employeeId': employeeId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getCustomReport({required String startDate, required String endDate, String? employeeId}) async {
    final response = await _dio.get('/attendance/custom-report', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      if (employeeId != null) 'employeeId': employeeId,
    });
    return response.data;
  }

  Future<List<int>> exportReport({required String format, String? type, String? employeeId, String? startDate, String? endDate}) async {
    final response = await _dio.get('/attendance/report/export', queryParameters: {
      'format': format,
      if (type != null) 'type': type,
      if (employeeId != null) 'employeeId': employeeId,
      if (startDate != null) 'startDate': startDate,
      if (endDate != null) 'endDate': endDate,
    }, options: Options(responseType: ResponseType.bytes));
    return response.data as List<int>;
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(ref.watch(dioProvider));
});
