import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';

class AdminService {
  final Dio _dio;

  AdminService(this._dio);

  Future<Map<String, dynamic>> getDashboardStats() async {
    final results = await Future.wait([
      _dio.get('/employees', queryParameters: {'status': 'APPROVED'}),
      _dio.get('/employees', queryParameters: {'status': 'PENDING'}),
      _dio.get('/leaves', queryParameters: {'status': 'PENDING'}),
      _dio.get('/attendance/pending-approvals'),
      _dio.get('/overtime/pending').catchError((_) => Response(
            requestOptions: RequestOptions(path: '/overtime/pending'),
            data: [],
          )),
      _dio.get('/sites', queryParameters: {'activeOnly': true}).catchError(
            (_) => Response(
              requestOptions: RequestOptions(path: '/sites'),
              data: [],
            ),
          ),
    ]);

    Map<String, dynamic>? settingsData;
    bool isServerOnline = true;
    try {
      final settingsRes = await _dio.get('/settings');
      settingsData = settingsRes.data as Map<String, dynamic>?;
    } catch (_) {
      isServerOnline = false;
    }

    return {
      'approvedEmployees': (results[0].data as List).length,
      'pendingEmployees': (results[1].data as List).length,
      'pendingLeaves': (results[2].data as List).length,
      'pendingAttendance': (results[3].data as List).length,
      'pendingOvertime': (results[4].data as List).length,
      'activeSites': (results[5].data as List).length,
      'settings': settingsData,
      'isServerOnline': isServerOnline,
    };
  }
}

final adminServiceProvider = Provider<AdminService>((ref) {
  return AdminService(ref.watch(dioProvider));
});
