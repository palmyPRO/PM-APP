import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String uid;
  String name;
  String email;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
  });

  // Firestore -> Object
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data =
    doc.data() as Map<String, dynamic>;

    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  // Object -> Firestore
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}