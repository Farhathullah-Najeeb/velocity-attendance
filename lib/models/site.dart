class Site {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final int? radiusMeters;
  final String? address;

  Site({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters,
    this.address,
  });

  factory Site.fromJson(Map<String, dynamic> json) {
    return Site(
      id: json['_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      radiusMeters: json['radiusMeters'] as int?,
      address: json['address'] as String?,
    );
  }
}
