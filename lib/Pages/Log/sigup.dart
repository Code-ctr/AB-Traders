import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:abtraders/Pages/Log/auth.dart';
import 'package:abtraders/Components/button.dart';
import 'package:abtraders/Components/shape.dart';
import 'package:abtraders/Components/teztfield.dart';

class Signup extends StatelessWidget {
  final TextEditingController _emailAddress = TextEditingController();
  final TextEditingController _passwd = TextEditingController();
  final TextEditingController _confirmPasswd = TextEditingController();

  Signup({super.key});

  void _showPopup(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close the popup
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _signUpUser(BuildContext context) async {
    String email = _emailAddress.text.trim();
    String password = _passwd.text.trim();
    String confirmPassword = _confirmPasswd.text.trim();

    if (password != confirmPassword) {
      _showPopup(context, "Warning", "Passwords do not match!");
      return;
    }

    try {
      // ✅ Register user
      User? user = await AuthService().signUp(email, password);

      if (user != null) {
        // ✅ Send verification email
        await user.sendEmailVerification();

        _showPopup(
          // ignore: use_build_context_synchronously
          context,
          "Verify Your Email",
          "A verification email has been sent to $email. Please verify before logging in.",
        );
      } else {
        // ignore: use_build_context_synchronously
        _showPopup(context, "Error", "Sign-up failed. Please try again.");
      }
    } catch (e) {
      // ignore: use_build_context_synchronously
      _showPopup(context, "Error", "Sign-up failed: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ShapedS(),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  MyTextField(
                    controller: _emailAddress,
                    hinttext: "Enter Your Email",
                    icon: Icons.email,
                  ),
                  MyTextField(
                    controller: _passwd,
                    hinttext: "Set Password",
                    icon: Icons.lock,
                  ),
                  MyTextField(
                    controller: _confirmPasswd,
                    hinttext: "Confirm Password",
                    icon: Icons.lock,
                  ),
                  SizedBox(height: MediaQuery.of(context).size.height * 0.01),
                  MyButton(
                    onTap: () => _signUpUser(context),
                    text: "Add Account",
                    color: Colors.teal.shade600,
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}
