import 'package:abtraders/Components/shadow_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RemainingItem extends StatelessWidget {
  const RemainingItem({super.key});

  // Fetch items from Firestore
  Future<List<Map<String, dynamic>>> _fetchItems() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      return [];
    }
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<Map<String, dynamic>> items = [];
      for (var doc in querySnapshot.docs) {
        items.add({
          'name': doc['name'],
          'quantity': doc['quantity'],
        });
      }
      return items;
    } catch (e) {
      print('Error fetching items: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Remaining Items",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 25,
                  offset: Offset(10, 10),
                  color: Colors.black,
                ),
              ],
            ),
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchItems(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No items found'),
                  );
                } else {
                  List<Map<String, dynamic>> items = snapshot.data!;
                  return SingleChildScrollView(
                    child: Column(
                      children: items.map((item) {
                        return Padding(
                          padding: EdgeInsets.symmetric(
                            vertical:
                                MediaQuery.of(context).size.height * 0.015,
                          ),
                          child: ShadowContainers(
                            itemName: item['name'],
                            quantity: item['quantity'],
                          ),
                        );
                      }).toList(),
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
