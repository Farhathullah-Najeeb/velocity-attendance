import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/user.dart';

class EmployeeService {
  final Dio _dio;

  EmployeeService(this._dio);

  Future<void> registerEmployee({
    required String name,
    required String email,
    required String password,
    required String department,
    required String location,
  }) async {
    await _dio.post('/employees/register', data: {
      'name': name,
      'email': email,
      'password': password,
      'department': department,
      'location': location,
    });
  }

  Future<List<User>> getEmployees({String status = 'ALL'}) async {
    final response = await _dio.get('/employees', queryParameters: {'status': status});
    final data = response.data as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<void> approveEmployee(String id) async {
    await _dio.patch('/employees/$id/approve');
  }

  Future<void> rejectEmployee(String id) async {
    await _dio.delete('/employees/$id/reject');
  }

  Future<void> toggleStatus(String id, bool isActive) async {
    await _dio.patch('/employees/$id/status', data: {'status': isActive ? 'ACTIVE' : 'DEACTIVE'});
  }

  Future<void> updateEmployee(String id, Map<String, dynamic> data) async {
    await _dio.patch('/employees/$id', data: data);
  }

  Future<void> assignRole(String id, String roleId) async {
    await _dio.patch('/employees/$id/role', data: {'roleId': roleId});
  }

  Future<void> assignSite(String id, String? siteId) async {
    await _dio.patch('/employees/$id/assign-site', data: {'siteId': siteId});
  }

  // Admins
  Future<List<User>> getAdmins() async {
    final response = await _dio.get('/admin/list');
    final data = response.data as List;
    return data.map((e) => User.fromJson(e)).toList();
  }

  Future<void> createAdmin({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    await _dio.post('/admin/create', data: {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
    });
  }

  Future<void> toggleAdminStatus(String id, bool isActive) async {
    await _dio.patch('/admin/$id/status', data: {'status': isActive ? 'ACTIVE' : 'DEACTIVE'});
  }

  Future<void> assignAdminRole(String id, String? roleId) async {
    await _dio.patch('/admin/$id/role', data: {'roleId': roleId});
  }

  Future<void> assignAdminPermissions(String id, List<String> permissions) async {
    await _dio.patch('/admin/$id/permissions', data: {'permissions': permissions});
  }
}

final employeeServiceProvider = Provider<EmployeeService>((ref) {
  return EmployeeService(ref.watch(dioProvider));
});
