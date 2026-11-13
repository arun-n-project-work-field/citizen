import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AppDialogs {
  AppDialogs._();

  static const Color red = Color(0xFFC62828);
  static const Color darkRed = Color(0xFF991B1B);
  static const Color yellow = Color(0xFFFFD600);
  static const Color background = Color(0xFFFFF3D6);
  static const Color grey = Color(0xFF777777);

  // --------------------------------------------------
  // SUCCESS DIALOG
  // --------------------------------------------------

  static Future<void> showSuccess(
    String message, {
    String title = 'Successfully Completed!',
    String buttonText = 'CONTINUE',
  }) async {
    await _showDialog(
      title: title,
      message: message,
      icon: Icons.check_circle_rounded,
      buttonText: buttonText,
      canDismiss: false,
    );
  }

  // --------------------------------------------------
  // ERROR DIALOG
  // --------------------------------------------------

  static Future<void> showError(
    String message, {
    String title = 'Something Went Wrong',
    String buttonText = 'OK',
  }) async {
    await _showDialog(
      title: title,
      message: message,
      icon: Icons.error_rounded,
      buttonText: buttonText,
    );
  }

  // --------------------------------------------------
  // WARNING DIALOG
  // --------------------------------------------------

  static Future<void> showWarning(
    String message, {
    String title = 'Please Check',
    String buttonText = 'OK',
  }) async {
    await _showDialog(
      title: title,
      message: message,
      icon: Icons.warning_rounded,
      buttonText: buttonText,
    );
  }

  // --------------------------------------------------
  // INTERNET REQUIRED DIALOG
  // --------------------------------------------------

  static Future<void> showInternetRequired({
    String message =
        'Your internet connection is not available.\n\n'
        'Please turn on Mobile Data or Wi-Fi to continue.',
    required VoidCallback onRetry,
  }) async {
    await _showDialog(
      title: 'Internet Connection Required',
      message: message,
      icon: Icons.wifi_off_rounded,
      buttonText: 'RETRY',
      onPressed: onRetry,
      canDismiss: false,
    );
  }

  // --------------------------------------------------
  // CONFIRMATION DIALOG
  // --------------------------------------------------

  static Future<bool?> showConfirmation({
    required String title,
    required String message,
    String confirmText = 'YES',
    String cancelText = 'CANCEL',
  }) async {
    return await Get.dialog<bool>(
      Dialog(
        backgroundColor: Colors.white,
        elevation: 12,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _iconContainer(Icons.help_rounded),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.start,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: darkRed,
                ),
              ),
              const SizedBox(height: 11),
              Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: grey, height: 1.5),
              ),
              const SizedBox(height: 25),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 48,
                      child: OutlinedButton(
                        onPressed: () => Get.back(result: false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: darkRed,
                          side: const BorderSide(color: red),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          cancelText,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _button(
                      text: confirmText,
                      onPressed: () => Get.back(result: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // --------------------------------------------------
  // COMMON DIALOG
  // --------------------------------------------------

  static Future<void> _showDialog({
    required String title,
    required String message,
    required IconData icon,
    required String buttonText,
    VoidCallback? onPressed,
    bool canDismiss = true,
  }) async {
    await Get.dialog<void>(
      PopScope(
        canPop: canDismiss,
        child: Dialog(
          backgroundColor: Colors.white,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _iconContainer(icon),
                const SizedBox(height: 20),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.bold,
                    color: darkRed,
                  ),
                ),
                const SizedBox(height: 11),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    color: grey,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  child: _button(
                    text: buttonText,
                    onPressed: onPressed ?? () => Get.back(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  // --------------------------------------------------
  // ICON
  // --------------------------------------------------

  static Widget _iconContainer(IconData icon) {
    return Container(
      height: 78,
      width: 78,
      decoration: const BoxDecoration(
        color: background,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: red, size: 49),
    );
  }

  // --------------------------------------------------
  // BUTTON
  // --------------------------------------------------

  static Widget _button({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: yellow,
          foregroundColor: darkRed,
          elevation: 0,
          minimumSize: const Size(double.infinity, 52),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            text,
            textAlign: TextAlign.center,
            maxLines: 1,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              letterSpacing: 0.8,
            ),
          ),
        ),
      ),
    );
  }
}
