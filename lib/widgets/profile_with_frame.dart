import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class ProfileWithFrame extends StatelessWidget {
  const ProfileWithFrame({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // صورة البروفايل
          const CircleAvatar(
            radius: 40,
            backgroundImage: NetworkImage(
              'https://i.pravatar.cc/300',
            ),
          ),

          // الإطار المتحرك (Lottie)
          Lottie.asset(
            'assets/lottie/frame.json',
            width: 120,
            height: 120,
            repeat: true,
            errorBuilder: (context, error, stackTrace) {
              // في حال لم يجد ملف الـ json بعد
              return Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.amber, width: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
