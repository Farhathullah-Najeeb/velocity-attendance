import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/attendance.dart';

class AttendanceService {
  final Dio _dio;

  AttendanceService(this._dio);

  Future<void> checkIn(double lat, double lng, [String? address, bool isWfh = false, String? reason]) async {
    await _dio.post('/attendance/check-in', data: {
      'latitude': lat,
      'longitude': lng,
      'address': ?address,
      'isWFH': isWfh,
      if (reason != null && reason.isNotEmpty) 'reason': reason,
    });
  }

  Future<void> checkOut(double lat, double lng, [String? address, bool isWfh = false, String? workSummary]) async {
    await _dio.post('/attendance/check-out', data: {
      'latitude': lat,
      'longitude': lng,
      'address': ?address,
      'isWFH': isWfh,
      if (workSummary != null && workSummary.isNotEmpty) 'workSummary': workSummary,
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

  Future<void> applyPenalty(String id, String penaltyType, [String? remarks]) async {
    await _dio.patch('/attendance/$id/penalty', data: {
      'penaltyType': penaltyType,
      'remarks': ?remarks,
    });
  }

  Future<List<Attendance>> getLiveMonitoring(String? date) async {
    final response = await _dio.get('/attendance/wfh-overtime-locations', queryParameters: {
      'date': ?date,
    });
    final data = response.data as List;
    return data.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<List<Attendance>> getHistory(String employeeId, {String? startDate, String? endDate}) async {
    final response = await _dio.get('/attendance/history/$employeeId', queryParameters: {
      'startDate': ?startDate,
      'endDate': ?endDate,
    });
    final data = response.data as List;
    return data.map((e) => Attendance.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> getWeeklyReport({String? employeeId}) async {
    final response = await _dio.get('/attendance/weekly-report', queryParameters: {
      'employeeId': ?employeeId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getMonthlyReport({String? employeeId}) async {
    final response = await _dio.get('/attendance/monthly-report', queryParameters: {
      'employeeId': ?employeeId,
    });
    return response.data;
  }

  Future<Map<String, dynamic>> getCustomReport({required String startDate, required String endDate, String? employeeId}) async {
    final response = await _dio.get('/attendance/custom-report', queryParameters: {
      'startDate': startDate,
      'endDate': endDate,
      'employeeId': ?employeeId,
    });
    return response.data;
  }

  Future<List<int>> exportReport({required String format, String? type, String? employeeId, String? startDate, String? endDate}) async {
    final response = await _dio.get('/attendance/report/export', queryParameters: {
      'format': format,
      'type': ?type,
      'employeeId': ?employeeId,
      'startDate': ?startDate,
      'endDate': ?endDate,
    }, options: Options(responseType: ResponseType.bytes));
    return response.data as List<int>;
  }

  // --- WFH Requests ---
  Future<void> requestWfh(String dateStr, String reason) async {
    await _dio.post('/attendance/wfh-request', data: {
      'dateStr': dateStr,
      'reason': reason,
    });
  }

  Future<List<dynamic>> getWfhRequests({String? status, String? dateStr, String? employeeId}) async {
    final response = await _dio.get('/attendance/wfh-request', queryParameters: {
      'status': status,
      'dateStr': dateStr,
      'employeeId': employeeId,
    });
    return response.data as List;
  }

  Future<void> approveWfhRequest(String id, String remarks) async {
    await _dio.patch('/attendance/wfh-request/$id/approve', data: {
      'remarks': remarks,
    });
  }

  Future<void> rejectWfhRequest(String id, String remarks) async {
    await _dio.patch('/attendance/wfh-request/$id/reject', data: {
      'remarks': remarks,
    });
  }

  // --- Regularization Requests ---
  Future<void> requestRegularization(String dateStr, String type, String requestedTime, String reason) async {
    await _dio.post('/attendance/regularization-request', data: {
      'dateStr': dateStr,
      'type': type,
      'requestedTime': requestedTime,
      'reason': reason,
    });
  }

  Future<List<dynamic>> getRegularizationRequests({String? status, String? dateStr, String? employeeId}) async {
    final response = await _dio.get('/attendance/regularization-request', queryParameters: {
      'status': status,
      'dateStr': dateStr,
      'employeeId': employeeId,
    });
    return response.data as List;
  }

  Future<List<dynamic>> getPendingRegularizations() async {
    final response = await _dio.get('/attendance/pending-regularizations');
    return response.data as List;
  }

  Future<void> approveRegularizationRequest(String id, String remarks) async {
    await _dio.patch('/attendance/regularization-request/$id/approve', data: {
      'remarks': remarks,
    });
  }

  Future<void> rejectRegularizationRequest(String id, String remarks) async {
    await _dio.patch('/attendance/regularization-request/$id/reject', data: {
      'remarks': remarks,
    });
  }
}

final attendanceServiceProvider = Provider<AttendanceService>((ref) {
  return AttendanceService(ref.watch(dioProvider));
});
