import 'package:flutter/material.dart';

class AllExpenses extends StatelessWidget {
  const AllExpenses({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("All Expenses"),
          backgroundColor: Colors.teal,
        ),
        body: Center(
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height * 0.05),
              const ExpenseShowCase(),
            ],
          ),
        ));
  }
}

class ExpenseShowCase extends StatelessWidget {
  const ExpenseShowCase({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.2,
      width: MediaQuery.of(context).size.width * 0.9,
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.teal.shade600),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Expense Name",
            style: TextStyle(
                color: Colors.amber.shade400,
                fontWeight: FontWeight.bold,
                fontSize: 20),
          ),
          const Text(
            "Amoun ---> 20000",
            style: TextStyle(fontSize: 20, color: Colors.white),
          )
        ],
      ),
    );
  }
}
