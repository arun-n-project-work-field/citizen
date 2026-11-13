
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:namma_karnataka_app/core/services/internet_monitor.dart';
import 'package:namma_karnataka_app/core/utils/app_dialogs.dart';

import '../../routes/app_routes.dart';
import '../../services/api_service.dart';
import '../../services/app_session.dart';

class SplashController extends GetxController
    with WidgetsBindingObserver {
  final ApiService apiService = Get.find<ApiService>();

  final InternetMonitor internetMonitor =
      Get.find<InternetMonitor>();

  // UI state
  final RxBool isCheckingVersion = true.obs;

  // Startup flags
  bool _startupStarted = false;
  bool _versionCheckInProgress = false;
  bool _versionCheckPassed = false;
  bool _permissionsInProgress = false;
  bool _waitingForSettings = false;
  bool _updateDialogOpen = false;

  @override
  void onInit() {
    super.onInit();
    WidgetsBinding.instance.addObserver(this);
  }

  // ==========================================================
  // STARTUP
  // ==========================================================

  @override
  void onReady() {
    super.onReady();

    if (_startupStarted) return;

    _startupStarted = true;

    // Start version verification.
    // InternetMonitor independently handles offline alerts.
    checkVersion();
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state != AppLifecycleState.resumed) {
      return;
    }

    debugPrint('APP RESUMED');

    // Refresh network status.
    internetMonitor.checkNow();

    // Returned from application settings.
    if (_waitingForSettings) {
      _waitingForSettings = false;

      debugPrint(
        'Returned from settings. Rechecking permissions.',
      );

      Future.delayed(
        const Duration(milliseconds: 500),
        () {
          if (!_permissionsInProgress &&
              _versionCheckPassed) {
            requestStartupPermissions();
          }
        },
      );

      return;
    }

    // Version check already passed, but permission flow
    // may need to continue after returning to the app.
    if (_versionCheckPassed &&
        !_permissionsInProgress) {
      debugPrint(
        'Resuming startup permission flow.',
      );

      requestStartupPermissions();
      return;
    }

    // Restart version check only if no check is currently running.
    if (!_versionCheckPassed &&
        !_versionCheckInProgress &&
        _startupStarted) {
      debugPrint(
        'Restarting pending version verification.',
      );

      checkVersion();
    }
  }

  // ==========================================================
  // STEP 1 AND 2: INTERNET AND VERSION CHECK
  // ==========================================================

  Future<void> checkVersion() async {
    if (_versionCheckInProgress) return;

    _versionCheckInProgress = true;
    _versionCheckPassed = false;
    isCheckingVersion.value = true;

    bool proceedToPermissions = false;

    try {
      while (true) {
        // Wait for actual internet availability.
        await internetMonitor.waitUntilConnected();

        try {
          final packageInfo =
              await PackageInfo.fromPlatform();

          final installedVersion = packageInfo.version;
          final packageName = packageInfo.packageName;

          debugPrint(
            'INSTALLED APP VERSION: $installedVersion',
          );

          // Call version API.
          final response =
              await apiService.checkAppVersion();

          final serverVersion =
              _extractCurrentVersion(response);

          if (serverVersion == null ||
              serverVersion.trim().isEmpty) {
            throw const FormatException(
              'The server did not return a valid application version.',
            );
          }

          debugPrint(
            'SERVER APP VERSION: $serverVersion',
          );

          // Compare installed and server versions.
          if (isVersionLower(
            installedVersion,
            serverVersion,
          )) {
            await showUpdateDialog(packageName);
            return;
          }

          // VERSION CHECK SUCCESSFUL.
          _versionCheckPassed = true;
          proceedToPermissions = true;

          debugPrint(
            'APP VERSION CHECK SUCCESSFUL',
          );

          break;
        } catch (e, stackTrace) {
          debugPrint('VERSION CHECK ERROR: $e');
          debugPrintStack(stackTrace: stackTrace);

          // If internet is lost, wait for reconnection.
          if (!internetMonitor.isConnected.value) {
            debugPrint(
              'Internet lost during version check. Waiting for reconnection.',
            );

            continue;
          }

          // API failed while internet is available.
          // Do not request permissions.
          final retry =
              await AppDialogs.showConfirmation(
                    title: 'Version Check Failed',
                    message:
                        'Unable to verify the application version.\n\n'
                        'Please try again.',
                    confirmText: 'RETRY',
                    cancelText: 'EXIT',
                  ) ??
                  false;

          if (retry) {
            continue;
          }

          SystemNavigator.pop();
          return;
        }
      }
    } catch (e, stackTrace) {
      debugPrint('STARTUP VERSION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      await AppDialogs.showError(
        'Unable to verify the application version. '
        'Please restart the application.',
        title: 'Version Check Failed',
      );

      return;
    } finally {
      // Stop version-check loading before requesting permissions.
      isCheckingVersion.value = false;
      _versionCheckInProgress = false;
    }

    // Permissions are requested only after successful verification.
    if (proceedToPermissions && _versionCheckPassed) {
      debugPrint(
        'VERSION VERIFIED. STARTING PERMISSION REQUESTS.',
      );

      await requestStartupPermissions();
    }
  }

  // ==========================================================
  // EXTRACT SERVER VERSION
  // ==========================================================

  String? _extractCurrentVersion(dynamic response) {
    dynamic data = response;

    if (data is List) {
      if (data.isEmpty) return null;
      data = data.first;
    }

    if (data is Map) {
      final version =
          data['CurrentVersion'] ??
          data['currentVersion'] ??
          data['current_version'];

      if (version == null) return null;

      final result = version.toString().trim();

      if (result.isEmpty ||
          result.toLowerCase() == 'null') {
        return null;
      }

      return result;
    }

    return null;
  }

  // ==========================================================
  // COMPARE APP VERSIONS
  // ==========================================================

  bool isVersionLower(
    String installedVersion,
    String serverVersion,
  ) {
    try {
      final installedParts =
          installedVersion.split('.').map(int.parse).toList();

      final serverParts =
          serverVersion.split('.').map(int.parse).toList();

      final maxLength =
          installedParts.length > serverParts.length
              ? installedParts.length
              : serverParts.length;

      for (int i = 0; i < maxLength; i++) {
        final installed =
            i < installedParts.length
                ? installedParts[i]
                : 0;

        final server =
            i < serverParts.length
                ? serverParts[i]
                : 0;

        if (installed < server) return true;

        if (installed > server) return false;
      }

      return false;
    } catch (e) {
      debugPrint('VERSION COMPARISON ERROR: $e');

      throw const FormatException(
        'Invalid application version format.',
      );
    }
  }

  // ==========================================================
  // FORCE APP UPDATE
  // ==========================================================

  Future<void> showUpdateDialog(String packageName) async {
    if (_updateDialogOpen) return;

    _updateDialogOpen = true;

    try {
      await Get.dialog(
        PopScope(
          canPop: false,
          child: AlertDialog(
            title: const Text(
              'Application Update Required',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
            content: const Text(
              'A newer version of Namma Karnataka is available.\n\n'
              'Please update the application to continue.',
            ),
            actions: [
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await _openPlayStore(packageName);
                },
                child: const Text('UPDATE NOW'),
              ),
            ],
          ),
        ),
        barrierDismissible: false,
      );
    } finally {
      _updateDialogOpen = false;
    }
  }

  Future<void> _openPlayStore(String packageName) async {
    final marketUri = Uri.parse(
      'market://details?id=$packageName',
    );

    final webUri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$packageName',
    );

    try {
      final marketOpened = await launchUrl(
        marketUri,
        mode: LaunchMode.externalApplication,
      );

      if (marketOpened) return;

      final browserOpened = await launchUrl(
        webUri,
        mode: LaunchMode.externalApplication,
      );

      if (!browserOpened) {
        await AppDialogs.showError(
          'Unable to open the application store. '
          'Please update Namma Karnataka manually.',
          title: 'Update Required',
        );
      }
    } catch (e) {
      debugPrint('PLAY STORE ERROR: $e');

      try {
        await launchUrl(
          webUri,
          mode: LaunchMode.externalApplication,
        );
      } catch (browserError) {
        debugPrint('BROWSER ERROR: $browserError');

        await AppDialogs.showError(
          'Unable to open the application store. '
          'Please update Namma Karnataka manually.',
          title: 'Update Required',
        );
      }
    }
  }

  // ==========================================================
  // STEP 3: REQUEST PERMISSIONS
  // ==========================================================

  Future<void> requestStartupPermissions() async {
    // STRICT VERSION CHECK PROTECTION.
    if (!_versionCheckPassed) {
      debugPrint(
        'PERMISSION BLOCKED: Version check not successful.',
      );
      return;
    }

    if (_permissionsInProgress) {
      debugPrint(
        'PERMISSION REQUEST ALREADY IN PROGRESS.',
      );
      return;
    }

    if (WidgetsBinding.instance.lifecycleState !=
        AppLifecycleState.resumed) {
      debugPrint(
        'APP NOT RESUMED. WAITING TO REQUEST PERMISSIONS.',
      );
      return;
    }

    _permissionsInProgress = true;

    try {
      debugPrint('REQUESTING LOCATION PERMISSION');

      // FIRST: LOCATION
      final locationGranted = await _requestPermission(
        Permission.locationWhenInUse,
        'Location',
      );

      if (!locationGranted) return;

      debugPrint('LOCATION PERMISSION GRANTED');

      // SECOND: CAMERA
      debugPrint('REQUESTING CAMERA PERMISSION');

      final cameraGranted = await _requestPermission(
        Permission.camera,
        'Camera',
      );

      if (!cameraGranted) return;

      debugPrint('CAMERA PERMISSION GRANTED');

      // BOTH PERMISSIONS GRANTED.
      // NOW NAVIGATE.
      debugPrint(
        'ALL STARTUP PERMISSIONS GRANTED',
      );

      await goToNextScreen();
    } catch (e, stackTrace) {
      debugPrint('PERMISSION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      await AppDialogs.showError(
        'Unable to verify application permissions. '
        'Please try again.',
        title: 'Permission Error',
      );
    } finally {
      _permissionsInProgress = false;
    }
  }

  // ==========================================================
  // INDIVIDUAL PERMISSION HANDLING
  // ==========================================================

  Future<bool> _requestPermission(
    Permission permission,
    String permissionName,
  ) async {
    PermissionStatus status = await permission.status;

    debugPrint(
      '$permissionName CURRENT STATUS: $status',
    );

    if (status.isGranted) {
      return true;
    }

    // Request the permission.
    status = await permission.request();

    debugPrint(
      '$permissionName REQUEST RESULT: $status',
    );

    if (status.isGranted) {
      return true;
    }

    // Permission denied.
    final openSettings =
        await AppDialogs.showConfirmation(
              title: '$permissionName Permission Required',
              message:
                  '$permissionName permission is required '
                  'to use Namma Karnataka.\n\n'
                  'Please grant this permission to continue.',
              confirmText: 'OPEN SETTINGS',
              cancelText: 'EXIT',
            ) ??
            false;

    if (!openSettings) {
      SystemNavigator.pop();
      return false;
    }

    // Wait for the user to return from settings.
    _waitingForSettings = true;

    final opened = await openAppSettings();

    if (!opened) {
      _waitingForSettings = false;

      await AppDialogs.showError(
        'Unable to open application settings. '
        'Please enable $permissionName permission manually.',
        title: 'Settings Unavailable',
      );

      return false;
    }

    // Do not navigate here.
    // Permissions will be checked again on app resume.
    return false;
  }

  // ==========================================================
  // STEP 4: NAVIGATION
  // ==========================================================

  Future<void> goToNextScreen() async {
    // Prevent navigation without successful version check.
    if (!_versionCheckPassed) {
      debugPrint(
        'NAVIGATION BLOCKED: Version check not passed.',
      );
      return;
    }

    try {
      final isLoggedIn =
          await AppSession.isLoggedIn();

      if (isLoggedIn) {
        debugPrint(
          'USER LOGGED IN - OPENING DASHBOARD',
        );

        Get.offAllNamed(AppRoutes.dashboard);
      } else {
        debugPrint(
          'NEW USER - OPENING REGISTRATION',
        );

        Get.offAllNamed(AppRoutes.registration);
      }
    } catch (e, stackTrace) {
      debugPrint('NAVIGATION ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      await AppDialogs.showError(
        'Unable to open the application. '
        'Please restart Namma Karnataka.',
        title: 'Startup Error',
      );
    }
  }

  // ==========================================================
  // CLEANUP
  // ==========================================================

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);
    super.onClose();
  }
}
