class RegularizationRequest {
  final String id;
  final dynamic employeeId;
  final String dateStr;
  final String type; // 'ACCIDENTAL_CHECK_OUT' | 'MISSED_CHECK_IN' | 'MISSED_CHECK_OUT' | 'OTHER'
  final String requestedTime;
  final String reason;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final String? remarks;
  final String? createdAt;

  RegularizationRequest({
    required this.id,
    required this.employeeId,
    required this.dateStr,
    required this.type,
    required this.requestedTime,
    required this.reason,
    required this.status,
    this.remarks,
    this.createdAt,
  });

  factory RegularizationRequest.fromJson(Map<String, dynamic> json) {
    return RegularizationRequest(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'],
      dateStr: json['dateStr'] as String? ?? '',
      type: json['type'] as String? ?? '',
      requestedTime: json['requestedTime'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
