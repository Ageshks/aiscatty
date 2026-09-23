import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../utils/app_colors.dart';
import '../../widgets/google_logo.dart';
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
  bool googleLoading = false;

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

  // ── Handle Google Sign-In ──
  Future<void> handleGoogleSignIn() async {
    if (googleLoading || isLoading) return;

    FocusScope.of(context).unfocus();
    setState(() => googleLoading = true);

    await authController.signInWithGoogle();

    // The controller navigates away on success, so guard the rebuild.
    if (mounted) {
      setState(() => googleLoading = false);
    }
  }

  // ── Handle Forgot Password ──
  Future<void> handleForgotPassword() async {
    // Pre-fill with whatever the user already typed in the email field.
    final emailController = TextEditingController(
      text: loginEmailController.text.trim(),
    );
    bool sending = false;
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> sendResetEmail() async {
              final email = emailController.text.trim();

              if (validateEmail(email) != null) {
                setDialogState(() => errorText = "Please enter a valid email");
                return;
              }

              setDialogState(() {
                sending = true;
                errorText = null;
              });

              final sent = await authController.resetPassword(email);

              if (!dialogContext.mounted) return;

              if (sent) {
                Navigator.of(dialogContext).pop();
                Get.snackbar(
                  "Email sent 📧",
                  "A password reset link was sent to $email",
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 4),
                );
              } else {
                // Keep the dialog open so the user can correct the email.
                setDialogState(() => sending = false);
              }
            }

            return AlertDialog(
              backgroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
              actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              title: const Text(
                "Reset Password 🔑",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Enter your registered email and we'll send you a link to "
                    "reset your password.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: emailController,
                    enabled: !sending,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => sendResetEmail(),
                    decoration: InputDecoration(
                      hintText: "Enter email",
                      prefixIcon: const Icon(Icons.email_outlined),
                      errorText: errorText,
                      filled: true,
                      fillColor: AppColors.lightGreen.withValues(alpha: 0.3),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: sending
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.black.withValues(alpha: 0.5),
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: sending ? null : sendResetEmail,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: sending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          "Send Link",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    );

    emailController.dispose();
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

          const SizedBox(height: 6),

          // ── Forgot Password ──
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: isLoading ? null : handleForgotPassword,
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.blue,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

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

          // ── Google Sign-In ──
          _buildGoogleAuthSection(),
        ],
      ),
    );
  }

  // ────────────────────────────────────
  //  GOOGLE SIGN-IN SECTION
  // ────────────────────────────────────
  Widget _buildGoogleAuthSection() {
    final bool busy = googleLoading || isLoading;

    return Column(
      children: [
        const SizedBox(height: 20),

        // ── Divider ──
        Row(
          children: [
            const Expanded(child: Divider(color: Colors.black12)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                "or continue with",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.black.withValues(alpha: 0.45),
                ),
              ),
            ),
            const Expanded(child: Divider(color: Colors.black12)),
          ],
        ),

        const SizedBox(height: 16),

        // ── Google Button ──
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: busy ? null : handleGoogleSignIn,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(vertical: 13),
              side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (googleLoading)
                  const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  const GoogleLogo(size: 20),
                const SizedBox(width: 12),
                Text(
                  googleLoading ? "Signing in..." : "Continue with Google",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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

          // ── Google Sign-In ──
          _buildGoogleAuthSection(),
        ],
      ),
    );
  }
}