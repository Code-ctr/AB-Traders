import 'package:flutter/material.dart';

// ignore: must_be_immutable
class MyTextField extends StatelessWidget {
  TextEditingController controller = TextEditingController();
  final String hinttext;
  final IconData? icon;
  final double? width;
  final double? height;
  final bool? isNumeric;
  MyTextField({
    super.key,
    required this.controller,
    required this.hinttext,
    this.icon,
    this.width,
    this.height,
    this.isNumeric = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: TextField(
          minLines: 1,
          maxLines: 10,
          controller: controller,
          autofocus: false,
          obscureText: false,
          style: const TextStyle(color: Colors.black),
          keyboardType: isNumeric! ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
              focusColor: const Color.fromARGB(255, 19, 12, 20),
              hintText: hinttext,
              prefixIcon: (icon != null
                  ? Icon(
                      icon,
                    )
                  : null),
              enabledBorder: OutlineInputBorder(
                borderSide:
                    const BorderSide(color: Color.fromARGB(255, 26, 23, 35)),
                borderRadius: BorderRadius.circular(8),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              )),
        ),
      ),
    );
  }
}
