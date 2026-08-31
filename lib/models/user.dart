class User {
  final String id;
  final String? employeeId;
  final String name;
  final String email;
  final String role; // 'EMPLOYEE' | 'ADMIN' | 'SUPER_ADMIN'
  final String? department;
  final String? location;
  final dynamic assignedSite;
  final String? staffType; // 'OFFICE' | 'SITE'
  final String? officeStartTime;
  final String? officeEndTime;
  final bool? isActive;
  final bool? isApproved;
  final List<String>? permissions;
  final String? createdAt;
  final String? updatedAt;

  User({
    required this.id,
    this.employeeId,
    required this.name,
    required this.email,
    required this.role,
    this.department,
    this.location,
    this.assignedSite,
    this.staffType,
    this.officeStartTime,
    this.officeEndTime,
    this.isActive,
    this.isApproved,
    this.permissions,
    this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] as String? ?? '',
      employeeId: json['employeeId'] as String?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: json['role'] as String? ?? 'EMPLOYEE',
      department: json['department'] as String?,
      location: json['location'] as String?,
      assignedSite: json['assignedSite'],
      staffType: json['staffType'] as String?,
      officeStartTime: json['officeStartTime'] as String?,
      officeEndTime: json['officeEndTime'] as String?,
      isActive: json['isActive'] as bool?,
      isApproved: json['isApproved'] as bool?,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e as String).toList(),
      createdAt: json['createdAt'] as String?,
      updatedAt: json['updatedAt'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      if (employeeId != null) 'employeeId': employeeId,
      'name': name,
      'email': email,
      'role': role,
      'department': department,
      'location': location,
      'assignedSite': assignedSite,
      'staffType': staffType,
      'officeStartTime': officeStartTime,
      'officeEndTime': officeEndTime,
      'isActive': isActive,
      'isApproved': isApproved,
      'permissions': permissions,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }
}
