import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/pdffile_generater.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerPayment extends StatefulWidget {
  final String customerId;
  final String customerName;
  final double currentBalance;
  final VoidCallback onTransactionComplete;

  const CustomerPayment({
    super.key,
    required this.customerId,
    required this.customerName,
    required this.currentBalance,
    required this.onTransactionComplete,
  });

  @override
  State<CustomerPayment> createState() => _CustomerPaymentState();
}

class _CustomerPaymentState extends State<CustomerPayment> {
  List<String> _banksList = [];
  final List<String> _paymentType = ['Receiving', 'Paying'];
  String? _selectedBank;
  String? _selectedPayment;
  String? _selectedPaymentMethod;
  TextEditingController amount = TextEditingController();
  TextEditingController detail = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchBanks();
  }

  Future<void> _fetchBanks() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .get();
      List<String> banks = querySnapshot.docs
          .map((doc) => doc['accountTitle'] as String)
          .toList();
      setState(() => _banksList = banks);
    } catch (e) {
      print('Error fetching banks: $e');
    }
  }

  Future<void> _updateCashBalance(double amount) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) return;

    try {
      DocumentSnapshot cashSnapshot =
          await _firestore.collection('cashBalances').doc(user.uid).get();
      double currentBalance =
          cashSnapshot.exists ? cashSnapshot['balance'] : 0.0;
      await _firestore.collection('cashBalances').doc(user.uid).set({
        'balance': currentBalance + amount,
        'userId': user.uid,
      });
    } catch (e) {
      print('Error updating cash balance: $e');
    }
  }

  Future<void> _updateBankBalance(String bankName, double amount) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) return;

    try {
      QuerySnapshot querySnapshot = await _firestore
          .collection('banks')
          .where('userId', isEqualTo: user.uid)
          .where('name', isEqualTo: bankName)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot bankSnapshot = querySnapshot.docs.first;
        double currentBalance = bankSnapshot['balance'];
        await bankSnapshot.reference
            .update({'balance': currentBalance + amount});
      }
    } catch (e) {
      print('Error updating bank balance: $e');
    }
  }

  void _completeTransaction() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) return;

    double amountValue = double.tryParse(amount.text) ?? 0.0;
    if (amountValue <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    double newBalance = widget.currentBalance;
    if (_selectedPayment == 'Receiving') {
      newBalance += amountValue;
    } else if (_selectedPayment == 'Paying') {
      newBalance -= amountValue;
    }

    if (_selectedPaymentMethod == 'Cash') {
      double cashAmount =
          _selectedPayment == 'Receiving' ? amountValue : -amountValue;
      await _updateCashBalance(cashAmount);
    } else if (_selectedPaymentMethod == 'Bank/Online' &&
        _selectedBank != null) {
      double bankAmount =
          _selectedPayment == 'Receiving' ? amountValue : -amountValue;
      await _updateBankBalance(_selectedBank!, bankAmount);
    }

    Map<String, dynamic> transaction = {
      'date': DateFormat('dd-MM-yyyy').format(DateTime.now()),
      'credit': _selectedPayment == 'Receiving' ? amountValue : 0,
      'debit': _selectedPayment == 'Paying' ? amountValue : 0,
      'balance': newBalance,
      'detail': detail.text,
      'paymentType': _selectedPayment,
      'bank': _selectedPaymentMethod == 'Cash' ? 'Cash' : _selectedBank,
      'userId': user.uid,
    };
    await _firestore
        .collection('customers')
        .doc(widget.customerId)
        .collection('transactions')
        .add(transaction);

    await _firestore.collection('customers').doc(widget.customerId).update({
      'balance': newBalance,
      'userId': user.uid,
    });

    amount.clear();
    detail.clear();
    setState(() {
      _selectedBank = null;
      _selectedPayment = null;
      _selectedPaymentMethod = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction completed successfully')),
    );

    widget.onTransactionComplete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer Payment"),
        backgroundColor: Colors.teal,
      ),
      body: SingleChildScrollView(
        child: Stack(children: [
          const ShapedS(),
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            SizedBox(height: MediaQuery.of(context).size.height * 0.05),
            Text(
              widget.customerName,
              style: const TextStyle(
                  color: Colors.amber,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            Text(
              "Current Balance: \t${widget.currentBalance}",
              style: TextStyle(
                  fontSize: 20,
                  color: widget.currentBalance >= 0
                      ? Colors.green.shade900
                      : Colors.red.shade900,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            MyTextField(
              width: MediaQuery.of(context).size.width * 0.925,
              controller: amount,
              hinttext: "Amount",
              icon: Icons.monetization_on_outlined,
              isNumeric: true,
            ),
            Center(
              child: Container(
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
                    hint: const Text('Select Payment type'),
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
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.black),
                    iconSize: 24,
                  ),
                ),
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
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
                      _selectedPaymentMethod = selected ? 'Bank/Online' : null;
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.01),
            Visibility(
              visible: _selectedPaymentMethod == 'Bank/Online',
              child: Center(
                child: Container(
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
                      value: _selectedBank,
                      hint: const Text('Select a bank'),
                      items: _banksList.map((String value) {
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
            ),
            MyTextField(
              width: MediaQuery.of(context).size.width * 0.925,
              controller: detail,
              hinttext: "Detail of the Transcation",
              icon: Icons.details,
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 90.0),
              child: MyButton(
                onTap: _completeTransaction,
                text: "Complete",
                color:
                    _selectedPayment != null && _selectedPaymentMethod != null
                        ? Colors.teal.shade600
                        : Colors.grey,
                isDisabled:
                    _selectedPayment == null || _selectedPaymentMethod == null,
              ),
            ),
            SizedBox(height: MediaQuery.of(context).size.height * 0.12),
            MyButton(
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return CustomerLedgerPdf(
                    customerId: widget.customerId,
                    customerName: widget.customerName,
                  );
                }));
              },
              text: "Check Full Ledagr",
              color: Colors.teal.shade600,
              width: MediaQuery.of(context).size.width * 0.9,
            ),
          ]),
        ]),
      ),
    );
  }
}
