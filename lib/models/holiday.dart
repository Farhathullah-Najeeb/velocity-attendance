class Holiday {
  final String id;
  final String date;
  final String name;

  Holiday({
    required this.id,
    required this.date,
    required this.name,
  });

  factory Holiday.fromJson(Map<String, dynamic> json) {
    return Holiday(
      id: json['_id'] as String? ?? '',
      date: json['date'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}
