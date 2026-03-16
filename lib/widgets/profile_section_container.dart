import 'package:flutter/material.dart';

class ProfileSectionContainer extends StatelessWidget {
  Widget child;
  ProfileSectionContainer({super.key, required this.child});
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          height: 346,
          decoration: ShapeDecoration(
            color: const Color(0xFF313439),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(55),
                bottomRight: Radius.circular(55),
              ),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}
