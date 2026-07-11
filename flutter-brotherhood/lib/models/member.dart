class Member {
  final String id;
  final String name;
  final bool isAdmin;

  const Member({
    required this.id,
    required this.name,
    this.isAdmin = false,
  });

  /// The three Brotherhood members. No fourth member.
  static const List<Member> all = [
    Member(id: 'vansh', name: 'Vansh', isAdmin: true),
    Member(id: 'govind', name: 'Govind'),
    Member(id: 'piyush', name: 'Piyush'),
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
