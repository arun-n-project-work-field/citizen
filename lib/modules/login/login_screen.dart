
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'login_controller.dart';

class LoginColors {
  static const red = Color(0xFFC62828);
  static const darkRed = Color(0xFF991B1B);
  static const yellow = Color(0xFFFFD600);
  static const background = Color(0xFFFFF3D6);
  static const text = Color(0xFF292929);
  static const grey = Color(0xFF777777);
  static const border = Color(0xFFE5DED3);
}

class LoginScreen extends GetView<LoginController> {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: LoginColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  22,
                  28,
                  22,
                  28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Welcome Back ! \n Login',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: LoginColors.text,
                      ),
                    ),

                    const SizedBox(height: 7),

                    const Text(
                      'Login to Your Account to Access the Karnataka Citizen Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: LoginColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 30),

                    // MOBILE NUMBER FIELD
                    _buildMobileField(),

                    // REGISTRATION CHECK STATUS
                    _buildRegistrationStatus(),

                    // GET OTP BUTTON
                    _buildOtpButtonSection(),

                    // OTP SECTION
                    Obx(
                      () => controller.isOtpSent.value
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: 25,
                              ),
                              child: _buildOtpSection(),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // LOGIN BUTTON
                    Obx(
                      () => controller.showLoginButton
                          ? Padding(
                              padding: const EdgeInsets.only(
                                top: 28,
                              ),
                              child: _buildLoginButton(),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 30),

                    // REGISTRATION FOOTER
                    _buildRegistrationFooter(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // HEADER
  // ==========================================================

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        24,
        30,
        24,
        35,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Color(0xFFFFD600),
            Color(0xFFFFD600),
            Color(0xFFB71C1C),
            Color(0xFFC62828),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(35),
          bottomRight: Radius.circular(35),
        ),
      ),
      child: Column(
        children: [
          Container(
            height: 85,
            width: 85,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: LoginColors.yellow,
                width: 4,
              ),
            ),
            child: const Center(
              child: Text(
                'ನ',
                style: TextStyle(
                  fontSize: 43,
                  fontWeight: FontWeight.bold,
                  color: LoginColors.red,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'NAMMA ',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 1.3,
                ),
              ),

              const Text(
                'KARNATAKA',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: Colors.yellow,
                  letterSpacing: 1.3,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Your State. Your Services. Your Karnataka.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // MOBILE NUMBER FIELD
  // ==========================================================

  Widget _buildMobileField() {
    return Obx(
      () => _inputField(
        label: 'Mobile Number',
        requiredField: true,
        hint: 'Enter 10-digit mobile number',
        icon: Icons.phone_android_rounded,
        textController: controller.mobileController,
        error: controller.mobileError.value,
        onChanged: controller.onMobileChanged,
        keyboardType: TextInputType.phone,
        maxLength: 10,
        prefix: const Padding(
          padding: EdgeInsets.only(
            left: 13,
            right: 8,
          ),
          child: Text(
            '+91',
            style: TextStyle(
              color: LoginColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // REGISTRATION STATUS
  // ==========================================================

  Widget _buildRegistrationStatus() {
    return Obx(() {
      if (!controller.isMobileValid) {
        return const SizedBox.shrink();
      }

      if (controller.isCheckingRegistration.value) {
        return const Padding(
          padding: EdgeInsets.only(top: 14),
          child: Row(
            children: [
              SizedBox(
                height: 17,
                width: 17,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: LoginColors.red,
                ),
              ),

              SizedBox(width: 10),

              Expanded(
                child: Text(
                  'Checking registered mobile number...',
                  style: TextStyle(
                    color: LoginColors.grey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.registrationCheckCompleted.value &&
          controller.isRegisteredMobile.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 18,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  controller.registrationMessage.value,
                  style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.registrationCheckCompleted.value &&
          !controller.isRegisteredMobile.value) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.error_outline,
                color: LoginColors.red,
                size: 18,
              ),

              const SizedBox(width: 7),

              Expanded(
                child: Text(
                  controller.registrationMessage.value,
                  style: const TextStyle(
                    color: LoginColors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        );
      }

      if (controller.registrationMessage.value.isNotEmpty) {
        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Text(
            controller.registrationMessage.value,
            style: const TextStyle(
              color: LoginColors.red,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
      }

      return const SizedBox.shrink();
    });
  }

  // ==========================================================
  // GET OTP BUTTON SECTION
  // ==========================================================

  Widget _buildOtpButtonSection() {
    return Obx(() {
      if (!controller.registrationCheckCompleted.value ||
          !controller.isRegisteredMobile.value) {
        return const SizedBox.shrink();
      }

      return Padding(
        padding: const EdgeInsets.only(top: 18),
        child: _buildOtpButton(),
      );
    });
  }

  // ==========================================================
  // GET OTP BUTTON
  // ==========================================================

  Widget _buildOtpButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 50,
        child: ElevatedButton(
          onPressed: controller.canSendOtp
              ? controller.sendOtp
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: LoginColors.yellow,
            disabledBackgroundColor: Colors.grey.shade400,
            foregroundColor: LoginColors.darkRed,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isSendingOtp.value
              ? const SizedBox(
                  height: 21,
                  width: 21,
                  child: CircularProgressIndicator(
                    color: LoginColors.darkRed,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  controller.isOtpSent.value
                      ? 'RESEND OTP'
                      : 'GET OTP',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  // ==========================================================
  // OTP SECTION
  // ==========================================================

  Widget _buildOtpSection() {
    return Obx(
      () => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Enter OTP',
                style: TextStyle(
                  color: LoginColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),

              GestureDetector(
                onTap: controller.resendSeconds.value == 0 &&
                        !controller.isSendingOtp.value
                    ? controller.resendOtp
                    : null,
                child: Text(
                  controller.resendSeconds.value > 0
                      ? 'Resend in ${controller.resendSeconds.value}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: controller.resendSeconds.value > 0
                        ? LoginColors.grey
                        : LoginColors.darkRed,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          _buildOtpBoxes(
            controller.otp.value,
            controller.onOtpChanged,
            controller.otpController,
          ),

          // OTP VALIDATION MESSAGE
          if (controller.otpError.value.isNotEmpty)
            _errorText(controller.otpError.value),
        ],
      ),
    );
  }

  // ==========================================================
  // LOGIN BUTTON
  // ==========================================================

  Widget _buildLoginButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 53,
        child: ElevatedButton(
          onPressed: controller.canLogin
              ? controller.login
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: LoginColors.yellow,
            disabledBackgroundColor: Colors.grey.shade300,
            foregroundColor: LoginColors.darkRed,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 2,
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: LoginColors.darkRed,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'LOGIN',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: 1,
                  ),
                ),
        ),
      ),
    );
  }

  // ==========================================================
  // REGISTRATION FOOTER
  // ==========================================================

  Widget _buildRegistrationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'New User ? ',
          style: TextStyle(
            color: LoginColors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),

        GestureDetector(
          onTap: controller.goToRegistration,
          child: const Text(
            'Register Here',
            style: TextStyle(
              color: LoginColors.red,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // COMMON INPUT FIELD
  // ==========================================================

  Widget _inputField({
    required String label,
    required bool requiredField,
    required String hint,
    required IconData icon,
    required TextEditingController textController,
    required String error,
    required ValueChanged<String> onChanged,
    required TextInputType keyboardType,
    int? maxLength,
    Widget? prefix,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel(label, requiredField),

        const SizedBox(height: 8),

        TextField(
          controller: textController,
          onChanged: onChanged,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: maxLength != null
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ]
              : null,
          style: const TextStyle(
            color: LoginColors.text,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: LoginColors.grey,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: LoginColors.red,
            ),
            prefix: prefix,
            counterText: '',
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 15,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: LoginColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: LoginColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: LoginColors.red,
                width: 1.5,
              ),
            ),
            errorText: error.isEmpty ? null : error,
            errorStyle: const TextStyle(
              color: LoginColors.red,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // FIELD LABEL
  // ==========================================================

  Widget _fieldLabel(String label, bool requiredField) {
    return RichText(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: LoginColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: LoginColors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }

  // ==========================================================
  // FOUR OTP BOXES
  // ==========================================================

  Widget _buildOtpBoxes(
    String value,
    ValueChanged<String> onChanged,
    TextEditingController textController,
  ) {
    return SizedBox(
      height: 56,
      child: Stack(
        children: [
          Row(
            children: List.generate(4, (index) {
              final digit = index < value.length
                  ? value[index]
                  : '';

              return Expanded(
                child: Container(
                  height: 54,
                  margin: EdgeInsets.only(
                    right: index == 3 ? 0 : 12,
                  ),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: LoginColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: LoginColors.text,
                    ),
                  ),
                ),
              );
            }),
          ),

          Positioned.fill(
            child: TextField(
              controller: textController,
              onChanged: onChanged,
              keyboardType: TextInputType.number,
              maxLength: 4,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(4),
              ],
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.transparent,
              ),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                counterText: '',
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // ERROR TEXT
  // ==========================================================

  Widget _errorText(String message) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 7,
        left: 4,
      ),
      child: Text(
        message,
        style: const TextStyle(
          color: LoginColors.red,
          fontSize: 12,
        ),
      ),
    );
  }
}
