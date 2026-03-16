import 'package:flutter/material.dart';

class AuthButton extends StatelessWidget {
  final Function onTap;
  final String text;
  final bool isLoading;

  const AuthButton({
    super.key,
    required this.text,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: isLoading ? null : () => onTap(),
          child: Container(
            width: MediaQuery.of(context).size.width * 0.85,
            height: 55,
            decoration: ShapeDecoration(
              color: isLoading ? Colors.grey : const Color(0xFFB71C1C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Center(
              child:
                  isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                        text,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
        ),
      ],
    );
  }
}
