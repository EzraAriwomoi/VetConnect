import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // PageController to control the PageView
  PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();

    // Automatically change the page every 3 seconds
    Future.delayed(Duration(seconds: 3), _autoSlide);
  }

  // Function to change the page every 3 seconds
  void _autoSlide() {
    if (_pageController.hasClients) {
      int nextPage = (_currentPage + 1) % 3; // Loop back to the first card
      _pageController.animateToPage(nextPage,
          duration: Duration(seconds: 1), curve: Curves.easeInOut);
      setState(() {
        _currentPage = nextPage;
      });

      // Call the function again to keep sliding
      Future.delayed(Duration(seconds: 3), _autoSlide);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('VetConnect',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Welcome Section
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.lightBlue,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(20)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome to VetConnect!',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connecting you with veterinary care at your fingertips.',
                    style: TextStyle(fontSize: 16, color: Colors.white70),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),

            // Main Features Section with Card Slideshow
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                height: 300, // Height of the card slideshow
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildFeatureCard(
                      icon: Icons.search,
                      title: 'Find a Veterinarian',
                      description: 'Locate veterinarians near you.',
                      onTap: () {
                        // Navigation to map or search feature
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.calendar_today,
                      title: 'Book an Appointment',
                      description: 'Schedule consultations with ease.',
                      onTap: () {
                        // Navigation to booking screen
                      },
                    ),
                    _buildFeatureCard(
                      icon: Icons.help_outline,
                      title: 'Helpdesk',
                      description: 'Get support for your veterinary needs.',
                      onTap: () {
                        // Navigation to helpdesk feature
                      },
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 10),
            // Dots Indicator
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return AnimatedContainer(
                    duration: Duration(milliseconds: 300),
                    margin: EdgeInsets.symmetric(horizontal: 5),
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: _currentPage == index
                          ? Colors.lightBlue
                          : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              ),
            ),
            SizedBox(height: 20),

            // Information Section
            Container(
              padding: EdgeInsets.all(20),
              color: Colors.lightBlue.withOpacity(0.1),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Why Choose VetConnect?',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'VetConnect is designed to make accessing veterinary care simple and efficient. Whether you\'re an animal owner or a veterinarian, our platform offers seamless communication, appointment booking, and access to health records.',
                    style: TextStyle(fontSize: 16, color: Colors.black54),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // Ensures that all items (icons and labels) are visible
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pets_outlined),
            label: 'Services',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.message_rounded),
            label: 'Chat',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle),
            label: 'Profile',
          ),
        ],
        selectedItemColor: Colors.lightBlue,
        unselectedItemColor: Colors.grey,
        onTap: (index) {
          // Handle navigation to different sections based on index
        },
      ),
    );
  }

  // Helper function to build feature cards
  Widget _buildFeatureCard(
      {required IconData icon,
      required String title,
      required String description,
      required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        margin: EdgeInsets.symmetric(horizontal: 5, vertical: 25),
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.01),
                blurRadius: 10,
                offset: Offset(4, 0),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 50, color: Colors.lightBlue),
              SizedBox(height: 15),
              Text(
                title,
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: Colors.lightBlue),
              ),
              SizedBox(height: 10),
              Text(
                description,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
