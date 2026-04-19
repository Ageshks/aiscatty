import 'package:get/get.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginController extends GetxController {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> login(String email) async {
    try {
      final userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: "123456",
      );

      print("SUCCESS");

      // 🔥 NAVIGATE TO HOME
      Get.offAllNamed('/home');

    } catch (e) {
      // If already registered → login instead
      if (e.toString().contains('email-already-in-use')) {
        await _auth.signInWithEmailAndPassword(
          email: email,
          password: "123456",
        );

        // 🔥 NAVIGATE HERE ALSO
        Get.offAllNamed('/home');
      } else {
        print("ERROR: $e");
        Get.snackbar("Error", e.toString());
      }
    }
  }
}