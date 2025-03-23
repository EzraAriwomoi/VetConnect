import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vetconnect/pages/doc_profile.dart';
import 'package:http/http.dart' as http;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  PageController _pageController = PageController();
  ScrollController _scrollController = ScrollController();
  int _currentPage = 0;
  bool _showAppBarTitle = false;
  List<Map<String, dynamic>> veterinarians = [];
  bool isLoading = true;
  int? loggedInUserId;
  List<Map<String, dynamic>> favoriteVeterinarians = [];

  Future<void> fetchVeterinarians() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.201.58:5000/veterinarians'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          veterinarians = List<Map<String, dynamic>>.from(
            data['veterinarians'].map((vet) => {
                  "id": vet["id"] ?? 0,
                  "name": vet["name"],
                  "clinicName": vet["clinic"],
                  "imagePath": vet["profile_image"] ?? "assets/user_guide1.png"
                }),
          );
          isLoading = false;
        });
      } else {
        throw Exception("Failed to load veterinarians");
      }
    } catch (e) {
      print("Error fetching veterinarians: $e");
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchUserId(String email) async {
    print("Fetching user ID for: $email");

    final response = await http.get(
      Uri.parse('http://192.168.201.58:5000/get_user?email=$email'),
    );

    print("Response from get_user: ${response.body}");

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      if (userData.containsKey("id")) {
        setState(() {
          loggedInUserId = userData["id"];
        });
        print("User ID set: $loggedInUserId");
      } else {
        print("User ID missing in response");
      }
    } else {
      print("Error fetching user ID: ${response.body}");
    }
  }

  Future<void> bookmarkVeterinarian(int vetId) async {
    print("Bookmarking Vet ID: $vetId");

    if (loggedInUserId == null) {
      print("User ID is null. Fetching again...");
      await fetchUserId(FirebaseAuth.instance.currentUser?.email ?? "");

      if (loggedInUserId == null) {
        print("Still no user ID. Cannot bookmark.");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Please log in first!"),
            backgroundColor: const Color.fromARGB(255, 250, 109, 99),
          ),
        );
        return;
      }
    }

    print("Attempting to bookmark vet $vetId for user $loggedInUserId");

    final response = await http.post(
      Uri.parse('http://192.168.201.58:5000/add_favorite'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"owner_id": loggedInUserId, "veterinarian_id": vetId}),
    );

    if (response.statusCode == 201) {
      print("Veterinarian bookmarked successfully");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Veterinarian added to favorites!"),
          backgroundColor: const Color.fromARGB(255, 54, 155, 58),
        ),
      );
    } else {
      print("Error bookmarking veterinarian: ${response.body}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add favorite"),
          backgroundColor: const Color.fromARGB(255, 250, 109, 99),
        ),
      );
    }
  }

  Future<void> removeFavorite(int vetId) async {
    if (loggedInUserId == null) return;

    final response = await http.delete(
      Uri.parse('http://192.168.201.58:5000/remove_favorite'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "owner_id": loggedInUserId,
        "veterinarian_id": vetId,
      }),
    );

    if (response.statusCode == 200) {
      print("Favorite removed successfully");
      setState(() {
        favoriteVeterinarians.removeWhere((vet) => vet["id"] == vetId);
      });
    } else {
      print("Error removing favorite: ${response.body}");
    }
  }

  Future<void> fetchFavorites(int ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.201.58:5000/get_favorites?owner_id=$ownerId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("Raw Favorites Response: $data");

        setState(() {
          favoriteVeterinarians = List<Map<String, dynamic>>.from(data);
        });

        print("Updated favorite list: $favoriteVeterinarians");
      } else {
        throw Exception("Failed to load favorites");
      }
    } catch (e) {
      print("Error fetching favorites: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVeterinarians();
    fetchUserId(FirebaseAuth.instance.currentUser?.email ?? "").then((_) {
      if (loggedInUserId != null) {
        fetchFavorites(loggedInUserId!);
      }
    });

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
                            margin: const EdgeInsets.symmetric(
                                vertical: 4, horizontal: 4),
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
                              padding: const EdgeInsets.all(6),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: vet["imagePath"] != null &&
                                            vet["imagePath"]!.startsWith("http")
                                        ? Image.network(
                                            vet["imagePath"]!,
                                            width: 75,
                                            height: 75,
                                            fit: BoxFit.cover,
                                            errorBuilder:
                                                (context, error, stackTrace) {
                                              return Image.asset(
                                                  'assets/user_guide1.png',
                                                  width: 75,
                                                  height: 75,
                                                  fit: BoxFit.cover);
                                            },
                                          )
                                        : Image.asset(
                                            'assets/user_guide1.png',
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
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              vet["name"]!,
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      StatefulBuilder(
                                        builder: (context, setStateIcon) {
                                          bool isBookmarked =
                                              favoriteVeterinarians.any((fav) =>
                                                  fav["id"] == vet["id"]);

                                          return IconButton(
                                            icon: Icon(
                                              isBookmarked
                                                  ? Icons.bookmark
                                                  : Icons
                                                      .bookmark_border_outlined,
                                              color: isBookmarked
                                                  ? Colors.black
                                                  : Colors.grey,
                                              size: 30,
                                            ),
                                            onPressed: () async {
                                              if (isBookmarked) {
                                                await removeFavorite(vet["id"]);
                                              } else {
                                                await bookmarkVeterinarian(
                                                    vet["id"]);
                                              }
                                              await fetchFavorites(
                                                  loggedInUserId!);

                                              setStateIcon(() {});
                                              setState(() {});
                                            },
                                          );
                                        },
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
