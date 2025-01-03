import 'package:flutter/material.dart';

class MyTextField extends StatelessWidget {
  final controller;
  final String hintText;
  final bool obscureText;

  const MyTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.obscureText,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      child: TextField(
        style: TextStyle(
          fontFamily: 'Poppins-Medium',
        ),
        controller: controller,
        obscureText: obscureText,
        decoration: InputDecoration(
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade700),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey.shade400),
            ),
            fillColor: const Color.fromARGB(255, 255, 255, 255),
            filled: true,
            labelText: hintText,
            hintStyle: TextStyle(color: Colors.grey[500])),
      ),
    );
  }
}
