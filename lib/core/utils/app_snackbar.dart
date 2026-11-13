
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppSnackbar {
  // Namma Karnataka theme
  static const Color red = Color(0xFFC62828);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color yellow = Color(0xFFFFD600);
  static const Color cream = Color(0xFFFFF3D6);
  static const Color text = Color(0xFF292929);

  // ==========================================================
  // COMMON SNACKBAR
  // ==========================================================

  static void show({
    required String title,
    required String message,
    IconData icon = Icons.info_outline_rounded,
    Color iconColor = red,
    Duration duration = const Duration(seconds: 3),
  }) {
    Get.snackbar(
      '',
      '',
      titleText: Row(
        children: [
          Icon(
            icon,
            color: iconColor,
            size: 23,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: darkRed,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      messageText: Padding(
        padding: const EdgeInsets.only(left: 33),
        child: Text(
          message,
          style: const TextStyle(
            color: text,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: cream,
      colorText: text,
      borderColor: yellow,
      borderWidth: 1.5,
      borderRadius: 14,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 18),
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 15,
      ),
      duration: duration,
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
      reverseAnimationCurve: Curves.easeIn,
      animationDuration: const Duration(milliseconds: 300),
      boxShadows: [
        BoxShadow(
          color: darkRed.withValues(alpha: 0.12),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  // ==========================================================
  // SUCCESS SNACKBAR
  // ==========================================================

  static void success(
    String message, {
    String title = 'Successfully Completed',
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      iconColor: Colors.green.shade700,
      duration: duration,
    );
  }

  // ==========================================================
  // ERROR SNACKBAR
  // ==========================================================

  static void error(
    String message, {
    String title = 'Something Went Wrong',
    Duration duration = const Duration(seconds: 4),
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      iconColor: red,
      duration: duration,
    );
  }

  // ==========================================================
  // WARNING SNACKBAR
  // ==========================================================

  static void warning(
    String message, {
    String title = 'Please Check',
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.warning_amber_rounded,
      iconColor: darkRed,
      duration: duration,
    );
  }

  // ==========================================================
  // INFORMATION SNACKBAR
  // ==========================================================

  static void info(
    String message, {
    String title = 'Information',
    Duration duration = const Duration(seconds: 3),
  }) {
    show(
      title: title,
      message: message,
      icon: Icons.info_rounded,
      iconColor: darkRed,
      duration: duration,
    );
  }
}
