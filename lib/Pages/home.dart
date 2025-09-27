import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Pages/Bank/bank_home.dart';
import 'package:abtraders/Pages/Customer/customer_home_page.dart';
import 'package:abtraders/Pages/Expense/expense_home.dart';
import 'package:abtraders/Pages/Product/product_homepage.dart';
import 'package:abtraders/Pages/Purchase/purchase_home.dart';
import 'package:abtraders/Pages/Reports/report_home.dart';
import 'package:abtraders/Pages/Sales/sale_panel.dart';
import 'package:abtraders/Pages/company/c_home.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  List buttontext = [
    "Customers",
    "Items",
    "Sales",
    "Reports",
    "Expense",
    "Purchase",
    "Com/Inv"
  ];

  List images = [
    Icons.person,
    Icons.inventory_rounded,
    Icons.sell,
    Icons.report,
    Icons.monetization_on_rounded,
    Icons.production_quantity_limits_sharp,
    Icons.switch_account_sharp,
  ];

  List<Widget> get routes => [
        const CustomerHomePage(),
        const ProductHomepage(),
        const SalePanel(),
        const ReportPage(),
        ExpensePanel(
          onTransactionComplete: () {
            setState(() {}); // This will refresh the Home page
          },
        ),
        const PurchaseHome(),
        const CHome(),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(children: [
        const ShapedS(),
        Center(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.05,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 15.0),
                  child: Row(
                    children: [
                      Align(
                        alignment: AlignmentDirectional.topStart,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.height * 0.06,
                          height: MediaQuery.of(context).size.height * 0.06,
                          child: ClipOval(
                            child: Image.asset("lib/images/obsidianByte.ico"),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.02,
                      ),
                      const Text("DEVELOPED By OBSIDIAN BYTES")
                    ],
                  ),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.15,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.0),
                  child: MyContainer(),
                ),
                Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        childAspectRatio:
                            1.8, // Adjust the aspect ratio as needed
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 12,
                      ),
                      itemCount: buttontext
                          .length, // Number of buttons (rows) you want to create
                      itemBuilder: (context, index) {
                        return MyButton(
                          onTap: () {
                            Navigator.push(context,
                                MaterialPageRoute(builder: (context) {
                              return routes[index];
                            }));
                          },
                          text: buttontext[index],
                          icon: images[index],
                          color: Colors.teal,
                          iconColor: Colors.white,
                          radius: 10,
                          size: 30,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }
}

class MyContainer extends StatelessWidget {
  const MyContainer({super.key});

  // Stream to fetch cash balance in real-time
  Stream<double> _getCashBalanceStream() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    return firestore
        .collection('cashBalances')
        .doc(auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.exists ? snapshot['balance'] : 0.0);
  }

  // Stream to fetch total bank balance in real-time
  Stream<double> _getBankBalanceStream() {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;
    final FirebaseAuth auth = FirebaseAuth.instance;
    return firestore
        .collection('bankAccounts')
        .where('userId', isEqualTo: auth.currentUser?.uid)
        .snapshots()
        .map((snapshot) => snapshot.docs
            // ignore: avoid_types_as_parameter_names
            .fold(0.0, (sum, doc) => sum + (doc['balance'] as double)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.32,
      width: MediaQuery.of(context).size.width * 1,
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 2, 77, 68),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: AlignmentDirectional.topEnd,
              child: MyButton(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(builder: (context) {
                    return const BankHome();
                  }));
                },
                icon: Icons.arrow_outward,
                color: Colors.blueGrey.shade400,
                width: MediaQuery.of(context).size.width * 0.12,
                height: MediaQuery.of(context).size.height * 0.07,
                radius: 360,
                iconColor: Colors.black,
              ),
            ),
            const Text(
              "Bank Balance",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Real-time bank balance
            StreamBuilder<double>(
              stream: _getBankBalanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  return Text(
                    snapshot.data?.toStringAsFixed(2) ?? '0.00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              },
            ),
            const Spacer(),
            const Text(
              "Cash Balance",
              style: TextStyle(
                color: Colors.amber,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Real-time cash balance
            StreamBuilder<double>(
              stream: _getCashBalanceStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text(
                    'Error: ${snapshot.error}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                } else {
                  return Text(
                    snapshot.data?.toStringAsFixed(2) ?? '0.00',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
