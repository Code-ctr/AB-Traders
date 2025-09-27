import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:printing/printing.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:intl/intl.dart'; // For date formatting

class CustomerLedgerPdf extends StatelessWidget {
  final String customerId;
  final String customerName;

  const CustomerLedgerPdf({
    super.key,
    required this.customerId,
    required this.customerName,
  });

  Future<List<Map<String, dynamic>>> _fetchAllTransactions(
      String customerId) async {
    final FirebaseAuth auth = FirebaseAuth.instance;
    User? user = auth.currentUser;
    if (user == null) {
      return [];
    }

    try {
      // Fetch transactions from the 'transactions' array
      DocumentSnapshot customerDoc = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .get();

      List<dynamic> arrayTransactions = customerDoc['transactions'] ?? [];

      // Fetch transactions from the 'transactions' subcollection
      QuerySnapshot subcollectionSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .doc(customerId)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      List<Map<String, dynamic>> subcollectionTransactions =
          subcollectionSnapshot.docs.map((doc) {
        Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        // Convert Timestamp to a formatted date string
        if (data['date'] is Timestamp) {
          data['date'] = DateFormat('dd-MM-yyyy').format(data['date'].toDate());
        }
        return data;
      }).toList();

      // Combine both lists
      List<Map<String, dynamic>> allTransactions = [
        ...arrayTransactions.map((transaction) {
          if (transaction['date'] is Timestamp) {
            transaction['date'] =
                DateFormat('dd-MM-yyyy').format(transaction['date'].toDate());
          }
          return transaction as Map<String, dynamic>;
        }),
        ...subcollectionTransactions,
      ];

      return allTransactions;
    } catch (e) {
      print('Error fetching transactions: $e');
      return [];
    }
  }

  Future<void> _generatePdf(
      List<Map<String, dynamic>> transactions, String customerName) async {
    try {
      // Create a PDF document
      final pdf = pw.Document();

      // Add a page to the PDF
      pdf.addPage(
        pw.Page(
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Header(
                  level: 0,
                  child: pw.Text(
                    'Customer Ledger: $customerName',
                    style: pw.TextStyle(
                        fontSize: 24, fontWeight: pw.FontWeight.bold),
                  ),
                ),
                pw.SizedBox(height: 20),

                // Table
                // ignore: deprecated_member_use
                pw.Table.fromTextArray(
                  context: context,
                  data: [
                    [
                      'Date',
                      'Credit',
                      'Debit',
                      'Balance',
                      'Detail'
                    ], // Table headers
                    ...transactions.map((transaction) => [
                          transaction['date']?.toString() ?? 'N/A',
                          (transaction['credit'] ?? 0).toString(),
                          (transaction['debit'] ?? 0).toString(),
                          (transaction['balance'] ?? 0).toString(),
                          transaction['detail']?.toString() ?? 'No detail',
                        ]),
                  ],
                  cellStyle: const pw.TextStyle(fontSize: 12),
                  headerStyle: pw.TextStyle(
                      fontSize: 14, fontWeight: pw.FontWeight.bold),
                ),
              ],
            );
          },
        ),
      );

      // Save and share the PDF
      await Printing.sharePdf(
          bytes: await pdf.save(), filename: '$customerName Ledger.pdf');
    } catch (e) {
      print('Error generating PDF: $e');
      // Fallback to CSV if PDF generation fails
      await exportAsCsv(transactions, customerName);
    }
  }

  Future<void> exportAsCsv(
      List<Map<String, dynamic>> transactions, String customerName) async {
    try {
      final StringBuffer csvBuffer = StringBuffer();
      csvBuffer.writeln('Date,Credit,Debit,Balance,Detail');
      for (final transaction in transactions) {
        csvBuffer.writeln(
            '${transaction['date']},${transaction['credit']},${transaction['debit']},${transaction['balance']},${transaction['detail']}');
      }

      final String dir = (await getApplicationDocumentsDirectory()).path;
      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String path = '$dir/${customerName}_Ledger_$timestamp.csv';
      final File file = File(path);
      await file.writeAsString(csvBuffer.toString());

      OpenFile.open(path);
    } catch (e) {
      print('Error exporting CSV: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$customerName Ledger'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchAllTransactions(customerId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No transactions found'));
          } else {
            final transactions = snapshot.data!;
            return Center(
              child: ElevatedButton(
                onPressed: () => _generatePdf(transactions, customerName),
                child: const Text('Generate PDF'),
              ),
            );
          }
        },
      ),
    );
  }
}
