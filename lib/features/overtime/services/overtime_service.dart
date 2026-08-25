import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/overtime.dart';

class OvertimeService {
  final Dio _dio;

  OvertimeService(this._dio);

  Future<void> submitOvertime({
    required String dateStr,
    required String startTime,
    required String endTime,
    required String workSummary,
    required double latitude,
    required double longitude,
    required String address,
  }) async {
    await _dio.post('/overtime/request', data: {
      'dateStr': dateStr,
      'startTime': startTime,
      'endTime': endTime,
      'workSummary': workSummary,
      'latitude': latitude,
      'longitude': longitude,
      'address': address,
    });
  }

  Future<List<Overtime>> getMyOvertime({required String employeeId}) async {
    final response = await _dio.get(
      '/overtime',
      queryParameters: {'employeeId': employeeId},
    );
    final data = response.data as List;
    return data.map((e) => Overtime.fromJson(e)).toList();
  }

  Future<List<Overtime>> getAllOvertime({String? status, String? employeeId}) async {
    final response = await _dio.get('/overtime', queryParameters: {
      'status': ?status,
      'employeeId': ?employeeId,
    });
    final data = response.data as List;
    return data.map((e) => Overtime.fromJson(e)).toList();
  }

  Future<List<Overtime>> getPendingOvertime() async {
    final response = await _dio.get('/overtime/pending');
    final data = response.data as List;
    return data.map((e) => Overtime.fromJson(e)).toList();
  }

  Future<void> updateOvertimeStatus(String id, String status, [String? remarks]) async {
    if (status == 'APPROVED') {
      await _dio.patch('/overtime/$id/approve', data: {
        'remarks': ?remarks,
      });
    } else if (status == 'REJECTED') {
      await _dio.patch('/overtime/$id/reject', data: {
        'remarks': ?remarks,
      });
    }
  }
}

final overtimeServiceProvider = Provider<OvertimeService>((ref) {
  return OvertimeService(ref.watch(dioProvider));
});
