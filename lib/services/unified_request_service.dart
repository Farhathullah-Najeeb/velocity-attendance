import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/network/dio_client.dart';
import '../models/unified_request.dart';

class UnifiedRequestService {
  final Dio _dio;

  UnifiedRequestService(this._dio);

  Future<List<UnifiedRequest>> getRequests({
    String? type,
    String? status,
    String? employeeId,
    String? dateStr,
  }) async {
    final response = await _dio.get('/requests', queryParameters: {
      if (type != null && type != 'ALL') 'type': type,
      if (status != null && status != 'ALL') 'status': status,
      if (employeeId != null && employeeId.isNotEmpty) 'employeeId': employeeId,
      if (dateStr != null && dateStr.isNotEmpty) 'dateStr': dateStr,
    });

    final data = response.data;
    List rawList = [];
    if (data is Map && data.containsKey('requests')) {
      rawList = data['requests'] as List;
    } else if (data is List) {
      rawList = data;
    }

    return rawList.map((e) => UnifiedRequest.fromJson(e as Map<String, dynamic>)).toList();
  }
}

final unifiedRequestServiceProvider = Provider<UnifiedRequestService>((ref) {
  return UnifiedRequestService(ref.watch(dioProvider));
});
