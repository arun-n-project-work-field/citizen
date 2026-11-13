
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:namma_karnataka_app/core/services/internet_monitor.dart';
import 'package:namma_karnataka_app/core/services/pref_service.dart';
import 'package:namma_karnataka_app/services/api_service.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('========== APP STARTED ==========');

  await PrefService.init();

  debugPrint('PREFERENCES INITIALIZED');

  // Register ApiService globally.
  Get.put<ApiService>(ApiService(), permanent: true);

  debugPrint('API SERVICE REGISTERED');

  // Initialize InternetMonitor.
  await Get.putAsync<InternetMonitor>(
    () => InternetMonitor().init(),
    permanent: true,
  );

  debugPrint('INTERNET MONITOR INITIALIZED');

  debugPrint('STARTING NAMMA KARNATAKA APPLICATION');

  runApp(const NammaKarnatakaApp());

  debugPrint('========== RUN APP COMPLETED ==========');
}
