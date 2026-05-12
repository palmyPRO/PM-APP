import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'company_screen.dart';

class ManageProductScreen extends StatefulWidget {
  const ManageProductScreen({super.key});

  @override
  State<ManageProductScreen> createState() => _ManageProductScreenState();
}

class _ManageProductScreenState extends State<ManageProductScreen> {
  final nameController = TextEditingController();
  final codeController = TextEditingController();
  final typeController = TextEditingController();
  final priceController = TextEditingController();
  final stockController = TextEditingController();
  final imageUrlController = TextEditingController();

  bool isLoading = false;

  Future<Map<String, dynamic>?> getCurrentUserCompany() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return null;
    }

    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    final userData = userDoc.data();

    if (userData == null) {
      return null;
    }

    final companyId = userData['companyId'];
    final companyName = userData['companyName'];

    if (companyId == null || companyId.toString().isEmpty) {
      return null;
    }

    return {
      'companyId': companyId,
      'companyName': companyName ?? '',
    };
  }

  Future<void> addProductToFirebase() async {
    if (nameController.text.trim().isEmpty ||
        codeController.text.trim().isEmpty ||
        typeController.text.trim().isEmpty ||
        priceController.text.trim().isEmpty ||
        stockController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all fields")),
      );
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final company = await getCurrentUserCompany();

      if (company == null) {
        setState(() {
          isLoading = false;
        });

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              "No Company",
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              "You need to join or create a company before adding products.",
              style: TextStyle(color: Colors.white70),
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
                onPressed: () {
                  Navigator.pop(context);

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const CompanyScreen(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                ),
                child: const Text(
                  "Go to Company",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        );

        return;
      }

      final companyId = company['companyId'];

      await FirebaseFirestore.instance
          .collection('companies')
          .doc(companyId)
          .collection('products')
          .add({
        'name': nameController.text.trim(),
        'code': codeController.text.trim(),
        'type': typeController.text.trim(),
        'price': double.tryParse(priceController.text.trim()) ?? 0,
        'stock': int.tryParse(stockController.text.trim()) ?? 0,
        'imageUrl': imageUrlController.text.trim(),
        'isFavorite': false,
        'created_at': FieldValue.serverTimestamp(),
        'updated_at': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add Product Success")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error : $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget buildInput(
      String hint,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.white54),
        filled: true,
        fillColor: Colors.grey[900],
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Color(0xFFFF6A00)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    nameController.dispose();
    codeController.dispose();
    typeController.dispose();
    priceController.dispose();
    stockController.dispose();
    imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Add Product"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            buildInput("Product Name", nameController),
            const SizedBox(height: 15),

            buildInput("Product Code", codeController),
            const SizedBox(height: 15),

            buildInput("Product Type", typeController),
            const SizedBox(height: 15),

            buildInput(
              "Price",
              priceController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            buildInput(
              "Stock",
              stockController,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 15),

            buildInput("Image URL (optional)", imageUrlController),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: isLoading ? null : addProductToFirebase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6A00),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                  "Add Product",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}