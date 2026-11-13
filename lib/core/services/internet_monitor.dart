
import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../utils/app_dialogs.dart';

class InternetMonitor extends GetxService
    with WidgetsBindingObserver {
  final Connectivity _connectivity = Connectivity();

  // ==========================================================
  // CONNECTION STATUS
  // ==========================================================

  // True when Wi-Fi or mobile data is connected.
  final RxBool isConnected = false.obs;

  // Physical network availability.
  final RxBool isNetworkAvailable = false.obs;

  // Current network types reported by Android.
  final RxList<ConnectivityResult> networkTypes =
      <ConnectivityResult>[].obs;

  // Wi-Fi status.
  final RxBool isWifiConnected = false.obs;

  // Mobile data status.
  final RxBool isMobileConnected = false.obs;

  // ==========================================================
  // MONITORING
  // ==========================================================

  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _timer;

  Completer<void>? _connectionCompleter;

  Future<void>? _checkFuture;

  bool _started = false;
  bool _dialogOpen = false;
  bool _initialCheckCompleted = false;

  static const Duration checkInterval =
      Duration(seconds: 5);

  // ==========================================================
  // INITIALIZE
  // ==========================================================

  Future<InternetMonitor> init() async {
    startMonitoring();
    return this;
  }

  // ==========================================================
  // START MONITORING
  // ==========================================================

  void startMonitoring() {
    if (_started) return;

    _started = true;

    WidgetsBinding.instance.addObserver(this);

    // Listen for Wi-Fi / mobile data changes.
    _subscription =
        _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        debugPrint('NETWORK CHANGED: $results');
        _updateNetworkTypes(results);
        checkNow();
      },
      onError: (error) {
        debugPrint('CONNECTIVITY STREAM ERROR: $error');

        _updateNetworkTypes(
          [ConnectivityResult.none],
        );

        _updateConnectionStatus(false);
      },
    );

    // Initial check.
    checkNow();

    // Periodic monitoring.
    _timer = Timer.periodic(
      checkInterval,
      (_) {
        if (WidgetsBinding.instance.lifecycleState ==
            AppLifecycleState.resumed) {
          checkNow();
        }
      },
    );
  }

  // ==========================================================
  // CHECK NOW
  // ==========================================================

  Future<void> checkNow() {
    // Prevent duplicate simultaneous checks.
    if (_checkFuture != null) {
      return _checkFuture!;
    }

    final future = _performCheck();

    _checkFuture = future;

    return future.whenComplete(() {
      if (identical(_checkFuture, future)) {
        _checkFuture = null;
      }
    });
  }

  // ==========================================================
  // CHECK NETWORK CONNECTION
  // ==========================================================

  Future<void> _performCheck() async {
    try {
      // Check only Wi-Fi / mobile data connectivity.
      final results =
          await _connectivity.checkConnectivity();

      _updateNetworkTypes(results);

      final bool hasNetwork = results.any(
        (result) =>
            result != ConnectivityResult.none,
      );

      isNetworkAvailable.value = hasNetwork;

      debugPrint('NETWORK AVAILABLE: $hasNetwork');
      debugPrint(
        'WIFI CONNECTED: ${isWifiConnected.value}',
      );
      debugPrint(
        'MOBILE DATA CONNECTED: ${isMobileConnected.value}',
      );

      _updateConnectionStatus(hasNetwork);
    } catch (e, stackTrace) {
      debugPrint('NETWORK CHECK ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      _updateNetworkTypes(
        [ConnectivityResult.none],
      );

      isNetworkAvailable.value = false;

      _updateConnectionStatus(false);
    } finally {
      _initialCheckCompleted = true;
    }
  }

  // ==========================================================
  // UPDATE NETWORK TYPES
  // ==========================================================

  void _updateNetworkTypes(
    List<ConnectivityResult> results,
  ) {
    networkTypes.assignAll(results);

    isWifiConnected.value =
        results.contains(ConnectivityResult.wifi);

    isMobileConnected.value =
        results.contains(ConnectivityResult.mobile);

    debugPrint(
      'WIFI CONNECTED: ${isWifiConnected.value}',
    );

    debugPrint(
      'MOBILE DATA CONNECTED: ${isMobileConnected.value}',
    );

    debugPrint(
      'ACTIVE NETWORK TYPES: $results',
    );
  }

  // ==========================================================
  // UPDATE CONNECTION STATUS
  // ==========================================================

  void _updateConnectionStatus(bool connected) {
    final previousStatus = isConnected.value;

    isConnected.value = connected;

    if (connected) {
      if (!previousStatus) {
        debugPrint('NETWORK CONNECTION AVAILABLE');
      }

      final completer = _connectionCompleter;

      if (completer != null &&
          !completer.isCompleted) {
        completer.complete();
      }

      _connectionCompleter = null;

      _closeInternetDialog();
    } else {
      if (previousStatus) {
        debugPrint('NETWORK CONNECTION LOST');
      }

      debugPrint('NO WIFI OR MOBILE DATA CONNECTION');

      if (_initialCheckCompleted &&
          WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
        showStatusDialog();
      }
    }
  }

  // ==========================================================
  // SHOW CONNECTION DIALOG
  // ==========================================================

  void showStatusDialog() {
    if (isConnected.value) return;
    if (!_initialCheckCompleted) return;
    if (_dialogOpen) return;
    if (Get.context == null) return;

    if (WidgetsBinding.instance.lifecycleState !=
        AppLifecycleState.resumed) {
      return;
    }

    _dialogOpen = true;

    AppDialogs.showInternetRequired(
      message:
          'Your network connection is not available.\n\n'
          'Please turn on Wi-Fi or Mobile Data '
          'and try again.',
      onRetry: () {
        checkNow();
      },
    ).whenComplete(() {
      _dialogOpen = false;

      if (!isConnected.value &&
          WidgetsBinding.instance.lifecycleState ==
              AppLifecycleState.resumed) {
        Future.delayed(
          const Duration(milliseconds: 500),
          () {
            showStatusDialog();
          },
        );
      }
    });
  }

  // ==========================================================
  // CLOSE CONNECTION DIALOG
  // ==========================================================

  void _closeInternetDialog() {
    if (!_dialogOpen) return;

    if (Get.isDialogOpen == true) {
      Get.back();
    }
  }

  // ==========================================================
  // WAIT UNTIL NETWORK IS AVAILABLE
  // ==========================================================

  Future<void> waitUntilConnected() async {
    while (!isConnected.value) {
      // Create completer before checking.
      final completer =
          _connectionCompleter ??= Completer<void>();

      await checkNow();

      if (isConnected.value) {
        return;
      }

      // Wait until network becomes available.
      await completer.future;
    }
  }

  // ==========================================================
  // APP LIFECYCLE
  // ==========================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      checkNow();
    }
  }

  // ==========================================================
  // CLEANUP
  // ==========================================================

  @override
  void onClose() {
    _timer?.cancel();
    _subscription?.cancel();

    WidgetsBinding.instance.removeObserver(this);

    final completer = _connectionCompleter;

    if (completer != null &&
        !completer.isCompleted) {
      completer.complete();
    }

    _connectionCompleter = null;

    super.onClose();
  }
}
