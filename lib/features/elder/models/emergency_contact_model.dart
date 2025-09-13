class EmergencyContact {
  final String id;
  final String name;
  final String relationship;
  final String phone;
  final String? photoUrl;
  final int priority;
  final DateTime createdAt;

  EmergencyContact({
    required this.id,
    required this.name,
    required this.relationship,
    required this.phone,
    this.photoUrl,
    required this.priority,
    required this.createdAt,
  });

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      relationship: json['relationship'] ?? '',
      phone: json['phone'] ?? '',
      photoUrl: json['photo_url'],
      priority: json['priority'] ?? 999,
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'relationship': relationship,
      'phone': phone,
      'photo_url': photoUrl,
      'priority': priority,
      'created_at': createdAt.toIso8601String(),
    };
  }
}