import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:flutter/material.dart';

class CustomerLedger extends StatelessWidget {
  const CustomerLedger({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Customer ledger"),
        backgroundColor: Colors.teal,
      ),
      body: Stack(children: [
        const ShapedS(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.0),
              child: Text("Customer Name",
                  style: TextStyle(
                      fontSize: 20,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold)),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 28.0),
              child: Text(
                "Mobile Number",
                style: TextStyle(
                    fontSize: 20,
                    color: Colors.amber,
                    fontWeight: FontWeight.bold),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: Text(
                "Current Balance\t\t 20000",
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Colors.green.shade900),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.05,
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.57,
              child: SingleChildScrollView(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: DataTable(
                      dataRowColor:
                          WidgetStateProperty.all(Colors.blueGrey.shade400),
                      decoration: BoxDecoration(
                        color: Colors.yellow,
                        border: Border.all(color: Colors.black26),
                      ),
                      columns: const <DataColumn>[
                        DataColumn(label: Text("Date")),
                        DataColumn(label: Text("Credit")),
                        DataColumn(label: Text("Debit")),
                        DataColumn(label: Text("Balance")),
                      ],
                      rows: List.generate(
                        20,
                        (index) => const DataRow(
                          cells: <DataCell>[
                            DataCell(Text("20-12")),
                            DataCell(Text("Amount")),
                            DataCell(Text("Amount")),
                            DataCell(Text("Amount")),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.02,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 80.0),
              child: MyButton(
                onTap: () {},
                text: "Generate Full Reporte",
                color: Colors.teal.shade600,
                width: MediaQuery.of(context).size.width * 0.6,
              ),
            )
          ],
        ),
      ]),
    );
  }
}
