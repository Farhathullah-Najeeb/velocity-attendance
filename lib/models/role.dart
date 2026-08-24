class Role {
  final String id;
  final String name;
  final String? description;
  final List<String> permissions;

  Role({
    required this.id,
    required this.name,
    this.description,
    required this.permissions,
  });

  factory Role.fromJson(Map<String, dynamic> json) {
    return Role(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      permissions: (json['permissions'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}
