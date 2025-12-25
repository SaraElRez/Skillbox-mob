class Service {
  final int id;
  final String title;
  final String image;
  final String description;
  final int? createdBy;
  final int? updatedBy;
  final String? createdByName;
  final String? updatedByName;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Service({
    required this.id,
    required this.title,
    required this.image,
    required this.description,
    this.createdBy,
    this.updatedBy,
    this.createdByName,
    this.updatedByName,
    required this.createdAt,
    this.updatedAt,
  });

  factory Service.fromJson(Map<String, dynamic> json) {
    return Service(
      id: json['id'],
      title: json['title'],
      image: json['image'],
      description: json['description'],
      createdBy: json['created_by'],
      updatedBy: json['updated_by'],
      createdByName: json['created_by_name'],
      updatedByName: json['updated_by_name'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'image': image,
      'description': description,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_by_name': createdByName,
      'updated_by_name': updatedByName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
