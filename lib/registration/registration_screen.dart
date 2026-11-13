
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'registration_controller.dart';

class RegistrationColors {
  static const red = Color(0xFFC62828);
  static const darkRed = Color(0xFF991B1B);
  static const yellow = Color(0xFFFFD600);
  static const background = Color(0xFFFFF3D6);
  static const text = Color(0xFF292929);
  static const grey = Color(0xFF777777);
  static const border = Color(0xFFE5DED3);
}

class RegistrationScreen extends GetView<RegistrationController> {
  const RegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RegistrationColors.background,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 25, 22, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Create an Account ! \n Register',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.bold,
                        color: RegistrationColors.text,
                      ),
                    ),
                    const SizedBox(height: 7),
                    const Text(
                      'Register Now to access the Karnataka Citizen Services',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: RegistrationColors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 28),

                    _buildNameField(),
                    const SizedBox(height: 17),

                    _buildEmailField(),
                    const SizedBox(height: 17),

                    _buildMobileField(),

                    // GET OTP button appears only when
                    // name, mobile and email validations pass.
                    Obx(
                      () => (controller.isNameValid &&
                              controller.isMobileValid &&
                              controller.isEmailValid)
                          ? Column(
                              children: [
                                const SizedBox(height: 18),
                                _buildOtpButton(),
                              ],
                            )
                          : const SizedBox.shrink(),
                    ),

                    // OTP section appears after OTP is sent.
                    Obx(
                      () => controller.isOtpSent.value
                          ? Padding(
                              padding: const EdgeInsets.only(top: 25),
                              child: _buildOtpSection(),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Register button appears only after
                    // successful OTP verification.
                    Obx(
                      () => controller.showRegisterButton
                          ? Padding(
                              padding: const EdgeInsets.only(top: 28),
                              child: _buildRegisterButton(),
                            )
                          : const SizedBox.shrink(),
                    ),

                    const SizedBox(height: 30),
                    _buildLoginFooter(),
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
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 35),
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
                color: RegistrationColors.yellow,
                width: 4,
              ),
            ),
            child: const Center(
              child: Text(
                'ನ',
                style: TextStyle(
                  fontSize: 43,
                  fontWeight: FontWeight.bold,
                  color: RegistrationColors.red,
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
  // NAME FIELD
  // ==========================================================

  Widget _buildNameField() {
    return Obx(
      () => _inputField(
        label: 'Full Name',
        requiredField: true,
        hint: 'Enter your full name',
        icon: Icons.person_outline_rounded,
        textController: controller.usernameController,
        error: controller.usernameError.value,
        onChanged: controller.onNameChanged,
        keyboardType: TextInputType.name,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  // ==========================================================
  // EMAIL FIELD
  // ==========================================================

  Widget _buildEmailField() {
    return Obx(
      () => _inputField(
        label: 'Email ID (Optional)',
        requiredField: false,
        hint: 'Enter your email address',
        icon: Icons.email_outlined,
        textController: controller.emailController,
        error: controller.emailError.value,
        onChanged: controller.onEmailChanged,
        keyboardType: TextInputType.emailAddress,
      ),
    );
  }

  // ==========================================================
  // MOBILE FIELD
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
          padding: EdgeInsets.only(left: 13, right: 8),
          child: Text(
            '+91',
            style: TextStyle(
              color: RegistrationColors.text,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
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
          onPressed:
              controller.canSendOtp ? controller.sendOtp : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: RegistrationColors.yellow,
            disabledBackgroundColor: Colors.grey.shade400,
            foregroundColor: RegistrationColors.darkRed,
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
                    color: RegistrationColors.darkRed,
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
                  color: RegistrationColors.text,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              GestureDetector(
                onTap: controller.resendSeconds.value == 0
                    ? controller.resendOtp
                    : null,
                child: Text(
                  controller.resendSeconds.value > 0
                      ? 'Resend in ${controller.resendSeconds.value}s'
                      : 'Resend OTP',
                  style: TextStyle(
                    color: controller.resendSeconds.value > 0
                        ? RegistrationColors.grey
                        : RegistrationColors.darkRed,
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
          if (controller.otpError.value.isNotEmpty)
            _errorText(controller.otpError.value),
        ],
      ),
    );
  }

  // ==========================================================
  // REGISTER BUTTON
  // ==========================================================

  Widget _buildRegisterButton() {
    return Obx(
      () => SizedBox(
        width: double.infinity,
        height: 53,
        child: ElevatedButton(
          onPressed:
              controller.canRegister ? controller.register : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: RegistrationColors.yellow,
            foregroundColor: RegistrationColors.darkRed,
            disabledBackgroundColor: Colors.grey.shade300,
            disabledForegroundColor: Colors.grey.shade600,
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: controller.isSubmitting.value
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(
                    color: RegistrationColors.darkRed,
                    strokeWidth: 2,
                  ),
                )
              : const Text(
                  'REGISTER',
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
  // LOGIN FOOTER
  // ==========================================================

  Widget _buildLoginFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Already Registered ? ',
          style: TextStyle(
            color: RegistrationColors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
        GestureDetector(
          onTap: controller.goToLogin,
          child: const Text(
            'Login Here',
            style: TextStyle(
              color: RegistrationColors.red,
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
    TextCapitalization textCapitalization =
        TextCapitalization.none,
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
          textCapitalization: textCapitalization,
          maxLength: maxLength,
          inputFormatters: maxLength != null
              ? [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(maxLength),
                ]
              : null,
          style: const TextStyle(
            color: RegistrationColors.text,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              color: RegistrationColors.grey,
              fontSize: 13,
            ),
            prefixIcon: Icon(
              icon,
              color: RegistrationColors.red,
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
                color: RegistrationColors.border,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RegistrationColors.border,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: RegistrationColors.red,
                width: 1.5,
              ),
            ),
            errorText: error.isEmpty ? null : error,
            errorStyle: const TextStyle(
              color: RegistrationColors.red,
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
          color: RegistrationColors.text,
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        children: [
          if (requiredField)
            const TextSpan(
              text: ' *',
              style: TextStyle(
                color: RegistrationColors.red,
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
              final digit =
                  index < value.length ? value[index] : '';

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
                      color: RegistrationColors.border,
                      width: 1.2,
                    ),
                  ),
                  child: Text(
                    digit,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: RegistrationColors.text,
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
      padding: const EdgeInsets.only(top: 7, left: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: RegistrationColors.red,
          fontSize: 12,
        ),
      ),
    );
  }
}
