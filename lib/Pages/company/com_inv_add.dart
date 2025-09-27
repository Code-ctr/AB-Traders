import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ComInvAdd extends StatefulWidget {
  const ComInvAdd({super.key});

  @override
  State<ComInvAdd> createState() => _ComInvAddState();
}

class _ComInvAddState extends State<ComInvAdd> {
  final TextEditingController _companyName = TextEditingController();
  final TextEditingController _contactNumber = TextEditingController();
  final List<String> _comInv = ['Company', 'Investor'];
  String? _selectedComInv;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Function to add a new company or investor
  Future<void> _addComInv() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    if (_selectedComInv == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select Company or Investor')),
      );
      return;
    }

    if (_companyName.text.isEmpty || _contactNumber.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      // Create a new document in the appropriate collection
      if (_selectedComInv == 'Company') {
        await _firestore.collection('companies').add({
          'name': _companyName.text,
          'contactNumber': _contactNumber.text,
          'balance': 0.0, // Starting balance is zero
          'createdAt': DateTime.now(), // Optional: Store the creation timestamp
          'userId': user.uid,
        });
      } else if (_selectedComInv == 'Investor') {
        await _firestore.collection('investors').add({
          'name': _companyName.text,
          'contactNumber': _contactNumber.text,
          'balance': 0.0, // Starting balance is zero
          'createdAt': DateTime.now(),
          'transactions': [],
        });
      }

      // Clear the form
      _companyName.clear();
      _contactNumber.clear();
      setState(() {
        _selectedComInv = null;
      });

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Added successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding $_selectedComInv: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Adding Com/Inv"),
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
                    height: MediaQuery.of(context).size.height * 0.05,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.07,
                    width: MediaQuery.of(context).size.width * 0.9,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        alignment: AlignmentDirectional.centerStart,
                        borderRadius: BorderRadius.circular(10),
                        dropdownColor: Colors.white,
                        value: _selectedComInv,
                        hint: const Text('Select Type'),
                        items: _comInv.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedComInv = newValue;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.02,
                  ),
                  MyTextField(
                    controller: _companyName,
                    hinttext: _selectedComInv == null
                        ? "Name"
                        : "$_selectedComInv Name",
                  ),
                  MyTextField(
                    controller: _contactNumber,
                    hinttext: "Phone Number",
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                  ),
                  MyButton(
                    onTap:
                        _addComInv, // Call _addComInv when the button is pressed
                    color: Colors.teal.shade600,
                    text: "Add",
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
