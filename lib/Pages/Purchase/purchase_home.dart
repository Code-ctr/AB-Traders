import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PurchaseHome extends StatefulWidget {
  const PurchaseHome({super.key});

  @override
  State<PurchaseHome> createState() => _PurchaseHomeState();
}

class _PurchaseHomeState extends State<PurchaseHome> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCompany;
  String? _selectedItem;
  List<String> _companies = [];
  List<String> _items = [];
  final List<Map<String, dynamic>> _purchasedItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCompanies();
    _fetchItems();
  }

  // Fetch companies from Firestore
  Future<void> _fetchCompanies() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('companies')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<String> companies = [];
      for (var doc in querySnapshot.docs) {
        companies.add(doc['name']);
      }
      setState(() {
        _companies = companies;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching companies: $e');
    }
  }

  // Fetch items from Firestore
  Future<void> _fetchItems() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('items')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<String> items = [];
      for (var doc in querySnapshot.docs) {
        items.add(doc['name']);
      }
      setState(() {
        _items = items;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching items: $e');
    }
  }

  // Add item to the purchase list
  void _addItem() {
    if (_selectedCompany == null ||
        _selectedItem == null ||
        _quantityController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double quantity = double.tryParse(_quantityController.text) ?? 0.0;
    double price = double.tryParse(_priceController.text) ?? 0.0;

    if (quantity <= 0 || price <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid quantity and price')),
      );
      return;
    }

    setState(() {
      _purchasedItems.add({
        'item': _selectedItem!,
        'quantity': quantity,
        'price': price,
      });
    });

    // Clear the form
    _quantityController.clear();
    _priceController.clear();
  }

  // Remove item from the purchase list
  void _removeItem(int index) {
    setState(() {
      _purchasedItems.removeAt(index);
    });
  }

  // Complete the purchase
  Future<void> _checkOut() async {
    if (_purchasedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to purchase')),
      );
      return;
    }

    try {
      // Fetch the selected company's document
      QuerySnapshot companyQuery = await _firestore
          .collection('companies')
          .where('name', isEqualTo: _selectedCompany)
          .get();

      if (companyQuery.docs.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company not found')),
        );
        return;
      }

      final companyDoc = companyQuery.docs.first;
      final companyId = companyDoc.id;
      double companyBalance = companyDoc['balance'];

      // Calculate total purchase amount
      double totalAmount = 0.0;
      for (var item in _purchasedItems) {
        totalAmount += item['quantity'] * item['price'];
      }

      // Update company balance (debit the company)
      double newCompanyBalance = companyBalance - totalAmount;
      await _firestore.collection('companies').doc(companyId).update({
        'balance': newCompanyBalance,
      });

      // Update item quantities and store purchase details
      for (var item in _purchasedItems) {
        // Fetch the item's document
        QuerySnapshot itemQuery = await _firestore
            .collection('items')
            .where('name', isEqualTo: item['item'])
            .get();

        if (itemQuery.docs.isNotEmpty) {
          final itemDoc = itemQuery.docs.first;
          final itemId = itemDoc.id;
          double currentQuantity = itemDoc['quantity'] ?? 0.0;

          // Update item quantity
          await _firestore.collection('items').doc(itemId).update({
            'quantity': currentQuantity + item['quantity'],
            'purchasePrice': item['price'],
          });
          User? user = FirebaseAuth.instance.currentUser;
          if (user == null) {
            throw Exception("User not logged in");
          }
          // Store purchase transaction
          await _firestore.collection('purchases').add({
            'companyId': companyId,
            'companyName': _selectedCompany,
            'item': item['item'],
            'quantity': item['quantity'],
            'price': item['price'],
            'totalAmount': item['quantity'] * item['price'],
            'date': DateTime.now(),
            'userId': user.uid,
          });
        }
      }
      // Clear the purchase list
      setState(() {
        _purchasedItems.clear();
      });

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase completed successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing purchase: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Purchase Panel"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.03,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        alignment: AlignmentDirectional.centerStart,
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        value: _selectedCompany,
                        hint: const Text('Select Company'),
                        items: _companies.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCompany = newValue;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black)),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        alignment: AlignmentDirectional.centerStart,
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        value: _selectedItem,
                        hint: const Text('Select Items'),
                        items: _items.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedItem = newValue;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 13.0),
                    child: Row(
                      children: [
                        MyTextField(
                          controller: _quantityController,
                          hinttext: "Item Quantity",
                          width: MediaQuery.of(context).size.width * 0.4,
                          isNumeric: true,
                        ),
                        MyTextField(
                          controller: _priceController,
                          hinttext: "Item Price",
                          width: MediaQuery.of(context).size.width * 0.4,
                          isNumeric: true,
                        ),
                        MyButton(
                          onTap: _addItem,
                          icon: Icons.add,
                          color: Colors.blueGrey.shade300,
                          width: MediaQuery.of(context).size.width * 0.13,
                          height: MediaQuery.of(context).size.height * 0.065,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.47,
                    width: MediaQuery.of(context).size.width * 0.92,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white,
                        border: Border.all(color: Colors.black)),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.02,
                          ),
                          for (int i = 0; i < _purchasedItems.length; i++)
                            AddingItems(
                              itemName: _purchasedItems[i]['item'],
                              quantity: _purchasedItems[i]['quantity'],
                              price: _purchasedItems[i]['price'],
                              onDelete: () =>
                                  _removeItem(i), // Pass the delete callback
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  MyButton(
                    onTap: _checkOut,
                    text: "Check Out",
                    color: Colors.teal.shade600,
                    width: MediaQuery.of(context).size.width * 0.6,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AddingItems extends StatelessWidget {
  final String itemName;
  final double quantity;
  final double price;
  final VoidCallback onDelete; // Callback function to delete the item

  const AddingItems({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.onDelete, // Add the callback function
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.08,
      width: MediaQuery.of(context).size.width * 0.85,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.blueGrey.shade400),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          children: [
            Text(itemName),
            const Spacer(),
            Text(quantity.toString()),
            const Spacer(),
            Text(price.toString()),
            const Spacer(),
            MyButton(
              onTap: onDelete, // Call the callback function
              icon: Icons.delete,
              width: MediaQuery.of(context).size.height * 0.1,
              iconColor: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}
