class Attendance {
  final String id;
  final dynamic employeeId;
  final String date;
  final String dateStr;
  final String checkInTime;
  final String? checkOutTime;
  final bool? isWFH;
  final int? workDurationMinutes;
  final String? formattedWorkTime;
  final int? lateMinutes;
  final int? earlyExitMinutes;
  final bool? isLateArrival;
  final bool? isEarlyCheckout;
  final String approvalStatus; // 'PENDING' | 'APPROVED' | 'REJECTED' | 'NOT_REQUIRED'
  final String? remarks;
  final String? penaltyType;

  Attendance({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.dateStr,
    required this.checkInTime,
    this.checkOutTime,
    this.isWFH,
    this.workDurationMinutes,
    this.formattedWorkTime,
    this.lateMinutes,
    this.earlyExitMinutes,
    this.isLateArrival,
    this.isEarlyCheckout,
    required this.approvalStatus,
    this.remarks,
    this.penaltyType,
  });

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'],
      date: json['date'] as String? ?? '',
      dateStr: json['dateStr'] as String? ?? '',
      checkInTime: json['checkInTime'] as String? ?? '',
      checkOutTime: json['checkOutTime'] as String?,
      isWFH: json['isWFH'] as bool?,
      workDurationMinutes: json['workDurationMinutes'] as int?,
      formattedWorkTime: json['formattedWorkTime'] as String?,
      lateMinutes: json['lateMinutes'] as int?,
      earlyExitMinutes: json['earlyExitMinutes'] as int?,
      isLateArrival: json['isLateArrival'] as bool?,
      isEarlyCheckout: json['isEarlyCheckout'] as bool?,
      approvalStatus: json['approvalStatus'] as String? ?? 'NOT_REQUIRED',
      remarks: json['remarks'] as String?,
      penaltyType: json['penaltyType'] as String?,
    );
  }
}
