import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String? id;
  final String email;
  final String password;
  final String username;

  const UserModel({
    this.id,
    required this.email,
    required this.password,
    required this.username,
  });

  toJson() {
    return {'email': email, 'password': password, 'username': username};
  }

  factory UserModel.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> document) {
    final data = document.data()!;
    return UserModel(
      id: document.id,
      email: data['email'],
      password: data['password'], 
      username: data['username'],
      );
  }
  
}
