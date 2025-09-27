import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:abtraders/Pages/Expense/all_expenses.dart';
import 'package:abtraders/Pages/Expense/expense_adding_catogery.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ExpensePanel extends StatefulWidget {
  final VoidCallback onTransactionComplete;
  const ExpensePanel({super.key, required this.onTransactionComplete});

  @override
  State<ExpensePanel> createState() => _ExpensePanelState();
}

class _ExpensePanelState extends State<ExpensePanel> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _expenseCategories = [];
  List<String> _bankAccounts = [];
  String? _selectedExpenseCategory;
  String? _selectedBankAccount;
  String? _selectedPaymentType;
  bool _isBankDropdownEnabled = false;

  TextEditingController amountController = TextEditingController();
  TextEditingController detailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchExpenseCategories();
    _fetchBankAccounts();
  }

  // Fetch user-specific expense categories
  void _fetchExpenseCategories() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('expenseCategories')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _expenseCategories =
            querySnapshot.docs.map((doc) => doc['name'] as String).toList();
      });
    }
  }

  // Fetch user-specific bank accounts
  void _fetchBankAccounts() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _bankAccounts = querySnapshot.docs
            .map((doc) => doc['accountTitle'] as String)
            .toList();
      });
    }
  }

  // Handle payment type selection
  void _handlePaymentTypeSelection(String value) {
    setState(() {
      _selectedPaymentType = value;
      _isBankDropdownEnabled = value == 'Bank/Online';
    });
  }

  // Save the transaction and update balances
  void _saveTransaction() async {
    User? user = _auth.currentUser;
    if (user == null ||
        _selectedExpenseCategory == null ||
        amountController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    double amount = double.parse(amountController.text);

    // Update cash or bank account balance
    if (_selectedPaymentType == 'Cash') {
      await _updateCashBalance(amount);
    } else if (_selectedPaymentType == 'Bank/Online' &&
        _selectedBankAccount != null) {
      await _updateBankAccountBalance(_selectedBankAccount!, amount);
    }

    // Update expense category balance
    await _updateExpenseCategoryBalance(_selectedExpenseCategory!, amount);

    // Save transaction details
    await _firestore.collection('transactions').add({
      'userId': user.uid,
      'expenseCategory': _selectedExpenseCategory,
      'paymentType': _selectedPaymentType,
      'bankAccount': _selectedBankAccount,
      'amount': amount,
      'detail': detailController.text,
      'timestamp': FieldValue.serverTimestamp(),
    });

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction saved successfully')),
    );

    // Clear fields
    amountController.clear();
    detailController.clear();
    setState(() {
      _selectedExpenseCategory = null;
      _selectedBankAccount = null;
      _selectedPaymentType = null;
      _isBankDropdownEnabled = false;
    });

    // Trigger the callback to refresh balances
    widget.onTransactionComplete();
  }

  // Update cash balance
  Future<void> _updateCashBalance(double amount) async {
    User? user = _auth.currentUser;
    if (user != null) {
      DocumentSnapshot cashSnapshot =
          await _firestore.collection('cashBalances').doc(user.uid).get();

      double currentBalance =
          cashSnapshot.exists ? cashSnapshot['balance'] : 0.0;
      await _firestore.collection('cashBalances').doc(user.uid).set({
        'balance': currentBalance - amount,
        'userId': user.uid,
      });
    }
  }

  // Update bank account balance
  Future<void> _updateBankAccountBalance(
      String accountTitle, double amount) async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .where('accountTitle', isEqualTo: accountTitle)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot bankAccount = querySnapshot.docs.first;
        double currentBalance = bankAccount['balance'];
        await bankAccount.reference.update({
          'balance': currentBalance - amount,
        });
      }
    }
  }

  // Update expense category balance
  Future<void> _updateExpenseCategoryBalance(
      String category, double amount) async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('expenseCategories')
          .where('userId', isEqualTo: user.uid)
          .where('name', isEqualTo: category)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        DocumentSnapshot expenseCategory = querySnapshot.docs.first;
        double currentBalance = expenseCategory['balance'];
        await expenseCategory.reference.update({
          'balance': currentBalance + amount,
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Expense Panel"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: MyButton(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (context) {
                          return const AddingExpense();
                        }));
                      },
                      icon: Icons.add,
                      color: Colors.blueGrey.shade300,
                      width: MediaQuery.of(context).size.width * 0.15,
                      radius: 360,
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Expense Category Dropdown
                  Container(
                    height: 60,
                    width: MediaQuery.of(context).size.width * 0.92,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.black),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        iconEnabledColor: Colors.white,
                        value: _selectedExpenseCategory,
                        hint: const Text('Select Expense Category'),
                        items: _expenseCategories.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            _selectedExpenseCategory = newValue;
                          });
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ChoiceChip(
                        selectedColor: Colors.blueGrey.shade300,
                        label: const Text('Cash'),
                        selected: _selectedPaymentType == 'Cash',
                        onSelected: (selected) {
                          _handlePaymentTypeSelection('Cash');
                        },
                      ),
                      ChoiceChip(
                        label: const Text('Bank/Online'),
                        selected: _selectedPaymentType == 'Bank/Online',
                        onSelected: (selected) {
                          _handlePaymentTypeSelection('Bank/Online');
                        },
                      ),
                    ],
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.005),
                  if (_isBankDropdownEnabled)
                    Container(
                      height: 60,
                      width: MediaQuery.of(context).size.width * 0.92,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          iconEnabledColor: Colors.white,
                          value: _selectedBankAccount,
                          hint: const Text('Select Bank Account'),
                          items: _bankAccounts.map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedBankAccount = newValue;
                            });
                          },
                        ),
                      ),
                    ),
                  MyTextField(
                    controller: amountController,
                    hinttext: "Enter Amount",
                    icon: Icons.monetization_on_outlined,
                    isNumeric: true,
                  ),
                  MyTextField(
                    controller: detailController,
                    hinttext: "Entry Detail",
                    icon: Icons.details_rounded,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.17),
                  MyButton(
                    onTap: _saveTransaction,
                    color: _selectedPaymentType != null &&
                            _selectedExpenseCategory != null
                        ? Colors.teal.shade600
                        : Colors.grey,
                    isDisabled: _selectedPaymentType != null &&
                        _selectedExpenseCategory != null,
                    text: "Done",
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.1),
                  // Check All Expenses Button
                  MyButton(
                    onTap: () {
                      Navigator.push(context,
                          MaterialPageRoute(builder: (context) {
                        return const AllExpenses();
                      }));
                    },
                    color: Colors.teal.shade600,
                    text: "Check All Expenses",
                    width: MediaQuery.of(context).size.width * 0.8,
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
