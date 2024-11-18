import 'package:flutter/material.dart';

import '../../pages/homepage.dart';
import '../../pages/messages_page.dart';
import '../../pages/profile_page.dart';
import '../../pages/services_page.dart';

class BottomNavigations extends StatefulWidget {
  @override
  _BottomNavigations createState() => _BottomNavigations();
}

class _BottomNavigations extends State<BottomNavigations> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    HomePage(),
    ServicesPage(),
    MessagesPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.pets_outlined), label: 'Services'),
          BottomNavigationBarItem(
              icon: Icon(Icons.message_rounded), label: 'Messages'),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_circle), label: 'Profile'),
        ],
        currentIndex: _currentIndex,
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
