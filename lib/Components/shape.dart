import 'package:flutter/material.dart';

class ShapedS extends StatelessWidget {
  const ShapedS({super.key});

  @override
  Widget build(BuildContext context) {
    return ClipPath(
      clipper: UShapeClipper(),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5, // Adjust as needed
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.teal.shade600, // Top Green Color
              Colors.teal.shade600, // Keep same for uniformity
            ],
          ),
        ),
      ),
    );
  }
}

class UShapeClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 10); // Start from left-bottom
    path.quadraticBezierTo(
        size.width / 2, size.height + 15, size.width, size.height - 10);
    path.lineTo(size.width, 0); // Top-right corner
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
