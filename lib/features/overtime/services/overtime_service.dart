import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/overtime.dart';

class OvertimeService {
  final Dio _dio;

  OvertimeService(this._dio);

  Future<void> submitOvertime(String date, int minutes, String reason) async {
    await _dio.post('/overtime', data: {
      'date': date,
      'overtimeMinutes': minutes,
      'reason': reason,
    });
  }

  Future<List<Overtime>> getMyOvertime() async {
    final response = await _dio.get('/overtime/my-overtime');
    final data = response.data as List;
    return data.map((e) => Overtime.fromJson(e)).toList();
  }

  Future<List<Overtime>> getAllOvertime({String? status, String? employeeId}) async {
    final response = await _dio.get('/overtime', queryParameters: {
      if (status != null) 'status': status,
      if (employeeId != null) 'employeeId': employeeId,
    });
    final data = response.data as List;
    return data.map((e) => Overtime.fromJson(e)).toList();
  }

  Future<void> updateOvertimeStatus(String id, String status, [String? remarks]) async {
    await _dio.patch('/overtime/$id/status', data: {
      'status': status,
      if (remarks != null) 'remarks': remarks,
    });
  }
}

final overtimeServiceProvider = Provider<OvertimeService>((ref) {
  return OvertimeService(ref.watch(dioProvider));
});
