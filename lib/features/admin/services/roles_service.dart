import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/role.dart';

class RolesService {
  final Dio _dio;

  RolesService(this._dio);

  Future<List<Role>> getRoles() async {
    final response = await _dio.get('/roles');
    final data = response.data as List;
    return data.map((e) => Role.fromJson(e)).toList();
  }

  Future<List<String>> getSystemPermissions() async {
    final response = await _dio.get('/admin/permissions');
    final data = response.data as List;
    return data.map((e) => e.toString()).toList();
  }

  Future<void> createRole(String name, String description, List<String> permissions) async {
    await _dio.post('/roles', data: {
      'name': name,
      'description': description,
      'permissions': permissions,
    });
  }

  Future<void> updateRole(String id, String name, String description, List<String> permissions) async {
    await _dio.patch('/roles/$id', data: {
      'name': name,
      'description': description,
      'permissions': permissions,
    });
  }

  Future<void> deleteRole(String id) async {
    await _dio.delete('/roles/$id');
  }
}

final rolesServiceProvider = Provider<RolesService>((ref) {
  return RolesService(ref.watch(dioProvider));
});
