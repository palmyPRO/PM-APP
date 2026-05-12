import 'package:cloud_firestore/cloud_firestore.dart';

class CompanyModel {
  final String id;
  final String name;
  final String code;
  final String createdBy;

  CompanyModel({
    required this.id,
    required this.name,
    required this.code,
    required this.createdBy,
  });

  factory CompanyModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CompanyModel(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      createdBy: data['createdBy'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }
}