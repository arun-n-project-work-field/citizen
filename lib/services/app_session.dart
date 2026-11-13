
import 'package:shared_preferences/shared_preferences.dart';

/// Single source of truth for authentication and registration data.
class AppSession {
  AppSession._();

  static const String _isLoggedInKey = 'is_logged_in';

  static const String _mobileNumberKey = 'login_mobile_number';
  static const String _districtNameKey = 'login_district_name';
  static const String _districtCodeKey = 'login_district_code';
  static const String _talukNameKey = 'login_taluk_name';
  static const String _talukCodeKey = 'login_taluk_code';

  // Registration details
  static const String _nameKey = 'registered_name';
  static const String _emailKey = 'registered_email';
  static const String _appVersionKey = 'registered_app_version';
  static const String _isRegisteredKey = 'is_registered';

  /// Save registration information after successful API insertion.
  static Future<void> saveRegistrationData({
    required String name,
    required String mobileNumber,
    required String email,
    required String appVersion,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Save all registration details first.
    await prefs.setString(_nameKey, name.trim());
    await prefs.setString(_mobileNumberKey, mobileNumber.trim());
    await prefs.setString(_emailKey, email.trim());
    await prefs.setString(_appVersionKey, appVersion.trim());

    // Registration and login status.
    await prefs.setBool(_isRegisteredKey, true);
    await prefs.setBool(
      _isLoggedInKey,
      mobileNumber.trim().isNotEmpty,
    );
  }

  /// Existing login credentials method.
  static Future<void> saveLoginCredentials({
    required String mobileNumber,
    required String districtName,
    required String districtCode,
    required String talukName,
    required String talukCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(_mobileNumberKey, mobileNumber.trim());
    await prefs.setString(_districtNameKey, districtName.trim());
    await prefs.setString(_districtCodeKey, districtCode.trim());
    await prefs.setString(_talukNameKey, talukName.trim());
    await prefs.setString(_talukCodeKey, talukCode.trim());

    await prefs.setBool(
      _isLoggedInKey,
      mobileNumber.trim().isNotEmpty,
    );
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final mobile = prefs.getString(_mobileNumberKey)?.trim() ?? '';

    return (prefs.getBool(_isLoggedInKey) ?? false) &&
        mobile.isNotEmpty;
  }

  static Future<bool> isRegistered() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isRegisteredKey) ?? false;
  }

  /// Retrieve all saved registration and login details.
  static Future<Map<String, String>> getLoginData() async {
    final prefs = await SharedPreferences.getInstance();

    return <String, String>{
      'name': prefs.getString(_nameKey) ?? '',
      'mobileNumber': prefs.getString(_mobileNumberKey) ?? '',
      'email': prefs.getString(_emailKey) ?? '',
      'appVersion': prefs.getString(_appVersionKey) ?? '',
      'districtName': prefs.getString(_districtNameKey) ?? '',
      'districtCode': prefs.getString(_districtCodeKey) ?? '',
      'talukName': prefs.getString(_talukNameKey) ?? '',
      'talukCode': prefs.getString(_talukCodeKey) ?? '',
    };
  }

  /// Clear authentication and registration information on logout.
  /// Local surveys and device ID are not affected.
  static Future<void> clearLoginCredentials() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setBool(_isLoggedInKey, false);
    await prefs.setBool(_isRegisteredKey, false);

    await prefs.remove(_mobileNumberKey);
    await prefs.remove(_districtNameKey);
    await prefs.remove(_districtCodeKey);
    await prefs.remove(_talukNameKey);
    await prefs.remove(_talukCodeKey);

    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_appVersionKey);
  }

  static Future<void> logout() => clearLoginCredentials();
}
