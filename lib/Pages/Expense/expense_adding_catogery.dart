import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddingExpense extends StatefulWidget {
  const AddingExpense({super.key});

  @override
  State<AddingExpense> createState() => _AddingExpenseState();
}

class _AddingExpenseState extends State<AddingExpense> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final TextEditingController _nameController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<Map<String, dynamic>> _categories = [];

  @override
  void initState() {
    super.initState();
    _fetchCategories(); // Fetch categories when the widget is initialized
  }

  // Fetch expense categories from Firestore
  Future<void> _fetchCategories() async {
    try {
      QuerySnapshot querySnapshot =
          await _firestore.collection('expenseCategories').get();
      List<Map<String, dynamic>> categories = [];
      for (var doc in querySnapshot.docs) {
        categories.add({
          'id': doc.id,
          'name': doc['name'],
        });
      }
      setState(() {
        _categories = categories;
      });
    } catch (e) {
      // ignore: avoid_print
      print('Error fetching categories: $e');
    }
  }

  // Add a new expense category
  Future<void> _addCategory() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category name')),
      );
      return;
    }
    User? user = _auth.currentUser;
    try {
      // Add the category to Firestore
      await _firestore.collection('expenseCategories').add({
        'name': _nameController.text,
        'balance': 0,
        'userId': user!.uid,
      });

      // Clear the text field
      _nameController.clear();

      // Refresh the category list
      _fetchCategories();

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category added successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding category: $e')),
      );
    }
  }

  // Delete an expense category
  Future<void> _deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('expenseCategories').doc(categoryId).delete();

      // Refresh the category list
      _fetchCategories();

      // Show success message
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      // Handle errors
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting category: $e')),
      );
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
          Center(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.1,
                  ),
                  MyTextField(
                    controller: _nameController,
                    hinttext: "Expense Category",
                    width: MediaQuery.of(context).size.width * 0.9,
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.01,
                  ),
                  MyButton(
                    onTap: _addCategory,
                    color: Colors.blueGrey.shade300,
                    text: "Add",
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.03,
                  ),
                  Container(
                    height: MediaQuery.of(context).size.height * 0.55,
                    width: MediaQuery.of(context).size.width * 0.9,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.white,
                    ),
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.03,
                          ),
                          ExpenseShowing(
                            categories: _categories,
                            onDelete:
                                _deleteCategory, // Pass the delete function
                          ),
                        ],
                      ),
                    ),
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

class ExpenseShowing extends StatelessWidget {
  final List<Map<String, dynamic>> categories;
  final Function(String) onDelete;

  const ExpenseShowing({
    super.key,
    required this.categories,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var category in categories)
          Container(
            margin: const EdgeInsets.symmetric(vertical: 5),
            height: MediaQuery.of(context).size.height * 0.08,
            width: MediaQuery.of(context).size.width * 0.85,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Colors.blueGrey.shade400,
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Row(
                children: [
                  Text(category['name']), // Display category name
                  const Spacer(),
                  MyButton(
                    onTap: () =>
                        onDelete(category['id']), // Call the delete function
                    icon: Icons.delete,
                    width: MediaQuery.of(context).size.width * 0.1,
                    iconColor: Colors.red,
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
