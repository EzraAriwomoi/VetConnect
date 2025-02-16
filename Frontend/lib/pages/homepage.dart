import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vetconnect/pages/doc_profile.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController _pageController = PageController();
  ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _showAppBarTitle = false;

  List<Map<String, String>> veterinarians = [
    {
      "name": "Dr. David",
      "clinicName": "Paws Care",
      "imagePath": "assets/user_guide1.png"
    },
    {
      "name": "Dr. Emily",
      "clinicName": "Healthy Pets",
      "imagePath": "assets/user_guide1.png"
    },
    {
      "name": "Dr. David",
      "clinicName": "Paws Care",
      "imagePath": "assets/user_guide1.png"
    },
    {
      "name": "Dr. Emily",
      "clinicName": "Healthy Pets",
      "imagePath": "assets/user_guide1.png"
    },
  ];

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(seconds: 3), _autoSlide);
    _scrollController.addListener(() {
      setState(() {
        _showAppBarTitle = _scrollController.offset > 100;
      });
    });
  }

  void _autoSlide() {
    if (_pageController.hasClients) {
      int nextPage = (_currentPage + 1) % 3;
      _pageController.animateToPage(nextPage,
          duration: Duration(seconds: 1), curve: Curves.easeInOut);
      setState(() {
        _currentPage = nextPage;
      });
      Future.delayed(Duration(seconds: 3), _autoSlide);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showAppBarTitle
            ? Text(
                'VetConnect',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: const Color.fromARGB(255, 39, 39, 39),
                ),
              )
            : null,
        backgroundColor: Colors.lightBlue,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            iconSize: 24,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            iconSize: 22,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {},
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            iconSize: 24,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
                    'Welcome Ezra',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 39, 39, 39),
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Connecting you with veterinary care at your fingertips.',
                    style: TextStyle(
                      fontSize: 16,
                      color: const Color.fromARGB(255, 71, 70, 70),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Container(
                height: 250,
                width: 12,
                child: PageView(
                  controller: _pageController,
                  onPageChanged: (page) {
                    setState(() {
                      _currentPage = page;
                    });
                  },
                  children: [
                    _buildAnimalSlider(
                      imagePath: 'assets/user_guide1.png',
                      description: 'This is a description for animal 1...',
                      showIcon: true,
                    ),
                    _buildAnimalSlider(
                      imagePath: 'assets/user_guide1.png',
                      description: 'Here\'s some info about animal 2...',
                      showIcon: false,
                    ),
                    _buildAnimalSlider(
                      imagePath: 'assets/user_guide1.png',
                      description: 'Details regarding animal 3 are here...',
                      showIcon: true,
                    ),
                    _buildAnimalSlider(
                      imagePath: 'assets/user_guide1.png',
                      description: 'Details regarding animal 4 are here...',
                      showIcon: false,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
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
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discover the nearest vet for your animal',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.lightBlue,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Use our interactive map to find the closest veterinary clinics in your area. Simply input your location and let us guide you to the nearest expert care for your animal.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                    ),
                  ),
                  SizedBox(height: 20),
                  Container(
                    height: 250,
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(-1.286389, 36.817223),
                        zoom: 12,
                      ),
                      onMapCreated: (GoogleMapController controller) {},
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Our Best Veterinarians',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                      TextButton(
                        onPressed: () {},
                        child: Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.lightBlue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 15),
                  SizedBox(
                    height: 250,
                    child: ListView.builder(
                      itemCount: veterinarians.length,
                      itemBuilder: (context, index) {
                        final vet = veterinarians[index];
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorProfilePage(
                                  name: vet["name"]!,
                                  clinicName: vet["clinicName"]!,
                                  imagePath: vet["imagePath"]!,
                                ),
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 10,
                                  spreadRadius: 2,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.asset(
                                      vet["imagePath"]!,
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              vet["name"]!,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 5),
                                            Icon(
                                              Icons.verified,
                                              size: 16,
                                              color: Colors.blueAccent,
                                            ),
                                          ],
                                        ),
                                        Text(
                                          vet["clinicName"]!,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.bookmark_border_outlined,
                                        color: Colors.black,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 20),
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: const BoxDecoration(
                                          color: Colors.black,
                                          shape: BoxShape.circle,
                                        ),
                                        child: IconButton(
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    DoctorProfilePage(
                                                  name: vet["name"]!,
                                                  clinicName:
                                                      vet["clinicName"]!,
                                                  imagePath: vet["imagePath"]!,
                                                ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(Icons.arrow_forward,
                                              size: 20, color: Colors.white),
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimalSlider({
    required String imagePath,
    required String description,
    bool showIcon = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage(imagePath),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          if (showIcon)
            Positioned(
              top: 10,
              left: 10,
              child: Icon(
                Icons.info,
                color: const Color.fromARGB(255, 240, 225, 89),
                size: 22,
              ),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  SizedBox(height: 5),
                  GestureDetector(
                    onTap: () {},
                    child: Text(
                      '...READ MORE',
                      style: TextStyle(
                        color: Colors.lightBlue,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
