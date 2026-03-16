import 'package:flutter/material.dart';
import 'package:lyrics/Const/const.dart';

class MainBAckgound extends StatelessWidget {
  Widget child;
  MainBAckgound({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: BoxDecoration(gradient: Const.backgroundColor),
      child: child,
    );
  }
}
