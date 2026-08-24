import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../models/settings.dart';
import '../../../models/holiday.dart';
import '../../../models/site.dart';

class SettingsService {
  final Dio _dio;

  SettingsService(this._dio);

  // Settings
  Future<Settings> getSettings() async {
    final response = await _dio.get('/settings');
    return Settings.fromJson(response.data);
  }

  Future<void> updateSettings(Map<String, dynamic> data) async {
    await _dio.patch('/settings', data: data);
  }

  // Location Policies
  Future<List<LocationPolicy>> getLocationPolicies() async {
    final response = await _dio.get('/settings/location-leave-policies');
    final data = response.data as List?;
    return data?.map((e) => LocationPolicy.fromJson(e)).toList() ?? [];
  }

  Future<void> updateLocationPolicy(String location, int monthlyQuota) async {
    await _dio.put('/settings/location-leave-policies', data: {
      'location': location,
      'monthlyPaidLeaveQuota': monthlyQuota,
    });
  }

  // Holidays
  Future<List<Holiday>> getHolidays() async {
    final response = await _dio.get('/holidays');
    final data = response.data as List;
    return data.map((e) => Holiday.fromJson(e)).toList();
  }

  Future<void> addHoliday(String date, String name) async {
    await _dio.post('/holidays', data: {'date': date, 'name': name});
  }

  Future<void> deleteHoliday(String id) async {
    await _dio.delete('/holidays/$id');
  }

  // Sites
  Future<List<Site>> getSites() async {
    final response = await _dio.get('/sites');
    final data = response.data as List?;
    return data?.map((e) => Site.fromJson(e)).toList() ?? [];
  }

  Future<void> addSite(Map<String, dynamic> data) async {
    await _dio.post('/sites', data: data);
  }

  Future<void> updateSite(String id, Map<String, dynamic> data) async {
    await _dio.patch('/sites/$id', data: data);
  }

  Future<void> deleteSite(String id) async {
    await _dio.delete('/sites/$id');
  }
}

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService(ref.watch(dioProvider));
});
