import 'package:flutter/material.dart';

class AuthViaButtons extends StatelessWidget {
  String path;
  String name;
  AuthViaButtons({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Opacity(
          opacity: 0.50,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.425,
            height: 54,
            decoration: ShapeDecoration(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(path),
                const SizedBox(width: 22),
                Text(
                  name,
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
