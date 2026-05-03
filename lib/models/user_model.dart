class UserModel {
  final String uid;
  final String firstName;
  final String lastName;
  final DateTime birthDate;
  final String email;
  final DateTime createdAt;

  UserModel({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.birthDate,
    required this.email,
    required this.createdAt,
  });

  String get fullName => '$firstName $lastName';

  Map<String, dynamic> toMap() => {
    'uid': uid,
    'firstName': firstName,
    'lastName': lastName,
    'birthDate': birthDate.toIso8601String(),
    'email': email,
    'createdAt': createdAt.toIso8601String(),
  };

  factory UserModel.fromMap(Map<String, dynamic> map) => UserModel(
    uid: map['uid'],
    firstName: map['firstName'],
    lastName: map['lastName'],
    birthDate: DateTime.parse(map['birthDate']),
    email: map['email'],
    createdAt: DateTime.parse(map['createdAt']),
  );
}
