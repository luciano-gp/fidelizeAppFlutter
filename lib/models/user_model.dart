class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isAdmin;
  final int points;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.isAdmin,
    required this.points,
  });

  factory UserModel.fromMap(String uid, Map<String, dynamic> map) {
    return UserModel(
      uid: uid,
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      isAdmin: map['isAdmin'] ?? false,
      points: map['points'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'isAdmin': isAdmin,
      'points': points,
    };
  }
}
