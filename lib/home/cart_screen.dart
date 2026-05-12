import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'barcode_screen.dart';
import 'favorite_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  Future<String> getCompanyId() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    return userDoc.data()?['companyId'] ?? '';
  }

  Future<void> checkout(
      BuildContext context,
      String companyId,
      ) async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) return;

    final uid = currentUser.uid;

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();

    final userData = userDoc.data();

    final userName = userData?['name'] ?? currentUser.email ?? '';
    final userEmail = userData?['email'] ?? currentUser.email ?? '';

    final companyDoc = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .get();

    final companyData = companyDoc.data();

    final companyName =
        companyData?['name'] ?? userData?['companyName'] ?? '';

    final cartSnapshot = await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('cart')
        .get();

    if (cartSnapshot.docs.isEmpty) return;

    final items = cartSnapshot.docs.map((doc) {
      final data = doc.data();

      return {
        'productId': data['productId'] ?? '',
        'name': data['name'] ?? '',
        'code': data['code'] ?? '',
        'type': data['type'] ?? '',
        'price': data['price'] ?? 0,
        'quantity': data['quantity'] ?? 1,
        'imageUrl': data['imageUrl'] ?? '',
      };
    }).toList();

    final historyData = {
      'items': items,
      'userId': uid,
      'userName': userName,
      'userEmail': userEmail,
      'companyId': companyId,
      'companyName': companyName,
      'checked_out_at': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('history')
        .add(historyData);

    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('history')
        .add(historyData);

    for (var doc in cartSnapshot.docs) {
      await doc.reference.delete();
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Checkout success")),
    );
  }

  Future<void> decreaseQuantity({
    required String companyId,
    required QueryDocumentSnapshot item,
    required Map<String, dynamic> data,
  }) async {
    final quantity = data['quantity'] ?? 1;
    final productId = data['productId'];

    if (quantity <= 1) return;

    final productRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .doc(productId);

    final productDoc = await productRef.get();

    final currentStock = productDoc.data()?['stock'] ?? 0;

    await item.reference.update({
      'quantity': quantity - 1,
    });

    await productRef.update({
      'stock': currentStock + 1,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> increaseQuantity({
    required String companyId,
    required QueryDocumentSnapshot item,
    required Map<String, dynamic> data,
  }) async {
    final quantity = data['quantity'] ?? 1;
    final productId = data['productId'];

    final productRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .doc(productId);

    final productDoc = await productRef.get();

    final currentStock = productDoc.data()?['stock'] ?? 0;

    if (currentStock <= 0) return;

    await item.reference.update({
      'quantity': quantity + 1,
    });

    await productRef.update({
      'stock': currentStock - 1,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> deleteItemAndReturnStock({
    required String companyId,
    required QueryDocumentSnapshot item,
    required Map<String, dynamic> data,
  }) async {
    final productId = data['productId'];
    final quantity = data['quantity'] ?? 1;

    final productRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .collection('products')
        .doc(productId);

    final productDoc = await productRef.get();

    final currentStock = productDoc.data()?['stock'] ?? 0;

    await productRef.update({
      'stock': currentStock + quantity,
      'updated_at': FieldValue.serverTimestamp(),
    });

    await item.reference.delete();
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
            title: const Text("Cart"),
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
          ),

          body: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .collection('cart')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFFFF6A00),
                  ),
                );
              }

              final cartItems = snapshot.data!.docs;

              if (cartItems.isEmpty) {
                return const Center(
                  child: Text(
                    "Cart is empty",
                    style: TextStyle(color: Colors.white54),
                  ),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartItems.length,
                      itemBuilder: (context, index) {
                        final item = cartItems[index];

                        final data =
                        item.data() as Map<String, dynamic>;

                        return Container(
                          margin: const EdgeInsets.all(12),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                data['name'] ?? '',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),

                              Text(
                                "Code : ${data['code'] ?? ''}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),

                              Text(
                                "Type : ${data['type'] ?? ''}",
                                style: const TextStyle(
                                  color: Colors.white70,
                                ),
                              ),

                              Text(
                                "Price : ${data['price'] ?? 0}",
                                style: const TextStyle(
                                  color: Colors.orange,
                                ),
                              ),

                              const SizedBox(height: 10),

                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      IconButton(
                                        onPressed: () async {
                                          await decreaseQuantity(
                                            companyId: companyId,
                                            item: item,
                                            data: data,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.remove,
                                          color: Colors.white,
                                        ),
                                      ),

                                      Text(
                                        "${data['quantity'] ?? 1}",
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                        ),
                                      ),

                                      IconButton(
                                        onPressed: () async {
                                          await increaseQuantity(
                                            companyId: companyId,
                                            item: item,
                                            data: data,
                                          );
                                        },
                                        icon: const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),

                                  IconButton(
                                    onPressed: () async {
                                      await deleteItemAndReturnStock(
                                        companyId: companyId,
                                        item: item,
                                        data: data,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: SizedBox(
                      width: double.infinity,
                      height: 55,
                      child: ElevatedButton(
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              backgroundColor: Colors.grey[900],
                              title: const Text(
                                "Confirm Checkout?",
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                "Are you sure you want to checkout?",
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                  },
                                  child: const Text(
                                    "Cancel",
                                    style: TextStyle(
                                      color: Colors.white54,
                                    ),
                                  ),
                                ),

                                ElevatedButton(
                                  onPressed: () {
                                    checkout(context, companyId);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                    const Color(0xFFFF6A00),
                                  ),
                                  child: const Text(
                                    "Confirm",
                                    style: TextStyle(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFFFF6A00),
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),

          bottomNavigationBar: BottomNavigationBar(
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.black,
            selectedItemColor: const Color(0xFFFF6A00),
            unselectedItemColor: Colors.white54,
            currentIndex: 3,
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

              if (index == 1) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                    const FavoriteScreen(products: []),
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
                icon: Icon(Icons.home),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.favorite_border),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.camera_alt),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag_outlined),
                label: "",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_circle_outlined),
                label: "",
              ),
            ],
          ),
        );
      },
    );
  }
}