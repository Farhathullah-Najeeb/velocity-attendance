class Overtime {
  final String id;
  final dynamic employeeId;
  final String date;
  final String dateStr;
  final int overtimeMinutes;
  final String? reason;
  final String status;
  final String? remarks;

  Overtime({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.dateStr,
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
      overtimeMinutes: json['overtimeMinutes'] as int? ?? 0,
      reason: json['reason'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
    );
  }
}
