import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:namma_karnataka_app/routes/app_pages.dart';

import 'package:namma_karnataka_app/routes/app_routes.dart';

class NammaKarnatakaApp extends StatelessWidget {
  const NammaKarnatakaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Namma Karnataka",
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      initialRoute: AppRoutes.splash,
      getPages: AppPages.pages,
      builder: EasyLoading.init(),
    );
  }
}
