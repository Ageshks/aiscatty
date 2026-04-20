// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:get/get.dart';
// import '../../utils/app_colors.dart';

// class LoginPage extends StatefulWidget {
//   const LoginPage({super.key});

//   @override
//   State<LoginPage> createState() => _LoginPageState();
// }

// class _LoginPageState extends State<LoginPage> {

//   final emailController = TextEditingController();
//   bool isLoading = false;

//   Future<void> sendLoginLink() async {
//     final email = emailController.text.trim();

//     if (email.isEmpty) {
//       Get.snackbar("Error", "Enter your email");
//       return;
//     }

//     setState(() => isLoading = true);

//     try {
//       final actionCodeSettings = ActionCodeSettings(
//         url: 'https://aiscatty.page.link/login',
//         handleCodeInApp: true,
//         androidPackageName: 'com.example.aiscatty',
//         androidInstallApp: true,
//         androidMinimumVersion: '21',
//       );

//       await FirebaseAuth.instance.sendSignInLinkToEmail(
//         email: email,
//         actionCodeSettings: actionCodeSettings,
//       );

//       Get.snackbar("Success", "Check your email 📩");

//     } catch (e) {
//       Get.snackbar("Error", e.toString());
//     }

//     setState(() => isLoading = false);
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: AppColors.lightGreen,

//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 24),
//           child: Column(
//             children: [

//               const SizedBox(height: 40),

//               /// 🐾 LOGO
//               Image.asset(
//                 'assets/logo.png',
//                 height: 100,
//               ),

//               const SizedBox(height: 20),

//               /// TITLE
//               const Text(
//                 "Welcome to Aiscatty 🐾",
//                 style: TextStyle(
//                   fontSize: 22,
//                   fontWeight: FontWeight.bold,
//                 ),
//               ),

//               const SizedBox(height: 8),

//               /// SUBTITLE
//               const Text(
//                 "Enter your email to continue",
//                 style: TextStyle(
//                   color: Colors.black54,
//                 ),
//               ),

//               const SizedBox(height: 40),

//               /// ✨ PREMIUM CARD
//               Container(
//                 padding: const EdgeInsets.all(20),
//                 decoration: BoxDecoration(
//                   color: Colors.white,
//                   borderRadius: BorderRadius.circular(20),
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.05),
//                       blurRadius: 10,
//                       offset: const Offset(0, 5),
//                     )
//                   ],
//                 ),

//                 child: Column(
//                   children: [

//                     /// 📧 EMAIL FIELD
//                     TextField(
//                       controller: emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         hintText: "Enter your email",
//                         prefixIcon: const Icon(Icons.email),
//                         filled: true,
//                         fillColor: AppColors.lightGreen.withOpacity(0.3),
//                         contentPadding: const EdgeInsets.symmetric(
//                           vertical: 14,
//                           horizontal: 16,
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide.none,
//                         ),
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     /// 🚀 BUTTON
//                     SizedBox(
//                       width: double.infinity,
//                       child: ElevatedButton(
//                         onPressed: isLoading ? null : sendLoginLink,
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: AppColors.primary,
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                         child: isLoading
//                             ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   color: Colors.white,
//                                   strokeWidth: 2,
//                                 ),
//                               )
//                             : const Text(
//                                 "Send Login Link",
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.w600,
//                                 ),
//                               ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),

//               const SizedBox(height: 20),

//               /// 🔐 FOOTER TEXT
//               const Text(
//                 "No password needed. We'll send a secure login link to your email.",
//                 textAlign: TextAlign.center,
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.black45,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {

  final emailController = TextEditingController();
  bool isLoading = false;

  /// 🔥 SIMPLE LOGIN (LOGIN OR REGISTER)
  Future<void> loginOrRegister() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      Get.snackbar("Error", "Enter your email");
      return;
    }

    setState(() => isLoading = true);

    try {
      /// ✅ TRY LOGIN
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: "123456", // 🔥 default password
      );

    } catch (e) {
      /// 🆕 IF USER NOT EXISTS → CREATE
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: "123456",
        );
      } catch (err) {
        Get.snackbar("Error", err.toString());
        setState(() => isLoading = false);
        return;
      }
    }

    setState(() => isLoading = false);

    /// 🚀 GO TO HOME
    Get.offAllNamed('/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [

              const SizedBox(height: 40),

              /// 🐾 LOGO
              Image.asset(
                'assets/logo11.png',
                height: 100,
              ),

              const SizedBox(height: 20),

              /// TITLE
              const Text(
                "Welcome to Aiscatty 🐾",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 8),

              /// SUBTITLE
              const Text(
                "Enter your email to continue",
                style: TextStyle(
                  color: Colors.black54,
                ),
              ),

              const SizedBox(height: 40),

              /// ✨ PREMIUM CARD
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    )
                  ],
                ),

                child: Column(
                  children: [

                    /// 📧 EMAIL FIELD
                    TextField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "Enter your email",
                        prefixIcon: const Icon(Icons.email),
                        filled: true,
                        fillColor: AppColors.lightGreen.withOpacity(0.3),
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                          horizontal: 16,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    /// 🚀 BUTTON
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : loginOrRegister,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Continue",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              /// 🔐 FOOTER TEXT
              const Text(
                "No password needed. Fast and simple login 🚀",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}