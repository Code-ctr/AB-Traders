import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SalePanel extends StatefulWidget {
  const SalePanel({super.key});

  @override
  State<SalePanel> createState() => _SalePanelState();
}

class _SalePanelState extends State<SalePanel> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  String? _selectedCustomer;
  String? _selectedItem;
  List<String> _customers = [];
  List<String> _items = [];
  final List<Map<String, dynamic>> _soldItems = [];

  @override
  void initState() {
    super.initState();
    _fetchCustomers();
    _fetchItems();
  }

  // Fetch customers from Firestore
  Future<void> _fetchCustomers() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('customers')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<String> customers = [];
      for (var doc in querySnapshot.docs) {
        customers.add(doc['name']);
      }
      setState(() {
        _customers = customers;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching customers: $e');
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

  // Add item to the sale list
  void _addItem() {
    if (_selectedCustomer == null ||
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
      _soldItems.add({
        'item': _selectedItem!,
        'quantity': quantity,
        'price': price,
      });
    });

    // Clear the form
    _quantityController.clear();
    _priceController.clear();
  }

  // Remove item from the sale list
  void _removeItem(int index) {
    setState(() {
      _soldItems.removeAt(index);
    });
  }

  // Complete the sale
  Future<void> _checkOut() async {
    if (_soldItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No items to sell')),
      );
      return;
    }

    try {
      // Fetch the selected customer's document
      QuerySnapshot customerQuery = await _firestore
          .collection('customers')
          .where('name', isEqualTo: _selectedCustomer)
          .get();

      if (customerQuery.docs.isEmpty) {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Customer not found')),
        );
        return;
      }

      final customerDoc = customerQuery.docs.first;
      final customerId = customerDoc.id;
      double customerBalance = customerDoc['balance'];

      // Calculate total sale amount
      double totalAmount = 0.0;
      for (var item in _soldItems) {
        totalAmount += item['quantity'] * item['price'];
      }

      // Check if all items are available in sufficient quantity
      for (var item in _soldItems) {
        // Fetch the item's document
        QuerySnapshot itemQuery = await _firestore
            .collection('items')
            .where('name', isEqualTo: item['item'])
            .get();

        if (itemQuery.docs.isNotEmpty) {
          final itemDoc = itemQuery.docs.first;
          double currentQuantity = itemDoc['quantity'] ?? 0.0;

          // Check if the item quantity is sufficient
          if (currentQuantity < item['quantity']) {
            // ignore: use_build_context_synchronously
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    'Not enough quantity. Only $currentQuantity units of ${item['item']} available.'),
              ),
            );
            return; // Exit the function if any item is insufficient
          }
        }
      }

      // If all items are available, proceed with the sale
      double newCustomerBalance = customerBalance - totalAmount;
      await _firestore.collection('customers').doc(customerId).update({
        'balance': newCustomerBalance,
      });

      // Update item quantities and store sale details
      for (var item in _soldItems) {
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
            'quantity': currentQuantity - item['quantity'],
          });

          // Fetch the item's purchase price for profit/loss calculation
          double purchasePrice = itemDoc['purchasePrice'] ?? 0.0;
          double profitLoss =
              (item['price'] - purchasePrice) * item['quantity'];

          // Store sale transaction
          await _firestore.collection('sales').add({
            'customerId': customerId,
            'customerName': _selectedCustomer,
            'item': item['item'],
            'quantity': item['quantity'],
            'price': item['price'],
            'totalAmount': item['quantity'] * item['price'],
            'profitLoss': profitLoss,
            'date': DateTime.now(),
            'userId': FirebaseAuth.instance.currentUser?.uid, // Add userId
          });

          // Add transaction to customer's ledger
          await _firestore.collection('customers').doc(customerId).update({
            'transactions': FieldValue.arrayUnion([
              {
                'date': DateTime.now(),
                'credit': 0.0, // No credit in this case
                'debit': item['quantity'] * item['price'], // Amount debited
                'balance': newCustomerBalance,
                'detail':
                    'Sold ${item['quantity']} units of ${item['item']} at ${item['price']} per unit',
                'type': 'Sale',
              }
            ]),
          });
        }
      }

      // Clear the sale list
      setState(() {
        _soldItems.clear();
      });

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sale completed successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing sale: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Sale Panel"),
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
                        value: _selectedCustomer,
                        hint: const Text('Select Customer'),
                        items: _customers.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedCustomer = newValue;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.005,
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
                        hint: const Text('Select Item'),
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
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
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
                          height: MediaQuery.of(context).size.height * 0.07,
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
                          for (int i = 0; i < _soldItems.length; i++)
                            ItemCasing(
                              itemName: _soldItems[i]['item'],
                              quantity: _soldItems[i]['quantity'],
                              price: _soldItems[i]['price'],
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

class ItemCasing extends StatelessWidget {
  final String itemName;
  final double quantity;
  final double price;
  final VoidCallback onDelete;

  const ItemCasing({
    super.key,
    required this.itemName,
    required this.quantity,
    required this.price,
    required this.onDelete,
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
              onTap: onDelete,
              icon: Icons.delete,
              iconColor: Colors.red,
              width: MediaQuery.of(context).size.width * 0.1,
            ),
          ],
        ),
      ),
    );
  }
}
