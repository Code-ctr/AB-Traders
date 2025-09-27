import 'package:flutter/material.dart';

class ShadowContainers extends StatelessWidget {
  final String itemName;
  final double quantity;
  const ShadowContainers(
      {super.key, required this.itemName, required this.quantity});

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height * 0.08,
        width: MediaQuery.of(context).size.width * 0.825,
        decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(5),
            boxShadow: const [
              BoxShadow(
                  blurRadius: 5, offset: Offset(5, 5), color: Colors.black)
            ]),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Row(
            children: [
              Text(
                itemName,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w500),
              ),
              const Spacer(),
              Text(
                quantity.toString(),
                style: TextStyle(
                    color: Colors.red.shade900,
                    fontSize: 17,
                    fontWeight: FontWeight.w500),
              )
            ],
          ),
        ));
  }
}
