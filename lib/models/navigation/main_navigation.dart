import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../home/home_page.dart';
import '../chat/chat_page.dart';
import '../profile/profile_page.dart';
import '../../utils/app_colors.dart';

class MainNavigation extends StatelessWidget {
  MainNavigation({super.key});

  final RxInt index = 0.obs;

  final pages = [
     HomePage(),
     ChatPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(() => Scaffold(
          body: pages[index.value],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index.value,
            onTap: (i) => index.value = i,
            selectedItemColor: AppColors.primary,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.chat), label: "Chat"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
            ],
          ),
        ));
  }
}