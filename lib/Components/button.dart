import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  final VoidCallback onTap;
  final String? text;
  final IconData? icon;
  final Image? image;
  final double? width;
  final double? radius;
  final Color? color;
  final Color? iconColor;
  final double? height;
  final double? size;
  final bool? shadow;
  final bool? imagecustomized;
  final bool? isDisabled;
  const MyButton({
    super.key,
    required this.onTap,
    this.color,
    this.iconColor,
    this.text,
    this.icon,
    this.image,
    this.width,
    this.height,
    this.size,
    this.radius,
    this.shadow = false,
    this.imagecustomized = false,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isDisabled! ? null : onTap,
      child: Container(
        width: width ?? 200,
        height: height ?? 50,
        decoration: BoxDecoration(
            color: color ?? Colors.transparent,
            borderRadius: BorderRadius.circular(radius ?? 10),
            boxShadow: shadow!
                ? [
                    const BoxShadow(
                        blurRadius: 10,
                        offset: Offset(10, 10),
                        color: Colors.lightBlue)
                  ]
                : []),
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                color: iconColor ?? Colors.grey.shade600,
                size: size,
              ),
            ] else if (image != null) ...[
              if (imagecustomized == true) ...[
                ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(15),
                      topRight: Radius.circular(15),
                      bottomLeft: Radius.circular(15),
                      bottomRight: Radius.circular(15),
                    ),
                    child: image!)
              ] else ...[
                SizedBox(
                    height: MediaQuery.of(context).size.height * 0.15,
                    width: MediaQuery.of(context).size.width * 0.15,
                    child: image!),
              ]
            ],
            if (text != null)
              Text(
                text!,
                style: const TextStyle(color: Colors.black),
              ),
          ],
        ),
      ),
    );
  }
}
