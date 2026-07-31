import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final authController = Get.put(AuthController());

  // ── Login Controllers ──
  final loginEmailController = TextEditingController();
  final loginPasswordController = TextEditingController();

  // ── Register Controllers ──
  final regNameController = TextEditingController();
  final regEmailController = TextEditingController();
  final regPhoneController = TextEditingController();
  final regPasswordController = TextEditingController();
  final regConfirmPasswordController = TextEditingController();

  // ── Form Keys ──
  final loginFormKey = GlobalKey<FormState>();
  final registerFormKey = GlobalKey<FormState>();

  // ── State ──
  bool isLogin = true;
  bool isLoading = false;

  // ── Show/Hide Password ──
  bool loginPasswordVisible = false;
  bool regPasswordVisible = false;
  bool regConfirmPasswordVisible = false;

  @override
  void dispose() {
    loginEmailController.dispose();
    loginPasswordController.dispose();
    regNameController.dispose();
    regEmailController.dispose();
    regPhoneController.dispose();
    regPasswordController.dispose();
    regConfirmPasswordController.dispose();
    super.dispose();
  }

  // ── Email Validator ──
  String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) {
      return 'Enter a valid email';
    }
    return null;
  }

  // ── Password Validator ──
  String? validatePassword(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  // ── Phone Validator ──
  String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    final phoneRegex = RegExp(r'^\d{10}$');
    if (!phoneRegex.hasMatch(value.trim())) {
      return 'Phone number must be exactly 10 digits';
    }
    return null;
  }

  // ── Handle Login ──
  Future<void> handleLogin() async {
    if (!loginFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    await authController.login(
      loginEmailController.text.trim(),
      loginPasswordController.text,
    );
    setState(() => isLoading = false);
  }

  // ── Handle Register ──
  Future<void> handleRegister() async {
    if (!registerFormKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    await authController.register(
      name: regNameController.text.trim(),
      email: regEmailController.text.trim(),
      phone: regPhoneController.text.trim(),
      password: regPasswordController.text,
    );
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              children: [
                const SizedBox(height: 40),

                // ── Logo ──
                Image.asset(
                  'assets/logo11.png',
                  height: 100,
                ),

                const SizedBox(height: 20),

                // ── Title ──
                Text(
                  isLogin ? "Welcome Back 🐾" : "Create Account 🐾",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 8),

                // ── Subtitle ──
                Text(
                  isLogin ? "Login to continue" : "Register to get started",
                  style: const TextStyle(color: Colors.black54),
                ),

                const SizedBox(height: 32),

                // ── Form Card ──
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: isLogin ? _buildLoginForm() : _buildRegisterForm(),
                ),

                const SizedBox(height: 20),

                // ── Switch Login/Register ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      isLogin
                          ? "Don't have an account?"
                          : "Already have an account?",
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          isLogin = !isLogin;
                        });
                      },
                      child: Text(isLogin ? "Register" : "Login"),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ────────────────────────────────────
  //  LOGIN FORM
  // ────────────────────────────────────
  Widget _buildLoginForm() {
    return Form(
      key: loginFormKey,
      child: Column(
        children: [
          // ── Email ──
          TextFormField(
            controller: loginEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            decoration: InputDecoration(
              hintText: "Enter email",
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ── Password ──
          TextFormField(
            controller: loginPasswordController,
            obscureText: !loginPasswordVisible,
            validator: validatePassword,
            decoration: InputDecoration(
              hintText: "Enter password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  loginPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    loginPasswordVisible = !loginPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Login Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : handleLogin,
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
                      "Login",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // ────────────────────────────────────
  //  REGISTER FORM
  // ────────────────────────────────────
  Widget _buildRegisterForm() {
    return Form(
      key: registerFormKey,
      child: Column(
        children: [
          // ── Full Name ──
          TextFormField(
            controller: regNameController,
            textCapitalization: TextCapitalization.words,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Full Name is required';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Full Name",
              prefixIcon: const Icon(Icons.person),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ── Email Address ──
          TextFormField(
            controller: regEmailController,
            keyboardType: TextInputType.emailAddress,
            validator: validateEmail,
            decoration: InputDecoration(
              hintText: "Email Address",
              prefixIcon: const Icon(Icons.email),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ── Phone Number ──
          TextFormField(
            controller: regPhoneController,
            keyboardType: TextInputType.phone,
            maxLength: 10,
            validator: validatePhone,
            decoration: InputDecoration(
              hintText: "Phone Number",
              prefixIcon: const Icon(Icons.phone),
              counterText: "",
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ── Password ──
          TextFormField(
            controller: regPasswordController,
            obscureText: !regPasswordVisible,
            validator: validatePassword,
            decoration: InputDecoration(
              hintText: "Password",
              prefixIcon: const Icon(Icons.lock),
              suffixIcon: IconButton(
                icon: Icon(
                  regPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    regPasswordVisible = !regPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 15),

          // ── Confirm Password ──
          TextFormField(
            controller: regConfirmPasswordController,
            obscureText: !regConfirmPasswordVisible,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Confirm password is required';
              }
              if (value != regPasswordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
            decoration: InputDecoration(
              hintText: "Confirm Password",
              prefixIcon: const Icon(Icons.lock_outline),
              suffixIcon: IconButton(
                icon: Icon(
                  regConfirmPasswordVisible
                      ? Icons.visibility
                      : Icons.visibility_off,
                ),
                onPressed: () {
                  setState(() {
                    regConfirmPasswordVisible =
                        !regConfirmPasswordVisible;
                  });
                },
              ),
              filled: true,
              fillColor: AppColors.lightGreen.withOpacity(0.3),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Register Button ──
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : handleRegister,
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
                      "Register",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}