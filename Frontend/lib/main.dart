import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:vetconnect/components/themes/darkmode.dart';
import 'package:vetconnect/components/themes/lightmode.dart';
// import 'package:vetconnect/pages/guides/user_guide1.dart';
import 'package:vetconnect/pages/login_page.dart';
// import 'package:vetconnect/pages/homepage.dart';
// import 'components/controls/bottom_navigations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: "AIzaSyAggBkk__X2Box91ioGpMyucZnEFi8NpnA",
        authDomain: "vetconnect-4da18.firebaseapp.com",
        databaseURL: "https://vetconnect-4da18-default-rtdb.firebaseio.com",
        projectId: "vetconnect-4da18",
        storageBucket: "vetconnect-4da18.firebasestorage.app",
        messagingSenderId: "116273557236",
        appId: "1:116273557236:web:91be5f1a9fb0f7c071f8a1",
        measurementId: "G-MEASUREMENT_ID"
      ),
    );
  } else {
    await Firebase.initializeApp();
  }

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
