class Holiday {
  final String id;
  final String date;
  final String name;
  final String? type;
  final List<String>? applicableLocations;
  final String? description;

  Holiday({
    required this.id,
    required this.date,
    required this.name,
    this.type,
    this.applicableLocations,
    this.description,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: json['type'] as String?,
      applicableLocations: (json['applicableLocations'] as List?)?.map((e) => e.toString()).toList(),
      description: json['description'] as String?,
    );
  }
}
