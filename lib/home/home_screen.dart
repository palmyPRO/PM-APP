import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'barcode_screen.dart';
import 'cart_screen.dart';
import 'favorite_screen.dart';
import 'manage_product_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = "";

  Future<void> addToCart({
    required String companyId,
    required QueryDocumentSnapshot item,
    required Map<String, dynamic> data,
    required int quantity,
  }) async {
    final stock = data['stock'] ?? 0;

    if (stock < quantity) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Stock not enough"),
        ),
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
      const SnackBar(
        content: Text("Added to cart"),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(
                  'assets/images/Asset 160.png',
                ),
                fit: BoxFit.cover,
              ),
            ),
          ),

          Container(
            color: Colors.black.withOpacity(0.75),
          ),

          SafeArea(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, userSnapshot) {
                if (!userSnapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFFFF6A00),
                    ),
                  );
                }

                final userData =
                userSnapshot.data!.data()
                as Map<String, dynamic>?;

                final companyId =
                    userData?['companyId'] ?? '';

                if (companyId == '') {
                  return const Center(
                    child: Text(
                      "Please join company first",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                  );
                }

                return Column(
                  children: [
                    const SizedBox(height: 15),

                    const Text(
                      "PMFX PYROTECHNICS",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 20),

                    Padding(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 15,
                      ),
                      child: TextField(
                        onChanged: (value) {
                          setState(() {
                            searchText = value;
                          });
                        },
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Search",
                          hintStyle:
                          const TextStyle(
                            color: Colors.white54,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.white54,
                          ),
                          filled: true,
                          fillColor: Colors.grey[900],
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                                25),
                            borderSide:
                            BorderSide.none,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),

                    Expanded(
                      child:
                      StreamBuilder<QuerySnapshot>(
                        stream:
                        FirebaseFirestore
                            .instance
                            .collection(
                            'companies')
                            .doc(companyId)
                            .collection(
                            'products')
                            .snapshots(),
                        builder:
                            (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child:
                              CircularProgressIndicator(
                                color: Color(
                                    0xFFFF6A00),
                              ),
                            );
                          }

                          final input =
                          searchText
                              .trim()
                              .toLowerCase();

                          final products =
                          snapshot.data!.docs
                              .where((doc) {
                            final data =
                            doc.data()
                            as Map<String,
                                dynamic>;

                            final name =
                            (data['name'] ??
                                '')
                                .toString()
                                .toLowerCase();

                            final code =
                            (data['code'] ??
                                '')
                                .toString()
                                .toLowerCase();

                            final type =
                            (data['type'] ??
                                '')
                                .toString()
                                .toLowerCase();

                            final price =
                            (data['price'] ??
                                '')
                                .toString()
                                .toLowerCase();

                            final stock =
                            (data['stock'] ??
                                '')
                                .toString()
                                .toLowerCase();

                            if (input.isEmpty) {
                              return true;
                            }

                            return name
                                .contains(
                                input) ||
                                code.contains(
                                    input) ||
                                type.contains(
                                    input) ||
                                price.contains(
                                    input) ||
                                stock.contains(
                                    input);
                          }).toList();

                          if (products.isEmpty) {
                            return const Center(
                              child: Text(
                                "No products",
                                style: TextStyle(
                                  color:
                                  Colors.white54,
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount:
                            products.length,
                            itemBuilder:
                                (context, index) {
                              final item =
                              products[index];

                              final data =
                              item.data()
                              as Map<String,
                                  dynamic>;

                              return Container(
                                margin:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal: 15,
                                  vertical: 8,
                                ),
                                padding:
                                const EdgeInsets
                                    .all(15),
                                decoration:
                                BoxDecoration(
                                  color:
                                  Colors.black,
                                  borderRadius:
                                  BorderRadius
                                      .circular(
                                      20),
                                  border: Border.all(
                                    color: Colors
                                        .white24,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment
                                      .start,
                                  children: [
                                    if (data[
                                    'imageUrl'] !=
                                        null &&
                                        data['imageUrl'] !=
                                            "")
                                      ClipRRect(
                                        borderRadius:
                                        BorderRadius
                                            .circular(
                                            15),
                                        child:
                                        Image.network(
                                          data[
                                          'imageUrl'],
                                          height: 180,
                                          width: double
                                              .infinity,
                                          fit: BoxFit
                                              .cover,
                                        ),
                                      ),

                                    const SizedBox(
                                        height: 15),

                                    Text(
                                      "Name : ${data['name']}",
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .white,
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    Text(
                                      "Code : ${data['code']}",
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .white70,
                                      ),
                                    ),

                                    Text(
                                      "Type : ${data['type']}",
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .white70,
                                      ),
                                    ),

                                    Text(
                                      "Price : ${data['price']}",
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .orange,
                                        fontSize: 18,
                                        fontWeight:
                                        FontWeight
                                            .bold,
                                      ),
                                    ),

                                    Text(
                                      "Stock : ${data['stock']}",
                                      style:
                                      const TextStyle(
                                        color: Colors
                                            .white70,
                                      ),
                                    ),

                                    const SizedBox(
                                        height: 15),

                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment
                                          .spaceBetween,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            data['isFavorite'] ==
                                                true
                                                ? Icons
                                                .favorite
                                                : Icons
                                                .favorite_border,
                                            color: data[
                                            'isFavorite'] ==
                                                true
                                                ? const Color(
                                                0xFFFF6A00)
                                                : Colors
                                                .white54,
                                          ),
                                          onPressed:
                                              () async {
                                            await FirebaseFirestore
                                                .instance
                                                .collection(
                                                'companies')
                                                .doc(
                                                companyId)
                                                .collection(
                                                'products')
                                                .doc(
                                                item.id)
                                                .update({
                                              'isFavorite':
                                              !(data['isFavorite'] ==
                                                  true),
                                            });
                                          },
                                        ),

                                        ElevatedButton(
                                          onPressed:
                                              () {
                                            int quantity =
                                            1;

                                            showDialog(
                                              context:
                                              context,
                                              builder:
                                                  (
                                                  context,
                                                  ) {
                                                return StatefulBuilder(
                                                  builder:
                                                      (
                                                      context,
                                                      setStateDialog,
                                                      ) {
                                                    return AlertDialog(
                                                      backgroundColor:
                                                      Colors.grey[
                                                      900],
                                                      title:
                                                      const Text(
                                                        "Select Quantity",
                                                        style:
                                                        TextStyle(
                                                          color:
                                                          Colors.white,
                                                        ),
                                                      ),
                                                      content:
                                                      Row(
                                                        mainAxisAlignment:
                                                        MainAxisAlignment.center,
                                                        children: [
                                                          IconButton(
                                                            onPressed:
                                                                () {
                                                              if (quantity >
                                                                  1) {
                                                                setStateDialog(
                                                                        () {
                                                                      quantity--;
                                                                    });
                                                              }
                                                            },
                                                            icon:
                                                            const Icon(
                                                              Icons.remove,
                                                              color:
                                                              Colors.white,
                                                            ),
                                                          ),
                                                          Text(
                                                            quantity
                                                                .toString(),
                                                            style:
                                                            const TextStyle(
                                                              color:
                                                              Colors.white,
                                                              fontSize:
                                                              22,
                                                            ),
                                                          ),
                                                          IconButton(
                                                            onPressed:
                                                                () {
                                                              setStateDialog(
                                                                      () {
                                                                    quantity++;
                                                                  });
                                                            },
                                                            icon:
                                                            const Icon(
                                                              Icons.add,
                                                              color:
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed:
                                                              () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child:
                                                          const Text(
                                                            "Cancel",
                                                            style:
                                                            TextStyle(
                                                              color:
                                                              Colors.white54,
                                                            ),
                                                          ),
                                                        ),
                                                        ElevatedButton(
                                                          style:
                                                          ElevatedButton.styleFrom(
                                                            backgroundColor:
                                                            const Color(
                                                                0xFFFF6A00),
                                                          ),
                                                          onPressed:
                                                              () async {
                                                            await addToCart(
                                                              companyId:
                                                              companyId,
                                                              item:
                                                              item,
                                                              data:
                                                              data,
                                                              quantity:
                                                              quantity,
                                                            );

                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child:
                                                          const Text(
                                                            "Add",
                                                            style:
                                                            TextStyle(
                                                              color:
                                                              Colors.white,
                                                            ),
                                                          ),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              },
                                            );
                                          },
                                          style:
                                          ElevatedButton
                                              .styleFrom(
                                            backgroundColor:
                                            const Color(
                                                0xFFFF6A00),
                                            shape:
                                            RoundedRectangleBorder(
                                              borderRadius:
                                              BorderRadius.circular(
                                                  15),
                                            ),
                                          ),
                                          child:
                                          const Text(
                                            "Add",
                                            style:
                                            TextStyle(
                                              color: Colors
                                                  .white,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),

      floatingActionButton:
      FloatingActionButton(
        backgroundColor:
        const Color(0xFFFF6A00),
        child: const Icon(Icons.add),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
              const ManageProductScreen(),
            ),
          );
        },
      ),

      bottomNavigationBar:
      BottomNavigationBar(
        type:
        BottomNavigationBarType.fixed,
        backgroundColor: Colors.black,
        selectedItemColor:
        const Color(0xFFFF6A00),
        unselectedItemColor:
        Colors.white54,
        currentIndex: 0,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 1) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const FavoriteScreen(
                  products: [],
                ),
              ),
            );
          }

          if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const BarcodeScreen(),
              ),
            );
          }

          if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const CartScreen(),
              ),
            );
          }

          if (index == 4) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const ProfileScreen(),
              ),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home,
                size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.favorite_border,
                size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt,
                size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(
                Icons.shopping_bag_outlined,
                size: 30),
            label: "",
          ),
          BottomNavigationBarItem(
            icon: Icon(
              Icons.account_circle_outlined,
              size: 30,
            ),
            label: "",
          ),
        ],
      ),
    );
  }
}