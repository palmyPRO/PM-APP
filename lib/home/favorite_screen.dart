import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart';
import 'barcode_screen.dart';
import 'cart_screen.dart';
import 'profile_screen.dart';

class FavoriteScreen extends StatelessWidget {
  const FavoriteScreen({super.key, required List products});

  Future<String> getCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return userDoc.data()?['companyId'] ?? '';
  }

  Future<void> addToCart({
    required BuildContext context,
    required String companyId,
    required QueryDocumentSnapshot item,
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
        .where('productId', isEqualTo: item.id)
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
        'productId': item.id,
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
        .doc(item.id)
        .update({
      'stock': stock - quantity,
      'updated_at': FieldValue.serverTimestamp(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Added to cart")),
    );
  }

  void showQuantityDialog({
    required BuildContext context,
    required String companyId,
    required QueryDocumentSnapshot item,
    required Map<String, dynamic> data,
  }) {
    int quantity = 1;
    final stock = data['stock'] ?? 0;

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              backgroundColor: Colors.grey[900],
              title: const Text(
                "Select Quantity",
                style: TextStyle(color: Colors.white),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      if (quantity > 1) {
                        setStateDialog(() {
                          quantity--;
                        });
                      }
                    },
                    icon: const Icon(Icons.remove, color: Colors.white),
                  ),
                  Text(
                    quantity.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      if (quantity < stock) {
                        setStateDialog(() {
                          quantity++;
                        });
                      }
                    },
                    icon: const Icon(Icons.add, color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Cancel",
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
                      context: context,
                      companyId: companyId,
                      item: item,
                      data: data,
                      quantity: quantity,
                    );

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "Add",
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

  Widget productCard({
    required BuildContext context,
    required String companyId,
    required QueryDocumentSnapshot item,
  }) {
    final data = item.data() as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 8,
      ),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white24,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (data['imageUrl'] != null && data['imageUrl'] != "")
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                data['imageUrl'],
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),

          const SizedBox(height: 15),

          Text(
            "Name : ${data['name'] ?? ''}",
            style: const TextStyle(color: Colors.white),
          ),
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

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.favorite,
                  color: Color(0xFFFF6A00),
                ),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('companies')
                      .doc(companyId)
                      .collection('products')
                      .doc(item.id)
                      .update({
                    'isFavorite': false,
                  });
                },
              ),

              ElevatedButton(
                onPressed: () {
                  showQuantityDialog(
                    context: context,
                    companyId: companyId,
                    item: item,
                    data: data,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  "Add",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getCompanyId(),
      builder: (context, companySnapshot) {
        if (!companySnapshot.hasData) {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFF6A00),
              ),
            ),
          );
        }

        final companyId = companySnapshot.data ?? '';

        if (companyId == '') {
          return const Scaffold(
            backgroundColor: Colors.black,
            body: Center(
              child: Text(
                "Please join company first",
                style: TextStyle(color: Colors.white54),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.black,

          appBar: AppBar(
            backgroundColor: Colors.black,
            elevation: 0,
            foregroundColor: Colors.white,
            title: const Text(
              "Favorite Products",
              style: TextStyle(
                color: Color(0xFFFF6A00),
              ),
            ),
          ),

          body: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage('assets/images/Asset 160.png'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              Container(
                color: Colors.black.withOpacity(0.75),
              ),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(companyId)
                    .collection('products')
                    .where('isFavorite', isEqualTo: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFF6A00),
                      ),
                    );
                  }

                  final products = snapshot.data!.docs;

                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        "No favorite products",
                        style: TextStyle(color: Colors.white54),
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      return productCard(
                        context: context,
                        companyId: companyId,
                        item: products[index],
                      );
                    },
                  );
                },
              ),
            ],
          ),

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFFFF6A00),
            unselectedItemColor: Colors.white54,
            currentIndex: 1,
            showSelectedLabels: false,
            showUnselectedLabels: false,
            onTap: (index) {
              if (index == 0) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                );
              }

              if (index == 2) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BarcodeScreen(),
                  ),
                );
              }

              if (index == 3) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CartScreen(),
                  ),
                );
              }

              if (index == 4) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfileScreen(),
                  ),
                );
              }
            },
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home, size: 30),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite, size: 30),
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
      },
    );
  }
}