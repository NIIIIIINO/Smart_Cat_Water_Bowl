import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailC = TextEditingController();
  final TextEditingController _passwordC = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailC.dispose();
    _passwordC.dispose();
    super.dispose();
  }

  Future<void> _signIn() async {
    final email = _emailC.text.trim();
    final password = _passwordC.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('โปรดกรอก Email และ Password')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final uid = cred.user?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
      }

      Navigator.pushReplacementNamed(context, '/home');
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message ?? 'เกิดข้อผิดพลาด')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✅ สำคัญมาก: ต้องโปร่งใส
      backgroundColor: Colors.transparent,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 🐱 รูปแมวด้านบน
                  Image.asset('assets/images/finfin.png', height: 200),

                  const SizedBox(height: 10), // ลดให้ชิด text Login
                  // ===== Title =====
                  const Text(
                    'Login',
                    style: TextStyle(
                      fontFamily: 'Lobster',
                      fontSize: 40,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF5C4033),
                    ),
                  ),

                  const SizedBox(
                    height: 10,
                  ), // ระยะห่างระหว่าง Login และ Welcome Back

                  const Text(
                    'Welcome Back :)',
                    style: TextStyle(
                      fontFamily: 'MontserratAlternates',
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF5C4033),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // ===== Email / Phone =====
                  TextField(
                    controller: _emailC,
                    decoration: InputDecoration(
                      hintText: 'Email / Phone',
                      filled: true,
                      fillColor: Colors.white, // อ่านง่ายบน gradient
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== Password =====
                  TextField(
                    controller: _passwordC,
                    obscureText: true,
                    decoration: InputDecoration(
                      hintText: 'Password',
                      filled: true,
                      fillColor: Colors.white,
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
                      onPressed: _isLoading ? null : _signIn,
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
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Login',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'MontserratAlternates',
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ===== Register =====
                  TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/register');
                    },
                    style: TextButton.styleFrom(
                      textStyle: const TextStyle(
                        fontFamily: 'MontserratAlternates',
                        color: Color.fromARGB(255, 255, 255, 255),
                        decoration: TextDecoration.underline,
                        decorationColor: Color(0xFF5C4033), // สีเส้นใต้
                      ),
                    ),
                    child: const Text('Create an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
