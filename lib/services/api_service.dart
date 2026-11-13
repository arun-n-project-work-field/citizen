
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

class ApiService {
  static const String genericUrl =
      'https://kgis.ksrsac.in/generic/api/genericselect';

  static const String insertUrl =
      'https://maps.ksrsac.in/Generic_Insert_key';

  static const String otpUrl =
      'https://kgis.ksrsac.in/OTPAPI/api/Verifymobile';

  static const Duration requestTimeout =
      Duration(seconds: 30);

  // ==========================================================
  // 1. APP VERSION CHECK
  // ==========================================================

  Future<Map<String, dynamic>> checkAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    final installedVersion = packageInfo.version;

    debugPrint('INSTALLED APP VERSION: $installedVersion');

    final requestBody = {
      'applicantId': '1_CheckAppVersion',
      'parameter': 'P1\$|\$P2',
      'values': 'NammaKarnataka\$|\$$installedVersion',
    };

    debugPrint(
      'VERSION REQUEST: ${jsonEncode(requestBody)}',
    );

    final response = await http
        .post(
          Uri.parse(genericUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(requestTimeout);

    debugPrint('VERSION STATUS CODE: ${response.statusCode}');
    debugPrint('VERSION RESPONSE: ${response.body}');

    if (response.statusCode != 200) {
      throw Exception(
        'Version API failed: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! List ||
        decoded.isEmpty ||
        decoded.first is! Map) {
      throw Exception(
        'Invalid version API response',
      );
    }

    final versionData =
        Map<String, dynamic>.from(decoded.first as Map);

    final currentVersion =
        versionData['CurrentVersion']?.toString();

    if (currentVersion == null ||
        currentVersion.trim().isEmpty) {
      throw Exception(
        'CurrentVersion missing from version API response',
      );
    }

    debugPrint('SERVER VERSION: $currentVersion');

    return versionData;
  }

  // ==========================================================
  // 2. SEND OTP
  // ==========================================================

  Future<Map<String, dynamic>> sendOtp(String mobile) async {
    final mobileNumber = mobile.trim();

    if (!RegExp(r'^[6-9][0-9]{9}$')
        .hasMatch(mobileNumber)) {
      throw Exception(
        'Please enter a valid 10-digit mobile number.',
      );
    }

    final response = await http
        .get(
          Uri.parse('$otpUrl/$mobileNumber'),
          headers: {
            'Accept': 'application/json',
          },
        )
        .timeout(requestTimeout);

    debugPrint('OTP STATUS CODE: ${response.statusCode}');
    debugPrint('OTP RESPONSE: ${response.body}');

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(
        'Invalid OTP API response',
      );
    }

    throw Exception(
      'OTP API failed: ${response.statusCode}',
    );
  }

  // ==========================================================
  // 3. CITIZEN REGISTRATION
  // ==========================================================

  Future<Map<String, dynamic>> registerCitizen({
    required String name,
    required String mobileNumber,
    required String email,
  }) async {
    final packageInfo = await PackageInfo.fromPlatform();
    final appVersion = packageInfo.version;

    final requestBody = {
      'applicantId': '1_Insert_Citizen_app',
      'parameter': 'P1\$|\$P2\$|\$P3\$|\$P4',
      'values':
          '${name.trim()}\$|\$${mobileNumber.trim()}\$|\$${email.trim()}\$|\$$appVersion',
    };

    debugPrint(
      'REGISTRATION REQUEST: ${jsonEncode(requestBody)}',
    );

    final response = await http
        .post(
          Uri.parse(insertUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(requestTimeout);

    debugPrint(
      'REGISTRATION STATUS CODE: ${response.statusCode}',
    );

    debugPrint(
      'REGISTRATION RESPONSE: ${response.body}',
    );

    if (response.statusCode >= 200 &&
        response.statusCode < 300) {
      final dynamic decoded = jsonDecode(response.body);

      if (decoded is List &&
          decoded.isNotEmpty &&
          decoded.first is Map) {
        return Map<String, dynamic>.from(
          decoded.first as Map,
        );
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      throw Exception(
        'Invalid registration API response',
      );
    }

    throw Exception(
      'Registration API failed: ${response.statusCode}',
    );
  }

  // ==========================================================
  // 4. CHECK REGISTERED CITIZEN / LOGIN
  // ==========================================================

  Future<Map<String, dynamic>?> getCitizenByMobile(
    String mobileNumber,
  ) async {
    final mobile = mobileNumber.trim();

    if (!RegExp(r'^[6-9][0-9]{9}$').hasMatch(mobile)) {
      throw Exception(
        'Please enter a valid 10-digit mobile number.',
      );
    }

    final requestBody = {
      'applicantId': '1_Fetch_Citizen_app',
      'parameter': 'P1',
      'values': mobile,
    };

    debugPrint(
      'CITIZEN LOOKUP REQUEST: ${jsonEncode(requestBody)}',
    );

    final response = await http
        .post(
          Uri.parse(genericUrl),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(requestBody),
        )
        .timeout(requestTimeout);

    debugPrint(
      'CITIZEN LOOKUP STATUS CODE: ${response.statusCode}',
    );

    debugPrint(
      'CITIZEN LOOKUP RESPONSE: ${response.body}',
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Citizen lookup API failed: ${response.statusCode}',
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    // Expected response must be a non-empty list.
    if (decoded is! List || decoded.isEmpty) {
      throw Exception(
        'Invalid or empty citizen lookup API response.',
      );
    }

    if (decoded.first is! Map) {
      throw Exception(
        'Invalid citizen lookup response format.',
      );
    }

    final result =
        Map<String, dynamic>.from(decoded.first as Map);

    // --------------------------------------------------------
    // CASE 1: MOBILE NUMBER NOT REGISTERED
    // --------------------------------------------------------

    final message = result['Message']?.toString().trim();

    if (message != null &&
        message.toLowerCase().contains('not found')) {
      debugPrint(
        'CITIZEN NOT REGISTERED: $mobile',
      );

      return null;
    }

    // --------------------------------------------------------
    // CASE 2: REGISTERED CITIZEN FOUND
    // --------------------------------------------------------

    final registeredMobile =
        result['MobileNumber']?.toString().trim();

    final citizenName =
        result['Name']?.toString().trim();

    if (registeredMobile == mobile &&
        citizenName != null &&
        citizenName.isNotEmpty) {
      debugPrint(
        'REGISTERED CITIZEN FOUND: $citizenName',
      );

      return result;
    }

    // --------------------------------------------------------
    // CASE 3: UNKNOWN / INVALID RESPONSE
    // --------------------------------------------------------

    throw Exception(
      'Unexpected response received while checking citizen registration.',
    );
  }
}
