
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../services/api_service.dart';
import '../../core/utils/app_dialogs.dart';
import '../../core/utils/app_snackbar.dart';

class LoginController extends GetxController {
  final ApiService apiService = ApiService();

  // ==========================================================
  // TEST USER DETAILS
  // ==========================================================

  static const String testMobile = '9999999999';
  static const String testOtp = '1234';

  // ==========================================================
  // TEXT CONTROLLERS
  // ==========================================================

  final TextEditingController mobileController =
      TextEditingController();

  final TextEditingController otpController =
      TextEditingController();

  // ==========================================================
  // OBSERVABLE VARIABLES
  // ==========================================================

  final RxString mobile = ''.obs;
  final RxString otp = ''.obs;

  final RxString mobileError = ''.obs;
  final RxString otpError = ''.obs;

  final RxBool isOtpSent = false.obs;
  final RxBool isSendingOtp = false.obs;
  final RxBool isSubmitting = false.obs;

  final RxBool isCheckingRegistration = false.obs;
  final RxBool isRegisteredMobile = false.obs;
  final RxBool registrationCheckCompleted = false.obs;

  final RxString registrationMessage = ''.obs;

  final RxInt resendSeconds = 0.obs;

  // ==========================================================
  // INTERNAL VARIABLES
  // ==========================================================

  String? _serverOtp;
  String? _otpMobile;

  Timer? _resendTimer;
  Timer? _registrationCheckTimer;

  int _registrationRequestId = 0;

  // ==========================================================
  // VALIDATION GETTERS
  // ==========================================================

  bool get isMobileValid {
    return RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(mobile.value.trim());
  }

  bool get isOtpValid {
    return isOtpSent.value &&
        RegExp(r'^[0-9]{4}$').hasMatch(otp.value.trim()) &&
        _otpMobile == mobile.value.trim() &&
        _serverOtp == otp.value.trim();
  }

  bool get canSendOtp {
    return isMobileValid &&
        registrationCheckCompleted.value &&
        isRegisteredMobile.value &&
        !isCheckingRegistration.value &&
        !isSendingOtp.value &&
        (!isOtpSent.value || resendSeconds.value == 0);
  }

  bool get showLoginButton {
    return isMobileValid &&
        isRegisteredMobile.value &&
        registrationCheckCompleted.value &&
        isOtpValid;
  }

  bool get canLogin {
    return showLoginButton && !isSubmitting.value;
  }

  // ==========================================================
  // MOBILE NUMBER CHANGE
  // ==========================================================

  void onMobileChanged(String value) {
    final newMobile = value.trim();
    final hasChanged = mobile.value.trim() != newMobile;

    mobile.value = newMobile;

    if (hasChanged) {
      _resetOtpState();
    }

    // Same validation messages as RegistrationController.
    if (newMobile.isEmpty) {
      mobileError.value = 'Please enter mobile number';
    } else if (!isMobileValid) {
      mobileError.value =
          'Enter a valid 10-digit mobile number';
    } else {
      mobileError.value = '';
    }

    if (!hasChanged) return;

    // Invalidate previous registration lookup.
    _registrationRequestId++;

    _registrationCheckTimer?.cancel();

    isCheckingRegistration.value = false;
    isRegisteredMobile.value = false;
    registrationCheckCompleted.value = false;
    registrationMessage.value = '';

    // Check registration only after a valid number is entered.
    if (isMobileValid) {
      _registrationCheckTimer = Timer(
        const Duration(milliseconds: 500),
        () {
          checkMobileRegistration(newMobile);
        },
      );
    }
  }

  // ==========================================================
  // CHECK MOBILE REGISTRATION
  // ==========================================================

  Future<void> checkMobileRegistration(
    String mobileNumber,
  ) async {
    final currentMobile = mobileNumber.trim();

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(currentMobile)) {
      return;
    }

    final requestId = ++_registrationRequestId;

    isCheckingRegistration.value = true;
    isRegisteredMobile.value = false;
    registrationCheckCompleted.value = false;
    registrationMessage.value = '';

    try {
      debugPrint(
        'CHECKING CITIZEN REGISTRATION: $currentMobile',
      );

      final citizenData =
          await apiService.getCitizenByMobile(currentMobile);

      // Ignore stale responses.
      if (requestId != _registrationRequestId ||
          currentMobile != mobileController.text.trim()) {
        return;
      }

      if (citizenData != null) {
        final registeredMobile =
            citizenData['MobileNumber']?.toString().trim();

        if (registeredMobile == currentMobile) {
          isRegisteredMobile.value = true;
          registrationCheckCompleted.value = true;

          registrationMessage.value =
              'Mobile number verified. You can request OTP.';

          debugPrint('CITIZEN REGISTERED');
        } else {
          isRegisteredMobile.value = false;
          registrationCheckCompleted.value = true;

          registrationMessage.value =
              'This mobile number is not registered. Please register first.';
        }
      } else {
        isRegisteredMobile.value = false;
        registrationCheckCompleted.value = true;

        registrationMessage.value =
            'This mobile number is not registered. Please register first.';
      }
    } catch (e) {
      if (requestId != _registrationRequestId ||
          currentMobile != mobileController.text.trim()) {
        return;
      }

      isRegisteredMobile.value = false;
      registrationCheckCompleted.value = false;

      registrationMessage.value =
          'Unable to verify this mobile number. Please try again.';

      debugPrint('REGISTRATION CHECK ERROR: $e');

      await AppDialogs.showError(
        _getReadableError(e),
        title: 'Mobile Number Verification Failed',
      );
    } finally {
      if (requestId == _registrationRequestId) {
        isCheckingRegistration.value = false;
      }
    }
  }

  // ==========================================================
  // RESET OTP STATE
  // ==========================================================

  void _resetOtpState() {
    isOtpSent.value = false;

    otp.value = '';
    otpController.clear();

    otpError.value = '';

    _serverOtp = null;
    _otpMobile = null;

    resendSeconds.value = 0;

    _resendTimer?.cancel();
  }

  // ==========================================================
  // OTP CHANGE
  // ==========================================================

  void onOtpChanged(String value) {
    final enteredOtp =
        value.length > 4 ? value.substring(0, 4) : value;

    otp.value = enteredOtp;

    if (enteredOtp.isEmpty) {
      otpError.value = '';
    } else if (!isOtpSent.value) {
      otpError.value = 'Please request OTP first.';
    } else if (enteredOtp.length < 4) {
      otpError.value = 'Please enter the 4-digit OTP.';
    } else if (_otpMobile != mobile.value.trim()) {
      otpError.value =
          'Mobile number has changed. Please get OTP again.';
    } else if (enteredOtp != _serverOtp) {
      otpError.value = 'Invalid OTP. Please try again.';
    } else {
      otpError.value = '';
    }
  }

  // ==========================================================
  // MOBILE VALIDATION
  // ==========================================================

  bool validateMobile() {
    final enteredMobile = mobileController.text.trim();

    // Synchronize the value without restarting registration lookup.
    mobile.value = enteredMobile;

    if (enteredMobile.isEmpty) {
      mobileError.value = 'Please enter mobile number';
      return false;
    }

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(enteredMobile)) {
      mobileError.value =
          'Enter a valid 10-digit mobile number';
      return false;
    }

    mobileError.value = '';
    return true;
  }

  // ==========================================================
  // OTP VALIDATION
  // ==========================================================

  bool validateOtp() {
    if (!isOtpSent.value) {
      otpError.value = 'Please request OTP first.';
      return false;
    }

    if (otp.value.trim().isEmpty) {
      otpError.value = 'Please enter OTP.';
      return false;
    }

    if (otp.value.trim().length != 4) {
      otpError.value = 'Please enter the 4-digit OTP.';
      return false;
    }

    if (_otpMobile != mobile.value.trim()) {
      otpError.value =
          'Please request a new OTP for this mobile number.';
      return false;
    }

    if (_serverOtp != otp.value.trim()) {
      otpError.value = 'Invalid OTP. Please try again.';
      return false;
    }

    otpError.value = '';
    return true;
  }

  // ==========================================================
  // SEND OTP
  // ==========================================================

  Future<void> sendOtp() async {
    if (!validateMobile()) {
      await _showAlertDialog(
        title: 'Invalid Mobile Number',
        message: mobileError.value,
      );
      return;
    }

    if (isCheckingRegistration.value) {
      return;
    }

    if (!registrationCheckCompleted.value ||
        !isRegisteredMobile.value) {
      await _showAlertDialog(
        title: 'Registration Required',
        message:
            'This mobile number is not registered. Please register first.',
      );
      return;
    }

    if (!canSendOtp) return;

    await _requestOtp();
  }

  // ==========================================================
  // REQUEST OTP
  // ==========================================================

  Future<void> _requestOtp() async {
    final currentMobile = mobile.value.trim();

    if (!isRegisteredMobile.value ||
        !registrationCheckCompleted.value ||
        currentMobile != mobileController.text.trim()) {
      return;
    }

    isSendingOtp.value = true;

    try {
      // Test user.
      if (currentMobile == testMobile) {
        _serverOtp = testOtp;
        _otpMobile = currentMobile;

        isOtpSent.value = true;

        otp.value = '';
        otpController.clear();
        otpError.value = '';

        startResendTimer();

        AppSnackbar.success(
          'Test OTP: $testOtp',
          title: 'OTP Sent',
        );

        return;
      }

      // Regular user OTP API.
      final response =
          await apiService.sendOtp(currentMobile);

      if (currentMobile != mobileController.text.trim()) {
        return;
      }

      final dynamic status = response['status'];
      final dynamic receivedOtp = _extractOtp(response);

      if (status == true && receivedOtp != null) {
        _serverOtp = receivedOtp.toString().trim();
        _otpMobile = currentMobile;

        isOtpSent.value = true;

        otp.value = '';
        otpController.clear();
        otpError.value = '';

        startResendTimer();

        AppSnackbar.success(
          'OTP has been sent to your mobile number.',
          title: 'OTP Sent',
        );
      } else {
        await _showAlertDialog(
          title: 'OTP Failed',
          message: response['message']?.toString() ??
              'Unable to send OTP. Please try again.',
        );
      }
    } catch (e) {
      debugPrint('OTP API ERROR: $e');

      await _showAlertDialog(
        title: 'OTP Error',
        message: _getReadableError(e),
      );
    } finally {
      isSendingOtp.value = false;
    }
  }

  // ==========================================================
  // EXTRACT OTP
  // ==========================================================

  dynamic _extractOtp(Map<String, dynamic> response) {
    return response['otp'];
  }

  // ==========================================================
  // RESEND OTP
  // ==========================================================

  Future<void> resendOtp() async {
    if (resendSeconds.value > 0 ||
        isSendingOtp.value) {
      return;
    }

    if (!validateMobile()) {
      await _showAlertDialog(
        title: 'Invalid Mobile Number',
        message: mobileError.value,
      );
      return;
    }

    if (!registrationCheckCompleted.value ||
        !isRegisteredMobile.value ||
        isCheckingRegistration.value) {
      await _showAlertDialog(
        title: 'Registration Required',
        message:
            'Please verify that your mobile number is registered before requesting OTP.',
      );
      return;
    }

    await _requestOtp();
  }

  // ==========================================================
  // RESEND TIMER
  // ==========================================================

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

  // ==========================================================
  // LOGIN
  // ==========================================================

  Future<void> login() async {
    if (isSubmitting.value) return;

    if (!validateMobile()) {
      await _showAlertDialog(
        title: 'Invalid Mobile Number',
        message: mobileError.value,
      );
      return;
    }

    if (!registrationCheckCompleted.value ||
        !isRegisteredMobile.value) {
      await _showAlertDialog(
        title: 'Registration Required',
        message:
            'This mobile number is not registered. Please register first.',
      );
      return;
    }

    if (!validateOtp()) return;

    if (!canLogin) return;

    isSubmitting.value = true;

    try {
      final mobileNumber = mobile.value.trim();

      debugPrint(
        'CHECKING REGISTERED CITIZEN: $mobileNumber',
      );

      final citizenData =
          await apiService.getCitizenByMobile(mobileNumber);

      if (mobileNumber != mobileController.text.trim()) {
        return;
      }

      if (citizenData == null) {
        final result =
            await AppDialogs.showConfirmation(
          title: 'Mobile Number Not Registered',
          message:
              'This mobile number is not registered. Would you like to register now?',
          confirmText: 'REGISTER',
          cancelText: 'CANCEL',
        );

        if (result == true) {
          Get.toNamed('/registration');
        }

        return;
      }

      final citizenName =
          citizenData['Name']?.toString() ?? '';

      final citizenMobile =
          citizenData['MobileNumber']?.toString() ??
              mobileNumber;

      final citizenEmail =
          citizenData['MailID']?.toString() ?? '';

      final appVersion =
          citizenData['Version']?.toString() ?? '';

      // Save login session.
      final prefs =
          await SharedPreferences.getInstance();

      await prefs.setBool('is_logged_in', true);
      await prefs.setBool('is_registered', true);

      await prefs.setString(
        'login_mobile_number',
        citizenMobile,
      );

      await prefs.setString(
        'registered_name',
        citizenName,
      );

      await prefs.setString(
        'registered_email',
        citizenEmail,
      );

      await prefs.setString(
        'registered_app_version',
        appVersion,
      );

      debugPrint('CITIZEN LOGIN SUCCESS: $citizenName');

      await AppDialogs.showSuccess(
        'Welcome $citizenName!\n\n'
        'You have successfully logged in to Namma Karnataka.',
        title: 'Login Successful',
        buttonText: 'CONTINUE',
      );

      Get.offAllNamed(
        '/dashboard',
        arguments: citizenData,
      );
    } catch (e) {
      debugPrint('LOGIN API ERROR: $e');

      await _showAlertDialog(
        title: 'Login Failed',
        message: _getReadableError(e),
      );
    } finally {
      isSubmitting.value = false;
    }
  }

  // ==========================================================
  // COMMON ALERT DIALOG
  // ==========================================================

  Future<void> _showAlertDialog({
    required String title,
    required String message,
    String buttonText = 'OK',
  }) async {
    await AppDialogs.showError(
      message,
      title: title,
      buttonText: buttonText,
    );
  }

  // ==========================================================
  // READABLE ERROR MESSAGE
  // ==========================================================

  String _getReadableError(Object error) {
    final errorMessage = error.toString();

    if (errorMessage.contains('Failed host lookup') ||
        errorMessage.contains('SocketException') ||
        errorMessage.contains('Network is unreachable')) {
      return 'Unable to connect to the server. '
          'Please check your internet connection and try again.';
    }

    if (errorMessage.contains('TimeoutException')) {
      return 'The server is taking too long to respond. '
          'Please try again.';
    }

    return errorMessage.replaceFirst(
      'Exception: ',
      '',
    );
  }

  // ==========================================================
  // GO TO REGISTRATION
  // ==========================================================

  void goToRegistration() {
    Get.toNamed('/registration');
  }

  // ==========================================================
  // DISPOSE
  // ==========================================================

  @override
  void onClose() {
    _resendTimer?.cancel();
    _registrationCheckTimer?.cancel();

    mobileController.dispose();
    otpController.dispose();

    super.onClose();
  }
}
