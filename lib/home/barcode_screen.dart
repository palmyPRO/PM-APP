import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'cart_screen.dart';
import 'favorite_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class BarcodeScreen extends StatefulWidget {
  const BarcodeScreen({super.key});

  @override
  State<BarcodeScreen> createState() => _BarcodeScreenState();
}

class _BarcodeScreenState extends State<BarcodeScreen> {
  bool scanned = false;

  Future<String> getCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return userDoc.data()?['companyId'] ?? '';
  }

  Future<void> findProduct(String barcode) async {
    final companyId = await getCompanyId();

    if (companyId == '') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please join company first")),
      );

      setState(() {
        scanned = false;
      });

      return;
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .where('code', isEqualTo: barcode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Product not found : $barcode")),
      );

      setState(() {
        scanned = false;
      });

      return;
    }

    final product = snapshot.docs.first;
    final data = product.data();

    showProductDialog(
      companyId: companyId,
      productId: product.id,
      data: data,
    );
  }

  void showProductDialog({
    required String companyId,
    required String productId,
    required Map<String, dynamic> data,
  }) {
    int quantity = 1;
    final stock = data['stock'] ?? 0;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: Text(
                data['name'] ?? '',
                style: const TextStyle(color: Colors.white),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (data['imageUrl'] != null && data['imageUrl'] != "")
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        data['imageUrl'],
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),

                  const SizedBox(height: 15),

                  Text(
                    "Code : ${data['code'] ?? ''}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Type : ${data['type'] ?? ''}",
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text(
                    "Price : ${data['price'] ?? 0}",
                    style: const TextStyle(color: Colors.orange),
                  ),
                  Text(
                    "Stock : ${data['stock'] ?? 0}",
                    style: const TextStyle(color: Colors.white),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    "Quantity",
                    style: TextStyle(color: Colors.white70),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if (quantity > 1) {
                            setDialogState(() {
                              quantity--;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.remove,
                          color: Colors.white,
                        ),
                      ),

                      Text(
                        quantity.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),

                      IconButton(
                        onPressed: () {
                          if (quantity < stock) {
                            setDialogState(() {
                              quantity++;
                            });
                          }
                        },
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);

                    setState(() {
                      scanned = false;
                    });
                  },
                  child: const Text(
                    "Close",
                    style: TextStyle(color: Colors.white54),
                  ),
                ),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                  ),
                  onPressed: stock <= 0
                      ? null
                      : () async {
                    await addToCart(
                      companyId: companyId,
                      productId: productId,
                      data: data,
                      quantity: quantity,
                    );

                    Navigator.pop(context);

                    setState(() {
                      scanned = false;
                    });
                  },
                  child: const Text(
                    "Add To Cart",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> addToCart({
    required String companyId,
    required String productId,
    required Map<String, dynamic> data,
    required int quantity,
  }) async {
    final stock = data['stock'] ?? 0;

    if (stock < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Stock not enough")),
      );
      return;
    }

    final cartRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('cart');

    final existing = await cartRef
        .where('productId', isEqualTo: productId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) {
      final cartDoc = existing.docs.first;
      final oldQty = cartDoc['quantity'] ?? 1;

      await cartDoc.reference.update({
        'quantity': oldQty + quantity,
      });
    } else {
      await cartRef.add({
        'productId': productId,
        'name': data['name'] ?? '',
        'code': data['code'] ?? '',
        'type': data['type'] ?? '',
        'price': data['price'] ?? 0,
        'imageUrl': data['imageUrl'] ?? '',
        'quantity': quantity,
        'created_at': FieldValue.serverTimestamp(),
      });
    }

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .doc(productId)
        .update({
      'stock': stock - quantity,
      'updated_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        title: const Text("Barcode Scanner"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),

      body: MobileScanner(
        controller: MobileScannerController(
          formats: const [
            BarcodeFormat.code128,
          ],
        ),
        onDetect: (capture) async {
          if (scanned) return;

          final barcode = capture.barcodes.first.rawValue;

          if (barcode == null) return;

          setState(() {
            scanned = true;
          });

          await findProduct(barcode);
        },
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor: const Color(0xFFFF6A00),
        unselectedItemColor: Colors.white54,
        currentIndex: 2,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomeScreen()),
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const FavoriteScreen(products: []),
              ),
            );
          }

          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          }

          if (index == 4) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite_border, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_bag_outlined, size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined, size: 30),
            label: "",
          ),
        ],
      ),
    );
  }
}