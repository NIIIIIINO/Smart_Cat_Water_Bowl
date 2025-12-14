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
        // สามารถเก็บข้อมูลผู้ใช้จาก `doc.data()` ไว้ใน state
        // หรือส่งต่อไปยังหน้าอื่นตามต้องการ
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
    final double toolbarH = 300; // <-- ปรับได้
    final double imageH = 200; // <-- ปรับขนาดรูป

    // ทำให้รูปอยู่กึ่งกลางแนวตั้งใน AppBar
    final double verticalPadding = (toolbarH - imageH) / 2;

    // คุมช่องว่างระหว่างรูปกับส่วน body (0.0 = ชิดสุด)
    final double bodyTopSpacingFactor = 0.0; // ปรับค่านี้ (0.0 - 1.0)
    final double bodyTopSpacing = verticalPadding * bodyTopSpacingFactor;

    return Scaffold(
      backgroundColor: Colors.transparent,

      // ================= APP BAR =================
      appBar: AppBar(
        toolbarHeight: toolbarH,
        backgroundColor: const Color(0xFFFAF3DD),
        elevation: 0,
        surfaceTintColor: Colors.transparent,

        // ปิดปุ่มย้อนกลับไว้ก่อน
        // leading: TextButton(
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

        // แสดงเฉพาะรูป และจัดให้รูปอยู่กึ่งกลางแนวตั้งของ AppBar
        title: SizedBox(
          height: toolbarH,
          child: Center(
            child: Image.asset('assets/images/finfin.png', height: imageH),
          ),
        ),
      ),

      // ================= BODY =================
      body: Column(
        children: [
          SizedBox(height: bodyTopSpacing),

          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),

                // =====================================================
                // 🔴 ปิดแถบสีขาว (White Card) ไว้ก่อน
                // ถ้าจะเปิดกลับมา ให้เอา // ออกทั้งบล็อก Container ด้านล่าง
                // =====================================================

                // child: Container(
                //   width: double.infinity,
                //   padding: const EdgeInsets.all(24),
                //   decoration: BoxDecoration(
                //     color: Colors.white,
                //     borderRadius: const BorderRadius.vertical(
                //       top: Radius.circular(32),
                //     ),
                //     boxShadow: [
                //       BoxShadow(
                //         color: Colors.black.withOpacity(0.08),
                //         blurRadius: 20,
                //         offset: const Offset(0, -4),
                //       ),
                //     ],
                //   ),
                //   child: SingleChildScrollView(
                //     child: Column(
                //       children: [

                // ✅ ตอนนี้ใช้เนื้อหาด้านในโดยตรง (ไม่มีแถบสีขาว)
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

                //       ],
                //     ),
                //   ),
                // ),
                // =====================================================
                // 🔴 จบส่วนแถบสีขาว
                // =====================================================
              ),
            ),
          ),
        ],
      ),
    );
  }
}
