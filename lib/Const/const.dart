import 'package:flutter/material.dart';

class Const {
  static const LinearGradient backgroundColor = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF173857), Color(0xFF000000)],
    stops: [0.0, 0.88], // 173857 color stops at 78%
  );
  static const LinearGradient heroBackgrounf = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF212121), Color(0xFF0069A8)],
    stops: [0.1, 0.99], // 173857 color stops at 78%
  );

  static const String secret =
      // 'MzcxMTYxNTczMjk2NzIwMDMxOTE4MTQwNjAxOTg3NjY3MDM3NzY=';
      'NDc3ODcwNDE5MjQwODkzODM1MDU0NDc3MzY2MjMzNjU2MDgxODk=';

  static const String merchant_id = '1234448';
}