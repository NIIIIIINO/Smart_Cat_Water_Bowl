import 'package:flutter/material.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF3DD),

      // ================= APP BAR =================
      appBar: AppBar(
        toolbarHeight: 220,
        backgroundColor: const Color(0xFFFAF3DD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/welcome');
          },
        ),

        centerTitle: true,

        title: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/images/logo.png', width: 80),
            const SizedBox(height: 6),
            const Text(
              'Meow Flow',
              style: TextStyle(
                fontFamily: 'Lobster',
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5C4033),
              ),
            ),
          ],
        ),
      ),

      // ================= BODY =================
      body: Column(
        children: [
          // 🔹 ดันจุดเริ่มต้นของแถบขาวลงมาประมาณครึ่งจอ
          SizedBox(height: MediaQuery.of(context).size.height * 0.10),

          // 🔹 แถบขาว (เริ่มกลางจอ → ลงสุดล่าง)
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32), // โค้งเฉพาะด้านบน
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),

              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text(
                      'Login',
                      style: TextStyle(
                        fontFamily: 'MontserratAlternates',
                        fontSize: 27,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF5C4033),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ===== Email / Phone =====
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Email / Phone',
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Password =====
                    TextField(
                      obscureText: true,
                      decoration: InputDecoration(
                        hintText: 'Password',
                        filled: true,
                        fillColor: const Color(0xFFF3F3F3),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ===== Login Button =====
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/home');
                        },
                        style: ElevatedButton.styleFrom(
                          elevation: 0,
                          backgroundColor: const Color(0xFF6C9A8B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          textStyle: const TextStyle(
                            fontFamily: 'MontserratAlternates',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            letterSpacing: 1.2,
                          ),
                        ),
                        child: const Text('LOGIN'),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // ===== Register =====
                    TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/register');
                      },
                      child: const Text(
                        'Create an account',
                        style: TextStyle(
                          fontFamily: 'MontserratAlternates',
                          color: Color(0xFF5C4033),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
