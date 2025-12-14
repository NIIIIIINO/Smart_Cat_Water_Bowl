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
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .get();
        // สามารถเก็บข้อมูลผู้ใช้จาก `doc.data()` ไว้ใน state หรือส่งต่อไปยังหน้าอื่นตามต้องการ
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
    // ปรับค่านี้เพื่อเปลี่ยนความสูงของพื้นที่ด้านบน (AppBar)
    // - `toolbarH` คือความสูงรวมของ AppBar
    // - `imageH` คือความสูงของรูปแมว
    // ให้ช่องว่างบน/ล่างเท่ากันเมื่อใช้ Center ภายใน SizedBox
    final double toolbarH =
        300; // <-- ปรับตรงนี้ถ้าต้องการพื้นที่บนมากขึ้น/น้อยลง
    final double imageH = 200; // <-- ปรับขนาดรูปแมวที่ต้องการ
    // คำนวณระยะห่างบนของ body เพื่อให้ช่องว่างระหว่างรูปกับแถบสีขาวควบคุมได้ง่าย
    // ลดค่า `bodyTopSpacingFactor` ให้ช่องว่างแคบลง (0.0 = ชิดสุด, 1.0 = padding ปกติ)
    final double verticalPadding = (toolbarH - imageH) / 2;
    final double bodyTopSpacingFactor = 0.0; // ปรับค่านี้ (0.0 - 1.0)
    final double bodyTopSpacing = verticalPadding * bodyTopSpacingFactor;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF3DD),
      appBar: AppBar(
        toolbarHeight: toolbarH,
        backgroundColor: const Color(0xFFFAF3DD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        // เก็บโค้ดปุ่ม `<<` ไว้เป็นคอมเมนต์ เผื่อจะเปิดกลับมาใช้ภายหลัง
        // TextButton(
        //   onPressed: () {
        //     Navigator.pushReplacementNamed(context, '/welcome');
        //   },
        //   child: const Text(
        //     '<<',
        //     style: TextStyle(
        //       fontFamily: 'MontserratAlternates',
        //       fontSize: 25,
        //       fontWeight: FontWeight.w700,
        //       color: Color(0xFF5C4033),
        //     ),
        //   ),
        // ),
        leading: null,
        centerTitle: true,
        // แสดงเฉพาะรูปและจัดให้รูปอยู่กึ่งกลางแนวตั้งของ AppBar
        title: SizedBox(
          height: toolbarH,
          child: Center(
            child: Image.asset('assets/images/finfin.png', height: imageH),
          ),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: bodyTopSpacing),
          Expanded(
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
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
                    TextField(
                      controller: _emailC,
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
                    TextField(
                      controller: _passwordC,
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
