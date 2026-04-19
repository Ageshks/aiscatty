import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  final String fullText = "Pet Adoption 🐾";
  String displayedText = "";

  @override
  void initState() {
    super.initState();

    _startTypingAnimation();

    Future.delayed(const Duration(seconds: 3), () {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        Get.offAllNamed('/home');
      } else {
        Get.offAllNamed('/login');
      }
    });
  }

  void _startTypingAnimation() {
    int index = 0;

    Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (index < fullText.length) {
        setState(() {
          displayedText += fullText[index];
        });
        index++;
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min, // 🔥 FIX ALIGNMENT
            children: [

              /// 🖼 LOGO (PNG BLEND FIX)
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white, // ensures blend
                  shape: BoxShape.circle,
                ),
                child: Image.asset(
                  'assets/logo.png',
                  height: 120,
                  fit: BoxFit.contain,
                ),
              ),

              const SizedBox(height: 30),

              /// ✍️ TYPEWRITER TEXT
              Text(
                displayedText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),

              const SizedBox(height: 12),

              /// ✨ TAGLINE
              const Text(
                "Find your perfect companion 🐶",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}