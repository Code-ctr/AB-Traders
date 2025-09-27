import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Sign Up (Register) with Email Verification
  Future<User?> signUp(String email, String password) async {
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null) {
        await user.sendEmailVerification(); // Send email verification
      }

      return user;
    } catch (e) {
      print("Sign Up Error: $e");
      return null;
    }
  }

  // Check if email is verified
  bool isEmailVerified() {
    User? user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  // Allow only verified users
  Future<User?> signIn(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;

      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        throw Exception(
            "Email is not verified. A new verification email has been sent.");
      }

      return user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  Future<void> _initializeCashBalance(String userId) async {
    try {
      DocumentSnapshot cashSnapshot = await FirebaseFirestore.instance
          .collection('cashBalances')
          .doc(userId)
          .get();
      if (!cashSnapshot.exists) {
        await FirebaseFirestore.instance
            .collection('cashBalances')
            .doc(userId)
            .set({
          'balance': 0.0, // Initial cash balance
          'userId': userId, // Associate with the user
        });
        print('Cash balance initialized for user: $userId');
      }
    } catch (e) {
      print('Error initializing cash balance: $e');
    }
  }

  // ignore: non_constant_identifier_names
  Future<User?> login_auth(String email, String password) async {
    try {
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      User? user = userCredential.user;
      await _initializeCashBalance(userCredential.user!.uid);
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        throw Exception(
            "Email is not verified. A new verification email has been sent.");
      }

      return user;
    } catch (e) {
      print("Sign In Error: $e");
      return null;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }
}
