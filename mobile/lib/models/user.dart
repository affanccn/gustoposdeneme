class UserSession {
  final String id;
  final String name;
  final String role; // "WAITER" or "ADMIN" or "MANAGER"

  UserSession({
    required this.id,
    required this.name,
    required this.role,
  });

  bool get isAdmin => role == 'ADMIN' || role == 'MANAGER';
  bool get isWaiter => role == 'WAITER';

  factory UserSession.fromJson(Map<String, dynamic> json) {
    return UserSession(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Kullanıcı',
      role: json['role']?.toString() ?? 'WAITER',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'role': role,
    };
  }
}
