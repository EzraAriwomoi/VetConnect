import 'package:flutter/material.dart';
import 'package:vetconnect/components/themes/darkmode.dart';
import 'package:vetconnect/components/themes/lightmode.dart';
// import 'package:vetconnect/pages/guides/user_guide1.dart';
import 'package:vetconnect/pages/login_page.dart';
// import 'package:vetconnect/pages/homepage.dart';
// import 'components/controls/bottom_navigations.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'VetConnect',
      theme: lightTheme(),
      darkTheme: darkTheme(),
      themeMode: ThemeMode.system,
      // home: BottomNavigations(),
      home: const LoginPage(),
    );
  }
}
