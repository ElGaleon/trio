class Organization {
  const Organization({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.members,
    this.logoUrl,
  });

  final String id;
  final String name;
  final String ownerId;
  final List<String> members;
  final String? logoUrl;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'members': members,
      'logoUrl': logoUrl,
    };
  }

  static Organization fromMap(Map<dynamic, dynamic> map) {
    return Organization(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      ownerId: map['ownerId'] as String? ?? '',
      members: List<String>.from(map['members'] as List? ?? []),
      logoUrl: map['logoUrl'] as String?,
    );
  }
}
