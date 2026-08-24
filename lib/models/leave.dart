class Leave {
  final String id;
  final dynamic employeeId;
  final String type;
  final String fromDate;
  final String toDate;
  final String reason;
  final String status;
  final String? remarks;
  
  Leave({
    required this.id,
    required this.employeeId,
    required this.type,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    required this.status,
    this.remarks,
  });

  factory Leave.fromJson(Map<String, dynamic> json) {
    return Leave(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'],
      type: json['type'] as String? ?? 'OTHER',
      fromDate: json['fromDate'] as String? ?? '',
      toDate: json['toDate'] as String? ?? '',
      reason: json['reason'] as String? ?? '',
      status: json['status'] as String? ?? 'PENDING',
      remarks: json['remarks'] as String?,
    );
  }
}

class LeaveBalanceDetail {
  final int? allowed;
  final int taken;
  final int remaining;
  final int? earned;
  final int? used;

  LeaveBalanceDetail({
    this.allowed,
    required this.taken,
    required this.remaining,
    this.earned,
    this.used,
  });

  factory LeaveBalanceDetail.fromJson(Map<String, dynamic> json) {
    return LeaveBalanceDetail(
      allowed: json['allowed'] as int?,
      taken: json['taken'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
      earned: json['earned'] as int?,
      used: json['used'] as int?,
    );
  }
}

class LeaveBalance {
  final Map<String, dynamic> employee;
  final Map<String, LeaveBalanceDetail> balances;

  LeaveBalance({
    required this.employee,
    required this.balances,
  });

  factory LeaveBalance.fromJson(Map<String, dynamic> json) {
    final balancesJson = json['balances'] as Map<String, dynamic>? ?? {};
    final balancesMap = <String, LeaveBalanceDetail>{};
    balancesJson.forEach((key, value) {
      if (key == 'OTHER' && value is Map<String, dynamic>) {
        balancesMap[key] = LeaveBalanceDetail(
          taken: value['taken'] as int? ?? 0,
          remaining: 0,
        );
      } else if (value is Map<String, dynamic>) {
        balancesMap[key] = LeaveBalanceDetail.fromJson(value);
      }
    });

    return LeaveBalance(
      employee: json['employee'] as Map<String, dynamic>? ?? {},
      balances: balancesMap,
    );
  }
}
