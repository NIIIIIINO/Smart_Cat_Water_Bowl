import 'dart:math';

import 'package:flutter/material.dart';

class StartPage extends StatelessWidget {
  const StartPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/images/logo.png', width: 200),
                const Positioned(
                  bottom: -15, // ติดลบได้ เพื่อให้ text ลงมาด้านล่างของรูป
                  child: Text(
                    'Meow Flow',
                    style: TextStyle(
                      fontFamily: 'Lobster',
                      fontSize: 37,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5C4033),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),
            ElevatedButton(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/welcome');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB1CCBB),
                foregroundColor: const Color(0xFF5C4033),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8), // โค้งมน
                ),
              ),
              child: const Text(
                'START',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'MontserratAlternates',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
