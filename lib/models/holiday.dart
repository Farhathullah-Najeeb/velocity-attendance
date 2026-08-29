class Holiday {
  final String id;
  final String date;
  final String dateStr;
  final String name;
  final String type; // 'NATIONAL' | 'REGIONAL' | 'BRANCH'
  final List<String> applicableLocations;
  final String? description;

  Holiday({
    required this.id,
    required this.date,
    required this.dateStr,
    required this.name,
    this.type = 'NATIONAL',
    this.applicableLocations = const [],
    this.description,
  });

  bool get isNational => type == 'NATIONAL' || applicableLocations.isEmpty;

  bool appliesTo(String? location) {
    if (isNational || location == null || location.isEmpty) return true;
    return applicableLocations.any(
      (loc) => loc.toLowerCase() == location.toLowerCase(),
    );
  }

  factory Holiday.fromJson(Map<String, dynamic> json) {
    final rawDate = json['date'] as String? ?? '';
    final dateStr = json['dateStr'] as String? ??
        (rawDate.length >= 10 ? rawDate.substring(0, 10) : rawDate);

    return Holiday(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      date: rawDate,
      dateStr: dateStr,
      name: json['name'] as String? ?? '',
      type: (json['type'] as String? ?? 'NATIONAL').toUpperCase(),
      applicableLocations: (json['applicableLocations'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      description: json['description'] as String?,
    );
  }
}
