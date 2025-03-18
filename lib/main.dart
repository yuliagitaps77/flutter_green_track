import 'package:flutter/material.dart';
import 'package:flutter_green_track/presentation/pages/authentication/LoginScreen.dart';
import 'package:flutter_green_track/presentation/pages/dashboard_tpk/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/presentation/pages/dashboard_tpk/admin_dashboard_tpk_page.dart';
import 'package:flutter_green_track/presentation/pages/intro/intro_page.dart';
import 'package:flutter_green_track/presentation/pages/navigation/navigation_page.dart';
import 'package:flutter_green_track/presentation/pages/navigation/penyemaian/page/page_bibit/page_detail_bibit.dart';
import 'package:flutter_green_track/presentation/pages/navigation/penyemaian/page/page_bibit/page_nav_bibit.dart';
import 'package:get/get.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Aplikasi Bibit Tanaman',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: Color(0xFF4CAF50),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Poppins',
        textTheme: TextTheme(
          displayLarge: TextStyle(
            fontSize: 26.0,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2E7D32),
          ),
          displayMedium: TextStyle(
            fontSize: 20.0,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2E7D32),
          ),
          bodyLarge: TextStyle(
            fontSize: 16.0,
            color: Color(0xFF424242),
          ),
          labelLarge: TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        colorScheme: ColorScheme.light(
          primary: Color(0xFF4CAF50),
          secondary: Color(0xFF8BC34A),
          surface: Colors.white,
          background: Colors.white,
        ),
      ),
      initialRoute: SplashScreen.routeName,
      getPages: [
        GetPage(
          name: DaftarBibitPage.routeName,
          page: () => const DaftarBibitPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: SplashScreen.routeName!,
          page: () => SplashScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: IntroScreen.routeName!,
          page: () => const DaftarBibitPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: BibitDetailPage.routeName,
          page: () => const BibitDetailPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: LoginScreen.routeName!,
          page: () => LoginScreen(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: DaftarBibitPage.routeName,
          page: () => const DaftarBibitPage(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: PenyemaianDashboardScreen.routeName!,
          page: () => PenyemaianDashboardScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: TPKDashboardScreen.routeName!,
          page: () => TPKDashboardScreen(),
          transition: Transition.fadeIn,
        ),
        GetPage(
          name: MainNavigationContainer.routeName,
          page: () => const BibitDetailPage(),
          transition: Transition.rightToLeft,
        ),
        GetPage(
          name: BibitDetailPage.routeName,
          page: () => const BibitDetailPage(),
          transition: Transition.rightToLeft,
        ),
      ],
    );
  }
}
