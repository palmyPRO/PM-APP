import 'package:cloud_firestore/cloud_firestore.dart';

class HistoryModel {
  final String id;
  final List items;
  final String userName;
  final String userEmail;
  final String companyId;
  final String companyName;

  HistoryModel({
    required this.id,
    required this.items,
    required this.userName,
    required this.userEmail,
    required this.companyId,
    required this.companyName,
  });

  factory HistoryModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return HistoryModel(
      id: doc.id,
      items: data['items'] ?? [],
      userName: data['user_name'] ?? '',
      userEmail: data['user_email'] ?? '',
      companyId: data['companyId'] ?? '',
      companyName: data['companyName'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'items': items,
      'user_name': userName,
      'user_email': userEmail,
      'companyId': companyId,
      'companyName': companyName,
      'checked_out_at': FieldValue.serverTimestamp(),
    };
  }
}