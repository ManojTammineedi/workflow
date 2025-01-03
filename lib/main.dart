import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Import Riverpod package
import 'package:google_fonts/google_fonts.dart';
import 'package:workflow/pages/home_page.dart';

void main() {
  runApp(
      const ProviderScope(child: MyApp())); // Wrap your app with ProviderScope
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Workflow Builder',
      theme: ThemeData(
        fontFamily: GoogleFonts.poppins().fontFamily,
        useMaterial3: true,
      ),
      debugShowCheckedModeBanner: false,
      home: HomePage(),
    );
  }
}
