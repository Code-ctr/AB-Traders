import 'package:abtraders/Components/shape.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class BankAccount extends StatefulWidget {
  const BankAccount({super.key});

  @override
  State<BankAccount> createState() => _BankAccountState();
}

class _BankAccountState extends State<BankAccount> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _fetchUserBankAccounts();
  }

  void _fetchUserBankAccounts() async {
    User? user = _auth.currentUser;
    if (user != null) {
      QuerySnapshot querySnapshot = await _firestore
          .collection('bankAccounts')
          .where('userId', isEqualTo: user.uid)
          .get();

      setState(() {
        _bankAccounts = querySnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const ShapedS(),
        SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(
                height: MediaQuery.of(context).size.height * 0.47,
                child: Image.asset("lib/images/bankt.png"),
              ),
              if (_bankAccounts.isNotEmpty)
                ..._bankAccounts.map((account) {
                  return ContainerForBank(
                    accountName: account['accountTitle'],
                    balance: account['balance'].toString(),
                  );
                })
            ],
          ),
        ),
      ]),
    );
  }
}

class ContainerForBank extends StatelessWidget {
  final String accountName;
  final String balance;

  const ContainerForBank({
    super.key,
    required this.accountName,
    required this.balance,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.09,
      width: MediaQuery.of(context).size.width * 0.9,
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(7),
        color: Colors.white,
        boxShadow: const [
          BoxShadow(blurRadius: 10, offset: Offset(5, 5), color: Colors.black),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            Text(
              accountName,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const Spacer(),
            Text(
              balance,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
