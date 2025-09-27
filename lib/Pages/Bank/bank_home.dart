import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Pages/Bank/adding_account.dart';
import 'package:abtraders/Pages/Bank/bank_account.dart';
import 'package:flutter/material.dart';

class BankHome extends StatelessWidget {
  const BankHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Bank Panel"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(
        children: [
          const ShapedS(),
          PageView(
            children: const [
              BankAccount(),
              AddingAccounts(),
            ],
          ),
        ],
      ),
    );
  }
}
