class Studio {
  final int id;
  final String name;
  final String description;
  final String location;
  final double pricePerHour;
  final String? imageUrl;
  final String? contactEmail;
  final String? contactPhone;
  final bool isAvailable;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Studio({
    required this.id,
    required this.name,
    required this.description,
    required this.location,
    required this.pricePerHour,
    this.imageUrl,
    this.contactEmail,
    this.contactPhone,
    required this.isAvailable,
    this.createdAt,
    this.updatedAt,
  });

  factory Studio.fromJson(Map<String, dynamic> json) {
    return Studio(
      id: json['id'] as int,
      name: json['name'] as String,
      description: json['description'] as String,
      location: json['location'] as String,
      pricePerHour: (json['pricePerHour'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String?,
      contactEmail: json['contactEmail'] as String?,
      contactPhone: json['contactPhone'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'location': location,
      'pricePerHour': pricePerHour,
      'imageUrl': imageUrl,
      'contactEmail': contactEmail,
      'contactPhone': contactPhone,
      'isAvailable': isAvailable,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'Studio{id: $id, name: $name, location: $location, pricePerHour: $pricePerHour}';
  }
}
