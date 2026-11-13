
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'package:namma_karnataka_app/core/utils/app_dialogs.dart';
import 'package:namma_karnataka_app/core/utils/app_snackbar.dart';

import '../../services/api_service.dart';
import '../../services/app_session.dart';

class RegistrationController extends GetxController {
  final ApiService apiService = Get.find<ApiService>();

  // Test credentials
  static const String testMobile = '9999999991';
  static const String testOtp = '1234';

  // Text controllers
  final TextEditingController usernameController =
      TextEditingController();

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  // Form values
  final RxString username = ''.obs;
  final RxString email = ''.obs;
  final RxString mobile = ''.obs;
  final RxString otp = ''.obs;

  // Validation messages
  final RxString usernameError = ''.obs;
  final RxString emailError = ''.obs;
  final RxString mobileError = ''.obs;
  final RxString otpError = ''.obs;

  // Loading and OTP states
  final RxBool isSendingOtp = false.obs;
  final RxBool isOtpSent = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxInt resendSeconds = 0.obs;

  Timer? _resendTimer;

  String _serverOtp = '';
  String _otpMobile = '';

  // --------------------------------------------------
  // VALIDATIONS
  // --------------------------------------------------

  bool get isNameValid {
    final value = username.value.trim();

    return value.length >= 2 &&
        RegExp(r"^[a-zA-Z][a-zA-Z0-9 .'-]*$")
            .hasMatch(value);
  }

  bool get isEmailValid {
    final value = email.value.trim();

    // Email is optional.
    if (value.isEmpty) return true;

    return RegExp(r'^[\w.+-]+@[\w-]+(\.[\w-]+)+$')
        .hasMatch(value);
  }

  bool get isMobileValid {
    return RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(mobile.value.trim());
  }

  bool get isOtpValid {
    return isOtpSent.value &&
        otp.value.length == 4 &&
        RegExp(r'^[0-9]{4}$').hasMatch(otp.value) &&
        _otpMobile == mobile.value.trim() &&
        _serverOtp == otp.value;
  }

  // --------------------------------------------------
  // BUTTON CONDITIONS
  // --------------------------------------------------

  bool get canShowOtpButton {
    return isNameValid && isEmailValid && isMobileValid;
  }

  bool get canSendOtp {
    return canShowOtpButton &&
        !isSendingOtp.value &&
        !isSubmitting.value &&
        resendSeconds.value == 0;
  }

  bool get showRegisterButton {
    return isNameValid &&
        isEmailValid &&
        isMobileValid &&
        isOtpValid;
  }

  bool get canRegister {
    return showRegisterButton && !isSubmitting.value;
  }

  // --------------------------------------------------
  // NAME CHANGE
  // --------------------------------------------------

  void onNameChanged(String value) {
    username.value = value.trim();

    if (value.trim().isEmpty) {
      usernameError.value = 'Please enter your name';
    } else if (value.trim().length < 2) {
      usernameError.value =
          'Name must contain at least 2 characters';
    } else if (!isNameValid) {
      usernameError.value = 'Please enter a valid name';
    } else {
      usernameError.value = '';
    }
  }

  // --------------------------------------------------
  // EMAIL CHANGE
  // --------------------------------------------------

  void onEmailChanged(String value) {
    email.value = value.trim();

    if (value.trim().isNotEmpty && !isEmailValid) {
      emailError.value = 'Please enter a valid email address';
    } else {
      emailError.value = '';
    }
  }

  // --------------------------------------------------
  // MOBILE CHANGE
  // --------------------------------------------------

  void onMobileChanged(String value) {
    final newMobile = value.trim();

    if (mobile.value != newMobile) {
      mobile.value = newMobile;

      // Reset OTP whenever mobile number changes.
      isOtpSent.value = false;
      _serverOtp = '';
      _otpMobile = '';

      otp.value = '';
      otpController.clear();
      otpError.value = '';

      resendSeconds.value = 0;
      _resendTimer?.cancel();
    }

    if (newMobile.isEmpty) {
      mobileError.value = 'Please enter mobile number';
    } else if (!isMobileValid) {
      mobileError.value =
          'Enter a valid 10-digit mobile number';
    } else {
      mobileError.value = '';
    }
  }

  // --------------------------------------------------
  // OTP CHANGE
  // --------------------------------------------------

  void onOtpChanged(String value) {
    final enteredOtp =
        value.length > 4 ? value.substring(0, 4) : value;

    otp.value = enteredOtp;

    if (enteredOtp.isEmpty) {
      otpError.value = '';
    } else if (enteredOtp.length < 4) {
      otpError.value = 'Please enter the 4-digit OTP';
    } else if (_otpMobile != mobile.value.trim()) {
      otpError.value =
          'Mobile number has changed. Please get OTP again';
    } else if (enteredOtp != _serverOtp) {
      otpError.value = 'Invalid OTP';
    } else {
      otpError.value = '';
    }
  }

  // --------------------------------------------------
  // CHECK WHETHER MOBILE IS ALREADY REGISTERED
  // --------------------------------------------------

  Future<bool> checkAlreadyRegistered(
    String mobileNumber,
  ) async {
    try {
      final existingCitizen =
          await apiService.getCitizenByMobile(mobileNumber);

      // Citizen already exists.
      if (existingCitizen != null) {
        final result = await AppDialogs.showConfirmation(
          title: 'Already Registered',
          message:
              'This mobile number is already registered with '
              'Namma Karnataka.\n\n'
              'Please login using your registered mobile number.',
          confirmText: 'GO TO LOGIN',
          cancelText: 'CANCEL',
        );

        if (result == true) {
          // Close confirmation dialog before navigation.
          if (Get.isDialogOpen == true) {
            Get.back();
          }

          await Future.delayed(Duration.zero);

          Get.offAllNamed('/login');
        }

        // Do not continue with OTP.
        return true;
      }

      // API confirmed that the number is not registered.
      return false;
    } catch (e) {
      debugPrint('CITIZEN LOOKUP ERROR: $e');

      await AppDialogs.showError(
        _cleanError(e),
        title: 'Unable to Verify Mobile Number',
      );

      // Stop OTP if API lookup fails.
      return true;
    }
  }

  // --------------------------------------------------
  // SEND OTP
  // --------------------------------------------------

  Future<void> sendOtp() async {
    final currentMobile = mobileController.text.trim();

    onNameChanged(usernameController.text);
    onEmailChanged(emailController.text);
    onMobileChanged(mobileController.text);

    if (!canShowOtpButton) {
      return;
    }

    if (resendSeconds.value > 0 ||
        isSendingOtp.value ||
        isSubmitting.value) {
      return;
    }

    isSendingOtp.value = true;

    try {
      // Check registration status before sending OTP.
      final alreadyRegistered =
          await checkAlreadyRegistered(currentMobile);

      if (alreadyRegistered) {
        return;
      }

      // Test mobile number.
      if (currentMobile == testMobile) {
        _serverOtp = testOtp;
        _otpMobile = currentMobile;

        isOtpSent.value = true;

        otp.value = '';
        otpController.clear();
        otpError.value = '';

        startResendTimer();

        // Common themed snackbar for test OTP.
        AppSnackbar.success(
          'Test OTP: $testOtp',
          title: 'OTP Sent',
        );

        return;
      }

      // Regular OTP API.
      final response = await apiService.sendOtp(currentMobile);

      if (response['status'] != true) {
        await AppDialogs.showError(
          response['message']?.toString() ??
              'Unable to send OTP. Please try again.',
          title: 'OTP Failed',
        );

        return;
      }

      // Read OTP from API response.
      _serverOtp = response['otp']?.toString().trim() ?? '';

      if (_serverOtp.isEmpty) {
        await AppDialogs.showError(
          'OTP was not received from the server. Please try again.',
          title: 'OTP Failed',
        );

        return;
      }

      _otpMobile = currentMobile;

      isOtpSent.value = true;

      otp.value = '';
      otpController.clear();
      otpError.value = '';

      startResendTimer();

      // Common themed snackbar for successful OTP.
      AppSnackbar.success(
        'OTP has been sent to your mobile number.',
        title: 'OTP Sent',
      );
    } catch (e) {
      debugPrint('SEND OTP ERROR: $e');

      await AppDialogs.showError(
        _cleanError(e),
        title: 'Unable to Send OTP',
      );
    } finally {
      isSendingOtp.value = false;
    }
  }

  // --------------------------------------------------
  // RESEND OTP TIMER
  // --------------------------------------------------

  void startResendTimer() {
    _resendTimer?.cancel();

    resendSeconds.value = 30;

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (resendSeconds.value > 0) {
          resendSeconds.value--;
        } else {
          timer.cancel();
        }
      },
    );
  }

  // --------------------------------------------------
  // RESEND OTP
  // --------------------------------------------------

  Future<void> resendOtp() async {
    if (resendSeconds.value > 0 ||
        isSendingOtp.value ||
        isSubmitting.value) {
      return;
    }

    await sendOtp();
  }

  // --------------------------------------------------
  // VALIDATE ALL FIELDS
  // --------------------------------------------------

  bool validateFields() {
    onNameChanged(usernameController.text);
    onEmailChanged(emailController.text);
    onMobileChanged(mobileController.text);
    onOtpChanged(otpController.text);

    return isNameValid &&
        isEmailValid &&
        isMobileValid &&
        isOtpValid;
  }

  // --------------------------------------------------
  // REGISTER CITIZEN
  // --------------------------------------------------

  Future<void> register() async {
    if (isSubmitting.value) return;

    // Update values from text controllers.
    username.value = usernameController.text.trim();
    email.value = emailController.text.trim();
    mobile.value = mobileController.text.trim();
    otp.value = otpController.text.trim();

    if (!validateFields()) {
      return;
    }

    if (!isOtpValid) {
      await AppDialogs.showError(
        'Please enter the correct OTP before registering.',
        title: 'Invalid OTP',
      );

      return;
    }

    isSubmitting.value = true;

    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final appVersion = packageInfo.version;

      final response = await apiService.registerCitizen(
        name: username.value.trim(),
        mobileNumber: mobile.value.trim(),
        email: email.value.trim(),
      );

      final statusCode =
          response['Status_Code']?.toString().trim();

      if (statusCode != '200') {
        await AppDialogs.showError(
          response['Status_Message']?.toString() ??
              'Registration failed. Please try again.',
          title: 'Registration Failed',
        );

        return;
      }

      // Save registration information.
      await AppSession.saveRegistrationData(
        name: username.value.trim(),
        mobileNumber: mobile.value.trim(),
        email: email.value.trim(),
        appVersion: appVersion,
      );

      // Show reusable success dialog.
      // This waits until the user presses CONTINUE.
      await AppDialogs.showSuccess(
        'Your registration has been completed successfully.',
        title: 'Successfully Registered!',
        buttonText: 'CONTINUE',
      );

      // Dialog is now closed.
      // Navigate to Dashboard.
      Get.offAllNamed('/dashboard');
    } catch (e) {
      debugPrint('REGISTRATION ERROR: $e');

      await AppDialogs.showError(
        _cleanError(e),
        title: 'Registration Failed',
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // --------------------------------------------------
  // ERROR MESSAGE CLEANUP
  // --------------------------------------------------

  String _cleanError(Object error) {
    final message = error.toString();

    if (message.contains('Failed host lookup') ||
        message.contains('SocketException') ||
        message.contains('Connection refused') ||
        message.contains('Network is unreachable')) {
      return 'Unable to connect to the server. '
          'Please check your internet connection and try again.';
    }

    if (message.contains('TimeoutException') ||
        message.contains('timed out')) {
      return 'The server is taking too long to respond. '
          'Please try again.';
    }

    return message
        .replaceFirst('Exception: ', '')
        .replaceFirst(
          'DioException [connection error]: ',
          '',
        );
  }

  // --------------------------------------------------
  // NAVIGATION
  // --------------------------------------------------

  void goToLogin() {
    Get.offAllNamed('/login');
  }

  // --------------------------------------------------
  // DISPOSE
  // --------------------------------------------------

  @override
  void onClose() {
    _resendTimer?.cancel();

    usernameController.dispose();
    emailController.dispose();
    mobileController.dispose();
    otpController.dispose();

    super.onClose();
  }
}
