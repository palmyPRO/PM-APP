import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserHistoryScreen extends StatelessWidget {
  const UserHistoryScreen({super.key});

  String formatDate(dynamic timestamp) {
    if (timestamp == null) return "-";

    final date = (timestamp as Timestamp).toDate();

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return "$day/$month/$year $hour:$minute";
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("User History"),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('history')
            .orderBy('checked_out_at', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
            );
          }

          final histories = snapshot.data!.docs;

          if (histories.isEmpty) {
            return const Center(
              child: Text(
                "No user history",
                style: TextStyle(color: Colors.white54),
              ),
            );
          }

          return ListView.builder(
            itemCount: histories.length,
            itemBuilder: (context, index) {
              final data = histories[index].data() as Map<String, dynamic>;

              final items = data['items'] as List? ?? [];

              return Container(
                margin: const EdgeInsets.all(12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "User : ${data['userName'] ?? ''}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                      ),
                    ),
                    Text(
                      "Email : ${data['userEmail'] ?? ''}",
                      style: const TextStyle(color: Colors.white70),
                    ),
                    Text(
                      "Company : ${data['companyName'] ?? ''}",
                      style: const TextStyle(color: Colors.orange),
                    ),
                    Text(
                      "Time : ${formatDate(data['checked_out_at'])}",
                      style: const TextStyle(color: Colors.white70),
                    ),

                    const Divider(color: Colors.white24),

                    ...items.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Text(
                          "${item['name']} | Code: ${item['code']} | Qty: ${item['quantity']}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}