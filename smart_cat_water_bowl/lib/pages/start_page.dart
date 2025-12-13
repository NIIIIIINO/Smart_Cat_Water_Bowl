import 'dart:math';

import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 140),
            const SizedBox(height: 11),
            const Text(
              'Meow Flow',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5C4033),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB1CCBB),
                foregroundColor: const Color(0xFF5C4033),
                padding: const EdgeInsets.symmetric(
                  horizontal: 35,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // โค้งมน
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
