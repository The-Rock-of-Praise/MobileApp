import 'package:flutter/material.dart';

class AuthTextfeildContainer extends StatefulWidget {
  final TextEditingController? controller;
  final IconData icon;
  final String hintText;
  final bool isPassword;

  const AuthTextfeildContainer({
    super.key,
    required this.icon,
    required this.hintText,
    required this.controller,
    this.isPassword = false,
  });

  @override
  State<AuthTextfeildContainer> createState() => _AuthTextfeildContainerState();
}

class _AuthTextfeildContainerState extends State<AuthTextfeildContainer> {
  bool _obscureText = true;

  @override
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: MediaQuery.of(context).size.width * 0.85,
          height: 62,
          // මෙන්න මෙතන තමයි style එක වෙනස් කළේ
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1), // Phone input එකේ වගේම opacity එක
            borderRadius: BorderRadius.circular(15), // Corner radius එක 15 කළා
            border: Border.all(
              color: Colors.white.withOpacity(0.2), // සිහින් සුදු පාට border එක
              width: 1,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscureText : false,
            // Text එක සුදු පාටින් පෙනෙන්න මෙන්න මේක දැම්මා
            style: const TextStyle(color: Colors.white), 
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(widget.icon, color: Colors.white.withOpacity(0.6)),
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscureText ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white.withOpacity(0.6),
                      ),
                      onPressed: () {
                        setState(() {
                          _obscureText = !_obscureText;
                        });
                      },
                    )
                  : null,
              hintText: widget.hintText,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 18,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
