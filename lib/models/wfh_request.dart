class WfhRequest {
  final String id;
  final dynamic employeeId;
  final String dateStr;
  final String reason;
  final String status; // 'PENDING' | 'APPROVED' | 'REJECTED'
  final String? remarks;
  final String? createdAt;

  WfhRequest({
    required this.id,
    required this.employeeId,
    required this.dateStr,
    required this.reason,
    required this.status,
    this.remarks,
    this.createdAt,
  });

  factory WfhRequest.fromJson(Map<String, dynamic> json) {
    return WfhRequest(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'],
      dateStr: json['dateStr'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
