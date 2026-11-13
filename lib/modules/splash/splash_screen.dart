import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'splash_controller.dart';

class SplashScreen extends GetView<SplashController> {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      body: Stack(
        fit: StackFit.expand,
        children: [
          // ====================================================
          // FULL SCREEN SPLASH IMAGE
          // ====================================================
          Image.asset('assets/images/splash_image.jpg', fit: BoxFit.cover),

          // ====================================================
          // VERSION CHECK LOADING
          // ====================================================
          Obx(() {
            if (!controller.isCheckingVersion.value) {
              return const SizedBox.shrink();
            }

            return const Positioned(
              bottom: 45,
              left: 0,
              right: 0,

              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Colors.yellow),

                  SizedBox(height: 15),

                  Text(
                    'Checking application version...',
                    textAlign: TextAlign.center,

                    style: TextStyle(
                      color: Colors.yellow,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,

                      shadows: [Shadow(blurRadius: 5, color: Colors.black)],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
