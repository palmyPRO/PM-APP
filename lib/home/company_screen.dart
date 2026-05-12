import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyScreen extends StatefulWidget {
  const CompanyScreen({super.key});

  @override
  State<CompanyScreen> createState() => _CompanyScreenState();
}

class _CompanyScreenState extends State<CompanyScreen> {

  final companyNameController =
  TextEditingController();

  final companySecretCodeController =
  TextEditingController();

  final confirmSecretCodeController =
  TextEditingController();

  final joinCompanyNameController =
  TextEditingController();

  final joinSecretCodeController =
  TextEditingController();

  bool isLoading = false;

  /// CREATE COMPANY
  Future<void> createCompany() async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final companyName =
    companyNameController.text.trim();

    final secretCode =
    companySecretCodeController.text.trim();

    final confirmCode =
    confirmSecretCodeController.text.trim();

    if (companyName.isEmpty ||
        secretCode.isEmpty ||
        confirmCode.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Please fill all fields",
          ),
        ),
      );

      return;
    }

    if (secretCode.length < 6) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Secret code must be at least 6 characters",
          ),
        ),
      );

      return;
    }

    if (secretCode != confirmCode) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Secret code does not match",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final checkCompany =
      await FirebaseFirestore.instance
          .collection('companies')
          .where(
        'name',
        isEqualTo: companyName,
      )
          .get();

      if (checkCompany.docs.isNotEmpty) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(
            content: Text(
              "Company already exists",
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      final companyRef =
      await FirebaseFirestore.instance
          .collection('companies')
          .add({

        'name': companyName,

        'secretCode': secretCode,

        'ownerId': uid,

        'createdAt':
        FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({

        'companyId': companyRef.id,

        'companyName': companyName,

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Create company success",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            "Error : $e",
          ),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// JOIN COMPANY
  Future<void> joinCompany() async {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;

    final companyName =
    joinCompanyNameController.text.trim();

    final secretCode =
    joinSecretCodeController.text.trim();

    if (companyName.isEmpty ||
        secretCode.isEmpty) {

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Please enter company name and code",
          ),
        ),
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {

      final snapshot =
      await FirebaseFirestore.instance
          .collection('companies')
          .get();

      QueryDocumentSnapshot? matchedCompany;

      for (var doc in snapshot.docs) {

        final data =
        doc.data() as Map<String, dynamic>;

        final dbName =
        (data['name'] ?? '')
            .toString()
            .trim();

        final dbCode =
        (data['secretCode'] ?? '')
            .toString()
            .trim();

        if (dbName.toLowerCase() ==
            companyName.toLowerCase() &&
            dbCode == secretCode) {

          matchedCompany = doc;
          break;
        }
      }

      if (matchedCompany == null) {

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(
            content: Text(
              "Wrong company name or secret code",
            ),
          ),
        );

        setState(() {
          isLoading = false;
        });

        return;
      }

      final companyData =
      matchedCompany.data()
      as Map<String, dynamic>;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({

        'companyId': matchedCompany.id,

        'companyName':
        companyData['name'],

      });

      ScaffoldMessenger.of(context).showSnackBar(

        const SnackBar(
          content: Text(
            "Join company success",
          ),
        ),
      );

      Navigator.pop(context);

    } catch (e) {

      ScaffoldMessenger.of(context).showSnackBar(

        SnackBar(
          content: Text(
            "Error : $e",
          ),
        ),
      );

    } finally {

      setState(() {
        isLoading = false;
      });
    }
  }

  /// INPUT
  Widget inputBox(
      String hint,
      TextEditingController controller, {

        bool isPassword = false,
      }) {

    return TextField(

      controller: controller,

      obscureText: isPassword,

      style: const TextStyle(
        color: Colors.white,
      ),

      decoration: InputDecoration(

        hintText: hint,

        hintStyle: const TextStyle(
          color: Colors.white54,
        ),

        filled: true,

        fillColor: Colors.grey[900],

        contentPadding:
        const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 18,
        ),

        border: OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: Colors.white24,
          ),
        ),

        enabledBorder: OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: Colors.white24,
          ),
        ),

        focusedBorder: OutlineInputBorder(

          borderRadius:
          BorderRadius.circular(15),

          borderSide:
          const BorderSide(
            color: Color(0xFFFF6A00),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {

    companyNameController.dispose();

    companySecretCodeController.dispose();

    confirmSecretCodeController.dispose();

    joinCompanyNameController.dispose();

    joinSecretCodeController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(

      backgroundColor: Colors.black,

      appBar: AppBar(

        title: const Text("Company"),

        backgroundColor: Colors.black,

        foregroundColor: Colors.white,
      ),

      body: SingleChildScrollView(

        padding: const EdgeInsets.all(25),

        child: Column(

          children: [

            const SizedBox(height: 20),

            /// CREATE COMPANY
            const Text(

              "Create Company",

              style: TextStyle(

                color: Color(0xFFFF6A00),

                fontSize: 24,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            inputBox(
              "Company Name",
              companyNameController,
            ),

            const SizedBox(height: 15),

            inputBox(
              "Secret Code",
              companySecretCodeController,
              isPassword: true,
            ),

            const SizedBox(height: 15),

            inputBox(
              "Confirm Secret Code",
              confirmSecretCodeController,
              isPassword: true,
            ),

            const SizedBox(height: 20),

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton(

                onPressed:
                isLoading
                    ? null
                    : createCompany,

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(0xFFFF6A00),

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(25),
                  ),
                ),

                child: const Text(

                  "Create Company",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 50),

            /// JOIN COMPANY
            const Text(

              "Join Company",

              style: TextStyle(

                color: Color(0xFFFF6A00),

                fontSize: 24,

                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 20),

            inputBox(
              "Enter Company Name",
              joinCompanyNameController,
            ),

            const SizedBox(height: 15),

            inputBox(
              "Enter Secret Code",
              joinSecretCodeController,
              isPassword: true,
            ),

            const SizedBox(height: 20),

            SizedBox(

              width: double.infinity,

              height: 55,

              child: ElevatedButton(

                onPressed:
                isLoading
                    ? null
                    : joinCompany,

                style:
                ElevatedButton.styleFrom(

                  backgroundColor:
                  const Color(0xFFFF6A00),

                  shape:
                  RoundedRectangleBorder(

                    borderRadius:
                    BorderRadius.circular(25),
                  ),
                ),

                child: const Text(

                  "Join Company",

                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
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