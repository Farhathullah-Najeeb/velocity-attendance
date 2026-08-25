class Overtime {
  final String id;
  final dynamic employeeId;
  final String date;
  final String dateStr;
  final String? startTime;
  final String? endTime;
  final String? workSummary;
  final double? latitude;
  final double? longitude;
  final String? address;
  final int overtimeMinutes;
  final String? reason;
  final String status;
  final String? remarks;

  Overtime({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.dateStr,
    this.startTime,
    this.endTime,
    this.workSummary,
    this.latitude,
    this.longitude,
    this.address,
    required this.overtimeMinutes,
    this.reason,
    required this.status,
    this.remarks,
  });

  factory Overtime.fromJson(Map<String, dynamic> json) {
    return Overtime(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'],
      date: json['date'] as String? ?? '',
      dateStr: json['dateStr'] as String? ?? '',
      startTime: json['startTime'] as String?,
      endTime: json['endTime'] as String?,
      workSummary: json['workSummary'] as String?,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      address: json['address'] as String?,
      overtimeMinutes: json['overtimeMinutes'] as int? ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
    );
  }
}
