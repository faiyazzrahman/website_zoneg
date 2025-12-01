import 'package:flutter/material.dart';
import 'pages/map_page.dart';
import 'pages/login_page.dart';
import 'pages/signup_page.dart';
import 'pages/dashboard_page.dart';
import 'pages/postcrime_page.dart';
import 'pages/inbox_page.dart';
import 'pages/settings_page.dart';
import 'pages/crimeReport.dart';

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zone_guard',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: LoginPage(),
      routes: {
        '/login': (context) => LoginPage(),
        '/signup': (context) => SignupPage(),
        '/dashboard': (context) => DashboardPage(),
        '/map': (context) => MapPage(),
        '/post': (context) => PostCrimePage(),
        '/inbox': (context) => InboxPage(),
        '/settings': (context) => SettingsPage(),
        '/report':(context)=> CrimeReportPage(),
      },
    );
  }
}
