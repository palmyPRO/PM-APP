import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'user_history_screen.dart';
import 'barcode_screen.dart';
import 'cart_screen.dart';
import 'company_screen.dart';
import 'favorite_screen.dart';
import 'history_screen.dart';
import '../login/login_screen.dart';
import 'home_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> leaveCompany(
      BuildContext context,
      String uid,
      ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({
      'companyId': FieldValue.delete(),
      'companyName': FieldValue.delete(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Left company"),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    await FirebaseAuth.instance.signOut();

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => const LoginScreen(),
      ),
          (route) => false,
    );
  }

  void showCompanyDialog(
      BuildContext context,
      String uid,
      ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          "Company",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Choose action",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              Navigator.pop(context);

              await leaveCompany(context, uid);
            },
            child: const Text(
              "Leave",
              style: TextStyle(color: Colors.white),
            ),
          ),

          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor:
              const Color(0xFFFF6A00),
            ),
            onPressed: () {
              Navigator.pop(context);

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                  const CompanyScreen(),
                ),
              );
            },
            child: const Text(
              "Switch",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget profileButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFFF6A00),
          borderRadius: BorderRadius.circular(25),
        ),
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: Colors.white,
              size: 50,
            ),

            const SizedBox(height: 15),

            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        children: [
          Container(
            color: Colors.black,
          ),

          Container(
            color: Colors.black.withOpacity(0.75),
          ),

          SafeArea(
            child:
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore
                  .instance
                  .collection('users')
                  .doc(uid)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child:
                    CircularProgressIndicator(
                      color: Color(0xFFFF6A00),
                    ),
                  );
                }

                final data =
                    snapshot.data!.data()
                    as Map<String, dynamic>? ??
                        {};

                final userName =
                    data['name'] ?? 'User';

                final companyName =
                    data['companyName'] ??
                        'No Company';

                return Padding(
                  padding:
                  const EdgeInsets.all(25),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      Row(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration:
                            BoxDecoration(
                              shape:
                              BoxShape.circle,
                              border: Border.all(
                                color:
                                const Color(
                                    0xFFFF6A00),
                                width: 5,
                              ),
                            ),
                          ),

                          const SizedBox(width: 20),

                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                              children: [
                                Text(
                                  userName,
                                  style:
                                  const TextStyle(
                                    color:
                                    Colors.white,
                                    fontSize: 32,
                                    fontWeight:
                                    FontWeight
                                        .bold,
                                  ),
                                ),

                                const SizedBox(
                                    height: 5),

                                Text(
                                  "Company : $companyName",
                                  style:
                                  const TextStyle(
                                    color: Colors
                                        .white70,
                                    fontSize: 22,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 40),

                      Expanded(
                        child: GridView.count(
                          crossAxisCount: 2,
                          crossAxisSpacing: 20,
                          mainAxisSpacing: 20,
                          children: [
                            profileButton(
                              icon:
                              Icons.favorite,
                              label: "Favorite",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const FavoriteScreen(
                                      products: [],
                                    ),
                                  ),
                                );
                              },
                            ),

                            profileButton(
                              icon: Icons
                                  .receipt_long,
                              label: "History",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const HistoryScreen(),
                                  ),
                                );
                              },
                            ),

                            profileButton(
                              icon:
                              Icons.home_work,
                              label:
                              "Switch Company",
                              onTap: () {
                                showCompanyDialog(
                                  context,
                                  uid,
                                );
                              },
                            ),

                            profileButton(
                              icon: Icons
                                  .person_search,
                              label:
                              "User History",
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                    const UserHistoryScreen(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            logout(context);
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
                              BorderRadius
                                  .circular(
                                  20),
                            ),
                          ),
                          child: const Text(
                            "Logout",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight:
                              FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
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
        currentIndex: 4,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        onTap: (index) {
          if (index == 0) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const HomeScreen(),
              ),
                  (route) => false,
            );
          }

          if (index == 1) {
            Navigator.pushReplacement(
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
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const BarcodeScreen(),
              ),
            );
          }

          if (index == 3) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) =>
                const CartScreen(),
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