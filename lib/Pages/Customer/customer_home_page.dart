import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Pages/Customer/adding_new_customer.dart';
import 'package:abtraders/Pages/Customer/customer_payment.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerHomePage extends StatefulWidget {
  const CustomerHomePage({super.key});

  @override
  State<CustomerHomePage> createState() => _CustomerHomePageState();
}

class _CustomerHomePageState extends State<CustomerHomePage> {
  // Firestore instance
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customers"),
        backgroundColor: Colors.teal,
      ),
      body: SafeArea(
        child: Stack(
          alignment: AlignmentDirectional.topEnd,
          children: [
            const ShapedS(),
            Padding(
              padding: const EdgeInsets.all(20),
              child: MyButton(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const AddingNewCustomer();
                  }));
                },
                icon: Icons.add,
                width: MediaQuery.of(context).size.width * 0.15,
                height: MediaQuery.of(context).size.height * 0.08,
                color: Colors.blueGrey.shade200,
                radius: 360,
              ),
            ),
            Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height * 0.2),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  width: MediaQuery.of(context).size.width * 0.95,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: Colors.grey.shade100,
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('customers')
                        .where('userId',
                            isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(child: Text('Error: ${snapshot.error}'));
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No customers found'));
                      }

                      final customers = snapshot.data!.docs;

                      return RefreshIndicator(
                        onRefresh: () async {
                          setState(
                              () {}); // Not really necessary with StreamBuilder
                          await Future.delayed(const Duration(seconds: 1));
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 30),
                          itemCount: customers.length,
                          itemBuilder: (context, index) {
                            var customer = customers[index];
                            return Column(
                              children: [
                                MyButton(
                                  onTap: () {
                                    Navigator.push(context,
                                        MaterialPageRoute(builder: (context) {
                                      return CustomerPayment(
                                        customerId: customer.id,
                                        customerName: customer['name'],
                                        currentBalance: customer['balance'],
                                        onTransactionComplete: () {
                                          // This will trigger a rebuild of MyContainer
                                          setState(() {});
                                        },
                                      );
                                    }));
                                  },
                                  text: customer['name'],
                                  color: Colors.blueGrey.shade300,
                                  width:
                                      MediaQuery.of(context).size.width * 0.9,
                                ),
                                const SizedBox(height: 10),
                              ],
                            );
                          },
                        ),
                      );
                    },
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
