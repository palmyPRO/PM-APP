import 'package:cloud_firestore/cloud_firestore.dart';

class CartModel {
  final String id;
  final String productId;
  final String name;
  final String code;
  final String type;
  final double price;
  final int quantity;

  CartModel({
    required this.id,
    required this.productId,
    required this.name,
    required this.code,
    required this.type,
    required this.price,
    required this.quantity,
  });

  factory CartModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return CartModel(
      id: doc.id,
      productId: data['productId'] ?? '',
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      quantity: data['quantity'] ?? 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'name': name,
      'code': code,
      'type': type,
      'price': price,
      'quantity': quantity,
      'created_at': FieldValue.serverTimestamp(),
    };
  }
}