class Member {
  final String id;
  final String name;
  final bool isAdmin;

  const Member({
    required this.id,
    required this.name,
    this.isAdmin = false,
  });

  static const List<Member> all = [
    Member(id: 'vansh', name: 'Vansh', isAdmin: true),
    Member(id: 'piyush', name: 'Piyush'),
    Member(id: 'govind', name: 'Govind'),
    Member(id: 'member4', name: 'Member 4'),
  ];

  static Member? fromId(String id) {
    try {
      return all.firstWhere((m) => m.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'isAdmin': isAdmin,
      };

  @override
  String toString() => name;
}
