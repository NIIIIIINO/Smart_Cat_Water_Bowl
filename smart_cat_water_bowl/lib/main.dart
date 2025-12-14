import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:smart_cat_water_bowl/firebase_options.dart';
import 'pages/start_page.dart';
import 'pages/welcome_page.dart';
import 'pages/login_page.dart';
import 'pages/register_page.dart';
import 'pages/home_page.dart';
import 'pages/information_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Cat Water Bowl',

      // ===== Theme ทั้งแอป =====
      theme: ThemeData(
        useMaterial3: true,
        // scaffoldBackgroundColor: const Color(0xFFFAF3DD), // ลบออกเพื่อใช้ gradient แทน
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.black,
          elevation: 0,
          surfaceTintColor: Colors.transparent,

          titleTextStyle: TextStyle(
            fontFamily: 'Lobster',
            fontSize: 26,
            fontWeight: FontWeight.w400,
            color: Colors.black,
            letterSpacing: 1.2,
          ),
        ),

        // ปุ่มหลัก
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C9A8B),
            foregroundColor: Colors.white,
            shape: StadiumBorder(),
          ),
        ),
      ),

      // ===== Builder สำหรับ gradient background =====
      builder: (context, child) => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFAF3DD), // #FAF3DD ข้างบน
              Color(0xFFF7F6A3), // #F7F6A3 ข้างล่าง
            ],
          ),
        ),
        child: child,
      ),

      // ===== Routing =====
      initialRoute: '/start',
      routes: {
        '/start': (context) => const StartPage(),
        '/welcome': (context) => const WelComePage(),
        '/': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/home': (context) => const HomePage(),
        '/info': (context) => const InformationPage(),
      },
    );
  }
}
