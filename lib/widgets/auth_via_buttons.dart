import 'package:flutter/material.dart';

class AuthViaButtons extends StatelessWidget {
  String path;
  String name;
  AuthViaButtons({super.key, required this.path, required this.name});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1.0,
      child: Container(
        width: double.infinity,
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
            Image.asset(path, height: 24), // Added height to keep it consistent
            const SizedBox(width: 12),
            Text(
              name,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
