class Settings {
  final String officeStartTime;
  final String officeEndTime;
  final int gracePeriod;
  final double? officeLatitude;
  final double? officeLongitude;
  final int? allowedRadiusMeters;
  final bool? geofencingEnabled;

  Settings({
    required this.officeStartTime,
    required this.officeEndTime,
    required this.gracePeriod,
    this.officeLatitude,
    this.officeLongitude,
    this.allowedRadiusMeters,
    this.geofencingEnabled,
  });

  factory Settings.fromJson(Map<String, dynamic> json) {
    return Settings(
      officeStartTime: json['officeStartTime'] as String? ?? '09:00',
      officeEndTime: json['officeEndTime'] as String? ?? '18:00',
      gracePeriod: json['gracePeriod'] as int? ?? 15,
      officeLatitude: (json['officeLatitude'] as num?)?.toDouble(),
      officeLongitude: (json['officeLongitude'] as num?)?.toDouble(),
      allowedRadiusMeters: json['allowedRadiusMeters'] as int?,
      geofencingEnabled: json['geofencingEnabled'] as bool?,
    );
  }
}

class LocationPolicy {
  final String location;
  final int monthlyPaidLeaveQuota;
  final int annualPaidLeaveQuota;

  LocationPolicy({
    required this.location,
    required this.monthlyPaidLeaveQuota,
    required this.annualPaidLeaveQuota,
  });

  factory LocationPolicy.fromJson(Map<String, dynamic> json) {
    return LocationPolicy(
      location: json['location'] as String? ?? '',
      monthlyPaidLeaveQuota: json['monthlyPaidLeaveQuota'] as int? ?? 1,
      annualPaidLeaveQuota: json['annualPaidLeaveQuota'] as int? ?? 12,
    );
  }
}
