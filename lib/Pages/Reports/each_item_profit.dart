import 'package:abtraders/Components/shadow_container.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class EachItemProfit extends StatelessWidget {
  const EachItemProfit({super.key});

  // Fetch sales data and calculate total profit for each item
  Future<Map<String, double>> _fetchItemProfits() async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      return {};
    }
    try {
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('sales')
          .where('userId', isEqualTo: user.uid)
          .get();
      Map<String, double> itemProfits = {};
      for (var doc in querySnapshot.docs) {
        String itemName = doc['item'];
        double profit = doc['profitLoss'];
        itemProfits[itemName] = (itemProfits[itemName] ?? 0) + profit;
      }
      return itemProfits;
    } catch (e) {
      print('Error fetching sales: $e');
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            "Profit",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.02,
          ),
          Container(
            height: MediaQuery.of(context).size.height * 0.7,
            width: MediaQuery.of(context).size.width * 0.9,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.black, width: 3),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 25,
                  offset: Offset(10, 10),
                  color: Colors.black,
                ),
              ],
            ),
            child: FutureBuilder<Map<String, double>>(
              future: _fetchItemProfits(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text('No sales found'),
                  );
                } else {
                  Map<String, double> itemProfits = snapshot.data!;

                  // Calculate total profit
                  double totalProfit =
                      itemProfits.values.fold(0, (sum, profit) => sum + profit);

                  return Column(
                    children: [
                      // Display total profit
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text(
                          'Total Profit: Pkr ${totalProfit.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      // Display individual item profits
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: itemProfits.entries.map((entry) {
                              return Padding(
                                padding: EdgeInsets.symmetric(
                                  vertical: MediaQuery.of(context).size.height *
                                      0.015,
                                ),
                                child: ShadowContainers(
                                  itemName: entry.key,
                                  quantity: entry.value,
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
