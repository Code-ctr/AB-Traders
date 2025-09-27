import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ProductHomepage extends StatefulWidget {
  const ProductHomepage({super.key});

  @override
  State<ProductHomepage> createState() => _ProductHomepageState();
}

class _ProductHomepageState extends State<ProductHomepage> {
  final TextEditingController _itemName = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add a new item to Firestore
  Future<void> _addNewItem() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    if (_itemName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    try {
      // Add the new item to Firestore
      await _firestore.collection('items').add({
        'name': _itemName.text,
        "quantity": 0.0,
        "purchasePrice": 0.0,
        'createdAt': DateTime.now(), // Optional: Store the creation timestamp
        'userId': user.uid,
      });

      // Clear the text field
      _itemName.clear();

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item added successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding item: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Product Panel"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                MyTextField(
                  controller: _itemName,
                  hinttext: "Item Name",
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                MyButton(
                  height: MediaQuery.of(context).size.height * 0.07,
                  width: MediaQuery.of(context).size.width * 0.5,
                  onTap:
                      _addNewItem, // Call _addNewItem when the button is pressed
                  text: "Add New Item",
                  color: Colors.blueGrey.shade300,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.01,
                ),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    height: MediaQuery.of(context).size.height * 0.6,
                    width: MediaQuery.of(context).size.width * 0.94,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: const ItemsShowCase(), // Display the list of items
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

class ItemsShowCase extends StatelessWidget {
  const ItemsShowCase({super.key});

  // Function to delete an item from Firestore
  Future<void> _deleteItem(String itemId) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    try {
      await firestore.collection('items').doc(itemId).delete();
    } catch (e) {
      // ignore: avoid_print
      print('Error deleting item: $e');
    }
  }

  Stream<QuerySnapshot> fetchItems() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    return FirebaseFirestore.instance
        .collection('items')
        .where('userId', isEqualTo: user.uid) // Filter by userId
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: fetchItems(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No items found'));
        }

        // Get the list of items
        final items = snapshot.data!.docs;

        return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              margin: const EdgeInsetsDirectional.all(5),
              height: MediaQuery.of(context).size.height * 0.08,
              width: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.blueGrey.shade400,
              ),
              child: Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 15.0),
                    child: Text(item['name']),
                  ),
                  const Spacer(),
                  MyButton(
                    width: MediaQuery.of(context).size.width * 0.12,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Delete Item'),
                          content: const Text(
                              'Are you sure you want to delete this item?'),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () {
                                _deleteItem(item.id);
                                Navigator.pop(context);
                              },
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    }, // Delete the item
                    icon: Icons.delete,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
