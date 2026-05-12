import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  String id;
  String name;
  String code;
  String type;
  double price;
  int stock;
  String imageUrl;
  bool isFavorite;

  Product({
    required this.id,
    required this.name,
    required this.code,
    required this.type,
    required this.price,
    required this.stock,
    required this.imageUrl,
    this.isFavorite = false,
  });

  factory Product.fromFirestore(
      DocumentSnapshot doc,
      ) {
    final data = doc.data() as Map<String, dynamic>;

    return Product(
      id: doc.id,
      name: data['name'] ?? '',
      code: data['code'] ?? '',
      type: data['type'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      stock: data['stock'] ?? 0,
      imageUrl: data['imageUrl'] ?? '',
      isFavorite: data['isFavorite'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'code': code,
      'type': type,
      'price': price,
      'stock': stock,
      'imageUrl': imageUrl,
      'isFavorite': isFavorite,
    };
  }
}