import 'package:flutter/material.dart';

class WelComePage extends StatelessWidget {
  const WelComePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/logo.png',
                width: 170, // ปรับได้ตามชอบ
                fit: BoxFit.contain,
              ),

              const SizedBox(height: 14),

              const Text(
                'MeowFlow',
                style: TextStyle(
                  fontFamily: 'Lobster',
                  fontSize: 34,
                  color: Color(0xFF5C4033),
                ),
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFD5C9),
                    foregroundColor: const Color(0xFF5C4033),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF5C4033)),
                    ),
                    textStyle: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'MontserratAlternates',
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: const Text('LOG IN'),
                ),
              ),

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, '/register'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBFD5C9),
                    foregroundColor: const Color(0xFF5C4033),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: const BorderSide(color: Color(0xFF5C4033)),
                    ),
                    textStyle: const TextStyle(
                      fontFamily: 'MontserratAlternates',
                      fontWeight: FontWeight.w600, // SemiBold 600
                      fontSize: 16,
                      letterSpacing: 1.2,
                    ),
                  ),
                  child: const Text('SIGN IN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
