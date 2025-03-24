import 'package:flutter/material.dart';
import 'package:flutter_green_track/fitur/history_pengisian/page_history_detail_bibit.dart';
import 'package:flutter_green_track/fitur/history_pengisian/page_history_pengisian.dart';
import 'package:get/get.dart';
import 'package:flutter_green_track/fitur/authentication/LoginScreen.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/admin_dashboard_penyemaian.dart';
import 'package:flutter_green_track/fitur/dashboard_tpk/admin_dashboard_tpk_page.dart';
import 'package:flutter_green_track/fitur/intro/intro_page.dart';
import 'package:flutter_green_track/fitur/navigation/navigation_page.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/page/page_bibit/page_detail_bibit.dart';
import 'package:flutter_green_track/fitur/navigation/penyemaian/page/page_bibit/page_nav_bibit.dart';

class AppRoutes {
  // Route names as static constants
  static const String splash = '/splash';
  static const String intro = '/intro';
  static const String login = '/login';
  static const String daftarBibit = '/daftar-bibit';
  static const String bibitDetail = '/bibit-detail';
  static const String navigation = '/navigation';
  static const String penyemaianDashboard = '/penyemaian-dashboard';
  static const String tpkDashboard = '/tpk-dashboard';

  // List of GetX route definitions
  static final List<GetPage> routes = [
    GetPage(
      name: HistoryPengisianPage.routeName,
      page: () => HistoryPengisianPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: DetailBibitPage.routeName,
      page: () => DetailBibitPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: splash,
      page: () => SplashScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: intro,
      page: () => IntroScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: login,
      page: () => LoginScreen(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: daftarBibit,
      page: () => const DaftarBibitPage(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: bibitDetail,
      page: () => const BibitDetailPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: navigation,
      page: () => MainNavigationContainer(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: penyemaianDashboard,
      page: () => PenyemaianDashboardScreen(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: tpkDashboard,
      page: () => TPKDashboardScreen(),
      transition: Transition.fadeIn,
    ),
  ];
}
