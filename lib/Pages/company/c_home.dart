import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Pages/company/com_inv_add.dart';
import 'package:abtraders/Pages/company/com_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CHome extends StatefulWidget {
  const CHome({super.key});

  @override
  State<CHome> createState() => _CHomeState();
}

class _CHomeState extends State<CHome> {
  Stream<QuerySnapshot> fetchCompanies() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('companies')
        .where('userId', isEqualTo: user.uid) // Filter by userId
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Company Panel"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: Column(
              children: [
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: MyButton(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const ComInvAdd();
                      }));
                    },
                    icon: Icons.add,
                    width: MediaQuery.of(context).size.width * 0.15,
                    color: Colors.blueGrey.shade300,
                    radius: 360,
                  ),
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                Container(
                  height: MediaQuery.of(context).size.height * 0.65,
                  width: MediaQuery.of(context).size.width * 0.95,
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.grey.shade100),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: fetchCompanies(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No data found'));
                      }

                      // Get the list of companies and investors
                      final companies = snapshot.data!.docs;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            const SizedBox(height: 30),
                            for (var company in companies) ...[
                              MyButton(
                                onTap: () {
                                  Navigator.push(context,
                                      MaterialPageRoute(builder: (context) {
                                    return ComPayment(
                                      companyId: company.id, // Pass companyId
                                      companyName: company['name'], // Pass name
                                      currentBalance:
                                          company['balance'], // Pass balance
                                      onTransactionComplete: () {
                                        // This will trigger a rebuild of MyContainer
                                        setState(() {});
                                      },
                                    );
                                  }));
                                },
                                text: company['name'], // Display company name
                                color: Colors.blueGrey.shade300,
                                width: MediaQuery.of(context).size.width * 0.9,
                              ),
                              const SizedBox(height: 10),
                            ],
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
