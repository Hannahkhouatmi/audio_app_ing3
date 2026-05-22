
class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String email;
  final String? phone; //optionel
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.email,
    this.phone,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'birthDate': birthDate.toIso8601String(),
      'email': email,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    return UserModel(
      uid: documentId,
      firstName: map['firstName'] ?? '',
      lastName: map['lastName'] ?? '',
      birthDate: map['birthDate'] != null ? DateTime.parse(map['birthDate']) : DateTime.now(),
      email: map['email'] ?? '',
      phone: map['phone'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : DateTime.now(),
    );
  }
}
