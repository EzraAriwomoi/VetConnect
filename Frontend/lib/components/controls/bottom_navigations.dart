import 'package:flutter/material.dart';
import 'package:vetconnect/pages/homepage.dart';
import 'package:vetconnect/pages/messages_page.dart';
import 'package:vetconnect/pages/profile_pages/profile_page_owner.dart';
import 'package:vetconnect/pages/profile_pages/profile_page_vet.dart';
import 'package:vetconnect/pages/services_page.dart';

class BottomNavigations extends StatefulWidget {
  final String userType;

  BottomNavigations({required this.userType});

  @override
  _BottomNavigations createState() => _BottomNavigations();
}

class _BottomNavigations extends State<BottomNavigations> {
  int _currentIndex = 0;

  List<Widget> _pages = [];

  @override
  void initState() {
    super.initState();
    _pages = [
      HomePage(),
      ServicesPage(),
      MessagesPage(),
      widget.userType == "animal_owner" ? ProfilePageOwner() : ProfilePageVet(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white,
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.pets_outlined), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.message_rounded), label: 'Messages'),
          BottomNavigationBarItem(icon: Icon(Icons.account_circle), label: 'Profile'),
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
