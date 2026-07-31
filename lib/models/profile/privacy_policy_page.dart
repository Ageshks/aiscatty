import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightGreen,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          "Privacy Policy",
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Privacy Policy",
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
              "1. Information We Collect",
              "When you use Aiscatty, we may collect the following information:\n\n"
              "• Personal Information: Name, email address, phone number, and profile picture when you register.\n"
              "• Pet Information: Photos, videos, breed, age, location, and other details about pets you list.\n"
              "• Location Data: Your approximate location to show pets near you.\n"
              "• Device Information: Device model, operating system, and app version for analytics.\n"
              "• Chat Messages: Messages exchanged between users regarding pet adoption.",
            ),

            _section(
              "2. How We Use Your Information",
              "We use the collected information to:\n\n"
              "• Facilitate pet adoption connections between pet owners and adopters.\n"
              "• Show relevant pet listings based on your location.\n"
              "• Enable communication between users through the chat feature.\n"
              "• Send notifications about adoption requests and messages.\n"
              "• Improve our services and user experience.\n"
              "• Ensure platform safety and prevent fraudulent activity.",
            ),

            _section(
              "3. Information Sharing",
              "We do not sell your personal information to third parties. "
              "However, we may share information:\n\n"
              "• With other users as necessary for pet adoption (e.g., your name and contact info when you request adoption).\n"
              "• With service providers who help us operate the platform (e.g., Cloudinary for image hosting, Firebase for backend services).\n"
              "• When required by law or to protect our legal rights.\n"
              "• With your explicit consent.",
            ),

            _section(
              "4. Data Security",
              "We implement reasonable security measures to protect your data, including:\n\n"
              "• Encryption of data in transit using HTTPS.\n"
              "• Secure Firebase authentication.\n"
              "• Regular security assessments.\n\n"
              "However, no method of electronic storage is 100% secure. "
              "We cannot guarantee absolute security of your data.",
            ),

            _section(
              "5. Your Rights",
              "You have the right to:\n\n"
              "• Access your personal data.\n"
              "• Correct inaccurate data.\n"
              "• Delete your account and associated data.\n"
              "• Opt out of promotional communications.\n"
              "• Request a copy of your data.\n\n"
              "To exercise these rights, please contact us through the app.",
            ),

            _section(
              "6. Third-Party Services",
              "Our app uses the following third-party services:\n\n"
              "• Firebase (Google) - Authentication, database, storage, and notifications.\n"
              "• Cloudinary - Image and video hosting.\n"
              "• Google Maps / Geolocator - Location services.\n\n"
              "These services have their own privacy policies governing data handling.",
            ),

            _section(
              "7. Children's Privacy",
              "Our services are not intended for children under 13. "
              "We do not knowingly collect data from children under 13. "
              "If we discover that a child under 13 has provided us with personal data, "
              "we will delete it immediately.",
            ),

            _section(
              "8. Changes to This Policy",
              "We may update this Privacy Policy from time to time. "
              "We will notify you of any changes by posting the new policy on this page "
              "and updating the 'Last updated' date. We encourage you to review this "
              "policy periodically.",
            ),

            _section(
              "9. Contact Us",
              "If you have any questions about this Privacy Policy, "
              "please contact us through the app's support features or email us at "
              "support@aiscatty.app.",
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