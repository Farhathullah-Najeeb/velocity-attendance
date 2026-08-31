class UnifiedRequest {
  final String id;
  final String requestType; // 'OVERTIME' | 'WFH' | 'REGULARIZATION' | 'EXCEPTION' | 'LEAVE'
  final dynamic employee;
  final String dateStr;
  final String? date;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED' | 'NOT_REQUIRED'
  final String? reason;
  final String? workSummary;
  final String? remarks;
  final String? createdAt;
  final Map<String, dynamic>? details;

  UnifiedRequest({
    required this.id,
    required this.requestType,
    required this.employee,
    required this.dateStr,
    this.date,
    required this.status,
    this.reason,
    this.workSummary,
    this.remarks,
    this.createdAt,
    this.details,
  });

  factory UnifiedRequest.fromJson(Map<String, dynamic> json) {
    return UnifiedRequest(
      id: json['_id'] as String? ?? '',
      requestType: json['requestType'] as String? ?? '',
      employee: json['employee'],
      dateStr: json['dateStr'] as String? ?? '',
      date: json['date'] as String?,
      status: json['status'] as String? ?? 'PENDING',
      reason: json['reason'] as String?,
      workSummary: json['workSummary'] as String?,
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as String?,
      details: json['details'] as Map<String, dynamic>?,
    );
  }
}
