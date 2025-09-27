import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddingNewCustomer extends StatefulWidget {
  const AddingNewCustomer({super.key});

  @override
  State<AddingNewCustomer> createState() => _AddingNewCustomerState();
}

class _AddingNewCustomerState extends State<AddingNewCustomer> {
  // Controllers for text fields
  TextEditingController customerName = TextEditingController();
  TextEditingController contactNumber = TextEditingController();
  TextEditingController address = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _isLoading = false;

  // Function to add a new customer
  Future<void> _addCustomer() async {
    setState(() {
      _isLoading = true;
    });
    try {
      if (customerName.text.isEmpty ||
          contactNumber.text.isEmpty ||
          address.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please fill all fields')),
        );
        return;
      }
    } catch (e) {
      // Handle error
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }

    // Create a new customer object
    Map<String, dynamic> customerData = {
      'name': customerName.text,
      'contactNumber': contactNumber.text,
      'address': address.text,
      'balance': 0.0, // Starting balance is always 0
      'transactions': [], // Initialize an empty transactions array
      'userId': user.uid,
    };

    try {
      // Add the customer to Firestore
      await _firestore.collection('customers').add(customerData);

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Customer added successfully')),
      );

      // Clear the form
      customerName.clear();
      contactNumber.clear();
      address.clear();
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adding New Customer"),
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
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.3,
                    width: MediaQuery.of(context).size.width * 0.45,
                    child: Image.asset('lib/images/account.png'),
                  ),
                  MyTextField(
                    controller: customerName,
                    hinttext: "Customer Name",
                  ),
                  MyTextField(
                    controller: contactNumber,
                    hinttext: "Contact Number",
                  ),
                  MyTextField(
                    controller: address,
                    hinttext: "Address",
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  MyButton(
                    onTap:
                        _addCustomer, // Call _addCustomer when the button is pressed
                    text: "Add",
                    color: Colors.teal.shade600,
                    shadow: true,
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
