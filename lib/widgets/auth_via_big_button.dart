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
        opacity: 0.50,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.85,
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
