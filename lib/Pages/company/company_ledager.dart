import 'package:flutter/material.dart';

class CompanyLedager extends StatelessWidget {
  const CompanyLedager({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Company Ledager"),
          backgroundColor: Colors.teal,
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.02,
                ),
                for (int i = 0; i < 15; i++) ...[
                  const CompanyDetail(),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                ]
              ],
            ),
          ),
        ));
  }
}

class CompanyDetail extends StatelessWidget {
  const CompanyDetail({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.15,
      width: MediaQuery.of(context).size.width * 0.96,
      decoration: BoxDecoration(
          color: Colors.teal.shade600, borderRadius: BorderRadius.circular(5)),
      child: const Column(
        children: [
          Padding(
            padding: EdgeInsets.all(10.0),
            child: Row(
              children: [
                Text(
                  "Muhammad Ayoub",
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  "10000",
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
                Spacer(),
                Text(
                  "20-01",
                  style: TextStyle(
                      color: Colors.amber,
                      fontSize: 17,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Detail: this Amount Was Paid by X and Y for Z that has to Collect on d time on k Location",
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
