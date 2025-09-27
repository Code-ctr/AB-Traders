import 'package:abtraders/Pages/Reports/each_item_profit.dart';
import 'package:abtraders/Pages/Reports/remaining_item.dart';
import 'package:flutter/material.dart';

class ReportPage extends StatelessWidget {
  const ReportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Report Panel"),
          backgroundColor: Colors.teal,
        ),
        body: PageView(children: const [
          RemainingItem(),
          EachItemProfit(),
        ]));
  }
}
