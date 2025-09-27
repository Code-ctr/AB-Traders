import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddingAccounts extends StatefulWidget {
  const AddingAccounts({super.key});

  @override
  State<AddingAccounts> createState() => _AddingAccountsState();
}

class _AddingAccountsState extends State<AddingAccounts> {
  final TextEditingController _accountTitleController = TextEditingController();
  final TextEditingController _accountNumberController =
      TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> _addAccount() async {
    String accountTitle = _accountTitleController.text.trim();
    String accountNumber = _accountNumberController.text.trim();

    if (accountTitle.isEmpty || accountNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in')),
      );
      return;
    }

    try {
      // Add the bank account to Firestore
      await _firestore.collection('bankAccounts').add({
        'accountTitle': accountTitle,
        'accountNumber': accountNumber,
        'balance': 0.0, // Starting balance is zero
        'userId': user.uid, // Associate the account with the logged-in user
      });

      // Clear the form
      _accountTitleController.clear();
      _accountNumberController.clear();

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account added successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding account: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.47,
            child: Image.asset("lib/images/bankt.png"),
          ),
          MyTextField(
            controller: _accountTitleController,
            hinttext: "Account Title",
            width: MediaQuery.of(context).size.width * 0.9,
          ),
          MyTextField(
            controller: _accountNumberController,
            hinttext: "Account Number",
            width: MediaQuery.of(context).size.width * 0.9,
            isNumeric: true,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.1,
          ),
          MyButton(
            onTap: _addAccount, // Call the _addAccount function
            text: "Add Account",
            color: Colors.teal.shade600,
          ),
        ],
      ),
    );
  }
}
