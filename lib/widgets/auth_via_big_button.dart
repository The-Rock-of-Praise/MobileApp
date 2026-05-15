import 'package:flutter/material.dart';

class AuthViaBigButton extends StatelessWidget {
  final String name;
  final String path;
  final VoidCallback ontap;
  final bool isLoading;

  const AuthViaBigButton({
    super.key,
    required this.name,
    required this.path,
    required this.ontap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : ontap,
      child: Opacity(
        opacity: 1.0,
        child: Container(
          width: double.infinity,
          height: 62,
          decoration: ShapeDecoration(
            color: const Color(0xFFD9D9D9),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Center(
            child:
                isLoading
                    ? const CircularProgressIndicator()
                    : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(path, width: 24, height: 24),
                        const SizedBox(width: 10),
                        Text(
                          name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
          ),
        ),
      ),
    );
  }
}
