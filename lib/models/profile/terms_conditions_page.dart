import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class TermsConditionsPage extends StatelessWidget {
  const TermsConditionsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Terms & Conditions",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Terms & Conditions",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.black,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Last updated: July 2026",
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 24),

            _section(
              "1. Acceptance of Terms",
              "By downloading, accessing, or using Aiscatty, you agree to be bound by "
              "these Terms & Conditions. If you do not agree with any part of these terms, "
              "you must not use the application.",
            ),

            _section(
              "2. Description of Service",
              "Aiscatty is a platform that connects pet owners with potential adopters. "
              "The app allows users to:\n\n"
              "• List pets available for adoption.\n"
              "• Browse and search for pets.\n"
              "• Send and receive adoption requests.\n"
              "• Communicate through in-app chat.\n"
              "• Save favorite pet listings.",
            ),

            _section(
              "3. User Accounts",
              "To use our services, you must create an account. You are responsible for:\n\n"
              "• Providing accurate and complete information during registration.\n"
              "• Maintaining the confidentiality of your account credentials.\n"
              "• All activities that occur under your account.\n"
              "• Notifying us immediately of any unauthorized use of your account.\n\n"
              "We reserve the right to suspend or terminate accounts that violate these terms.",
            ),

            _section(
              "4. User Conduct",
              "You agree not to:\n\n"
              "• Post false, misleading, or fraudulent pet listings.\n"
              "• Harass, abuse, or harm other users.\n"
              "• Use the platform for any illegal purpose.\n"
              "• Attempt to circumvent our security measures.\n"
              "• Collect user data without consent.\n"
              "• Post content that is offensive, discriminatory, or inappropriate.\n"
              "• Use automated bots or scripts to interact with the platform.",
            ),

            _section(
              "5. Pet Listings",
              "When listing a pet for adoption:\n\n"
              "• You confirm that you are the rightful owner or authorized to list the pet.\n"
              "• You must provide accurate information about the pet's health, behavior, and history.\n"
              "• You agree to respond to adoption requests in a timely manner.\n"
              "• You understand that Aiscatty is a platform only and does not facilitate the actual adoption process.\n"
              "• You are responsible for the welfare of the pet until adoption is finalized.",
            ),

            _section(
              "6. Adoption Process",
              "Aiscatty facilitates connections between pet owners and adopters but:\n\n"
              "• We do not verify the accuracy of pet listings or user information.\n"
              "• We are not responsible for the outcome of any adoption.\n"
              "• Users are responsible for conducting their own due diligence.\n"
              "• We recommend meeting the pet in person before finalizing adoption.\n"
              "• Any adoption agreement is solely between the pet owner and adopter.",
            ),

            _section(
              "7. Intellectual Property",
              "The Aiscatty app, including its design, logo, and content, is owned by "
              "Aiscatty and protected by copyright and other intellectual property laws. "
              "You may not reproduce, distribute, or create derivative works without our permission.",
            ),

            _section(
              "8. Limitation of Liability",
              "Aiscatty is provided 'as is' without warranties of any kind. "
              "We shall not be liable for:\n\n"
              "• Any direct, indirect, or consequential damages arising from app usage.\n"
              "• Disputes between users regarding pet adoption.\n"
              "• Technical issues, downtime, or data loss.\n"
              "• The actions or conduct of other users.\n\n"
              "Your use of the app is at your own risk.",
            ),

            _section(
              "9. Termination",
              "We may terminate or suspend your account at any time, without prior notice, "
              "for conduct that we believe violates these terms or is harmful to other users, "
              "us, or third parties. Upon termination, your right to use the app will immediately cease.",
            ),

            _section(
              "10. Changes to Terms",
              "We reserve the right to modify these terms at any time. "
              "We will notify users of material changes through the app or via email. "
              "Continued use of the app after changes constitutes acceptance of the new terms.",
            ),

            _section(
              "11. Governing Law",
              "These terms shall be governed by and construed in accordance with the laws of "
              "India. Any disputes arising from these terms shall be subject to the exclusive "
              "jurisdiction of the courts in Kerala, India.",
            ),

            _section(
              "12. Contact Information",
              "For questions about these Terms & Conditions, please contact us at:\n\n"
              "Email: support@aiscatty.app\n"
              "Or through the in-app support feature.",
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _section(String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: const TextStyle(
              fontSize: 14,
              color: Colors.black87,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}