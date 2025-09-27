import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:abtraders/Pages/company/company_ledager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class ComPayment extends StatefulWidget {
  final String companyId;
  final String companyName;
  final double currentBalance;
  final VoidCallback onTransactionComplete;

  const ComPayment({
    super.key,
    required this.companyId,
    required this.companyName,
    required this.currentBalance,
    required this.onTransactionComplete,
  });

  @override
  State<ComPayment> createState() => _ComPaymentState();
}

class _ComPaymentState extends State<ComPayment> {
  final List<String> _paymentType = ['Receiving', 'Paying'];
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _detailController = TextEditingController();
  String? _selectedBank;
  String? _selectedPayment;
  String? _selectedPaymentMethod;
  List<String> _banks = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchBanks(); // Fetch banks when the widget is initialized
  }

  // Fetch banks from Firestore
  Future<void> _fetchBanks() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      return;
    }
    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .get();
      if (querySnapshot.docs.isEmpty) {
        return;
      }
      List<String> banks = [];
      for (var doc in querySnapshot.docs) {
        banks.add(doc['accountTitle']);
      }
      setState(() {
        _banks = banks;
      });
    } catch (e) {
      print('Error fetching banks: $e');
    }
  }

  // Update cash balance in Firestore
  Future<void> _updateCashBalance(double amount) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      DocumentSnapshot cashSnapshot =
          await _firestore.collection('cashBalances').doc(user.uid).get();

      double currentBalance =
          cashSnapshot.exists ? cashSnapshot['balance'] : 0.0;
      await _firestore.collection('cashBalances').doc(user.uid).set({
        'balance': currentBalance +
            amount, // Increase or decrease based on payment type
        'userId': user.uid,
      });
    }
  }

  // Update bank account balance in Firestore
  Future<void> _updateBankBalance(String bankName, double amount) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .where('accountTitle', isEqualTo: bankName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot bankSnapshot = querySnapshot.docs.first;
        double currentBalance = bankSnapshot['balance'];
        await bankSnapshot.reference.update({
          'balance': currentBalance +
              amount, // Increase or decrease based on payment type
        });
      }
    }
  }

  // Function to complete the transaction
  Future<void> _completeTransaction() async {
    if (_selectedPayment == null || _amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double amount = double.tryParse(_amountController.text) ?? 0.0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    double newBalance = widget.currentBalance;
    if (_selectedPayment == 'Receiving') {
      newBalance += amount; // Increase balance for receiving
    } else if (_selectedPayment == 'Paying') {
      newBalance -= amount; // Decrease balance for paying
    }

    // Update cash or bank balance based on the selected payment method
    if (_selectedPaymentMethod == 'Cash') {
      // Update cash balance
      double cashAmount = _selectedPayment == 'Receiving' ? amount : -amount;
      await _updateCashBalance(cashAmount);
    } else if (_selectedPaymentMethod == 'Bank/Online' &&
        _selectedBank != null) {
      // Update bank balance
      double bankAmount = _selectedPayment == 'Receiving' ? amount : -amount;
      await _updateBankBalance(_selectedBank!, bankAmount);
    }

    // Create a new transaction record
    Map<String, dynamic> transaction = {
      'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      'credit': _selectedPayment == 'Receiving' ? amount : 0,
      'debit': _selectedPayment == 'Paying' ? amount : 0,
      'balance': newBalance,
      'detail': _detailController.text,
      'paymentType': _selectedPayment,
      'bank': _selectedPaymentMethod == 'Cash' ? 'Cash' : _selectedBank,
    };
    await _firestore
        .collection('companies')
        .doc(widget.companyId)
        .collection('transactions')
        .add(transaction);

    try {
      // Update the company/investor document in Firestore
      await _firestore.collection('companies').doc(widget.companyId).update({
        'balance': newBalance,
      });

      // Clear the form
      _amountController.clear();
      _detailController.clear();
      setState(() {
        _selectedBank = null;
        _selectedPayment = null;
        _selectedPaymentMethod = null;
      });

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaction completed successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error completing transaction: $e')),
      );
    }
    widget.onTransactionComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Com/Inv Payment"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text(
                      widget.companyName,
                      style: const TextStyle(
                          color: Colors.amber,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                Align(
                  alignment: Alignment.topLeft,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30.0),
                    child: Text(
                      "Amount :: ${widget.currentBalance}",
                      style: TextStyle(
                          color: widget.currentBalance >= 0
                              ? Colors.green.shade900
                              : Colors.red.shade900,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
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
                      value: _selectedPayment,
                      hint: const Text('Select Payment Type'),
                      items: _paymentType.map((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        setState(() {
                          _selectedPayment = newValue;
                        });
                      },
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Colors.black),
                      iconSize: 24,
                    ),
                  ),
                ),
                MyTextField(
                  controller: _amountController,
                  hinttext: "Enter Amount",
                  icon: Icons.monetization_on_outlined,
                  width: MediaQuery.of(context).size.width * 0.925,
                  isNumeric: true,
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ChoiceChip(
                      label: const Text('Cash'),
                      selected: _selectedPaymentMethod == 'Cash',
                      onSelected: (selected) {
                        setState(() {
                          _selectedPaymentMethod = selected ? 'Cash' : null;
                        });
                      },
                    ),
                    ChoiceChip(
                      label: const Text('Bank/Online'),
                      selected: _selectedPaymentMethod == 'Bank/Online',
                      onSelected: (selected) {
                        setState(() {
                          _selectedPaymentMethod =
                              selected ? 'Bank/Online' : null;
                        });
                      },
                    ),
                  ],
                ),
                SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                Visibility(
                  visible: _selectedPaymentMethod == 'Bank/Online',
                  child: Container(
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
                        value: _selectedBank,
                        hint: const Text('Select Bank'),
                        items: _banks.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedBank = newValue;
                          });
                        },
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.black),
                        iconSize: 24,
                      ),
                    ),
                  ),
                ),
                MyTextField(
                  controller: _detailController,
                  hinttext: "Enter Detail",
                  icon: Icons.details,
                  width: MediaQuery.of(context).size.width * 0.92,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                MyButton(
                  onTap: _completeTransaction,
                  text: "Complete Transcation",
                  color:
                      _selectedPayment != null && _selectedPaymentMethod != null
                          ? Colors.teal.shade600
                          : Colors.grey,
                  isDisabled: _selectedPayment == null ||
                      _selectedPaymentMethod == null,
                  width: MediaQuery.of(context).size.width * 0.6,
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.1,
                ),
                MyButton(
                  onTap: () {
                    Navigator.push(context,
                        MaterialPageRoute(builder: (context) {
                      return const CompanyLedager();
                    }));
                  },
                  text: "Check All Transcation",
                  color: Colors.teal.shade600,
                  width: MediaQuery.of(context).size.width * 0.9,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
