// lib/User_model.dart
class UserModel {
  final String uid;
  final String email;
  double balance;

  UserModel({
    required this.uid,
    required this.email,
    this.balance = 0.0,
  });
}
