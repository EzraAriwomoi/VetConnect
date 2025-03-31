import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:vetconnect/pages/doc_profile.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/pages/fullmap_view.dart';
import 'package:geolocator/geolocator.dart';

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
  String? loggedInUserName;
  Set<Marker> _markers = {};
  GoogleMapController? _mapController;
  LatLng _initialPosition =
      LatLng(-1.286389, 36.817223); // Default location (Nairobi)
  bool _locationFetched = false;

  Future<void> fetchVeterinarians() async {
    try {
      final response =
          await http.get(Uri.parse('http://192.168.166.58:5000/veterinarians'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          veterinarians = List<Map<String, dynamic>>.from(
            data['veterinarians'].map((vet) => {
                  "id": vet["id"] ?? 0,
                  "name": vet["name"],
                  "clinicName": vet["clinic"],
                  "imagePath":
                      vet["profile_image"] ?? "assets/default_profile.png",
                  "location":
                      vet["location"] ?? {"lat": -1.286389, "lng": 36.817223},
                }),
          );

          // Add markers for each vet
          _markers = veterinarians.map((vet) {
            return Marker(
              markerId: MarkerId('vet_${vet["id"]}'),
              position: LatLng(vet["location"]["lat"] ?? -1.286389,
                  vet["location"]["lng"] ?? 36.817223),
              infoWindow: InfoWindow(
                title: vet["name"],
                snippet: vet["clinicName"],
              ),
            );
          }).toSet();

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
    if (email.isEmpty) return;

    print("Fetching user ID for: $email");

    try {
      final response = await http.get(
        Uri.parse('http://192.168.166.58:5000/get_user?email=$email'),
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
    } catch (e) {
      print("Exception fetching user ID: $e");
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

    try {
      final response = await http.post(
        Uri.parse('http://192.168.166.58:5000/add_favorite'),
        headers: {"Content-Type": "application/json"},
        body:
            jsonEncode({"owner_id": loggedInUserId, "veterinarian_id": vetId}),
      );

      if (response.statusCode == 201) {
        print("Veterinarian bookmarked successfully");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Veterinarian added to favorites!"),
            backgroundColor: const Color.fromARGB(255, 54, 155, 58),
          ),
        );

        // Update favorites list
        await fetchFavorites(loggedInUserId!);
      } else {
        print("Error bookmarking veterinarian: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to add favorite"),
            backgroundColor: const Color.fromARGB(255, 250, 109, 99),
          ),
        );
      }
    } catch (e) {
      print("Exception bookmarking veterinarian: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error adding favorite: $e"),
          backgroundColor: const Color.fromARGB(255, 250, 109, 99),
        ),
      );
    }
  }

  Future<void> removeFavorite(int vetId) async {
    if (loggedInUserId == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.166.58:5000/remove_favorite'),
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

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from favorites"),
            backgroundColor: Colors.grey[700],
          ),
        );
      } else {
        print("Error removing favorite: ${response.body}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to remove favorite"),
            backgroundColor: const Color.fromARGB(255, 250, 109, 99),
          ),
        );
      }
    } catch (e) {
      print("Exception removing favorite: $e");
    }
  }

  Future<void> fetchFavorites(int ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.166.58:5000/get_favorites?owner_id=$ownerId'),
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

  Future<void> fetchUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://192.168.166.58:5000/get_user?email=${user.email}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          loggedInUserId = data["id"];
          loggedInUserName = data["name"];
        });

        // Now that we have the user ID, fetch favorites
        if (loggedInUserId != null) {
          fetchFavorites(loggedInUserId!);
        }
      }
    } catch (e) {
      print("Error fetching user data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchVeterinarians();
    fetchUserData();
    _determinePosition();

    // Start auto-sliding
    Future.delayed(Duration(seconds: 3), _autoSlide);

    // Listen for scroll to show/hide app bar title
    _scrollController.addListener(() {
      setState(() {
        _showAppBarTitle = _scrollController.offset > 100;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _autoSlide() {
    if (_pageController.hasClients) {
      // Fixed to use the actual number of slides (4)
      int nextPage = (_currentPage + 1) % 4;
      _pageController.animateToPage(nextPage,
          duration: Duration(seconds: 1), curve: Curves.easeInOut);
      setState(() {
        _currentPage = nextPage;
      });
      Future.delayed(Duration(seconds: 5), _autoSlide);
    }
  }

  void _viewAllVeterinarians() {
    // TODO: Implement navigation to all veterinarians page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("View all veterinarians coming soon!"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _openFullMapView() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullMapView(
          veterinarians: veterinarians,
        ),
      ),
    );
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return;
    }

    // Check for location permissions
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return;
    }

    // Get the current position
    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    LatLng userPosition = LatLng(position.latitude, position.longitude);

    setState(() {
      _initialPosition = userPosition;
      _markers.clear(); // Clear previous markers
      _markers.add(
        Marker(
          markerId: MarkerId("userLocation"),
          position: userPosition,
          infoWindow: InfoWindow(title: "You are here"),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
        ),
      );
    });

    // Move camera to the user's location
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: userPosition, zoom: 15),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 250),
          child: Text(
            'VetConnect',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 39, 39, 39),
            ),
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: _showAppBarTitle ? 4 : 0,
        actions: [
          IconButton(
            icon: Icon(Icons.search_rounded),
            tooltip: 'Search',
            iconSize: 24,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Search feature coming soon!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.calendar_today),
            tooltip: 'Appointments',
            iconSize: 22,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Appointments feature coming soon!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.notifications),
            tooltip: 'Notifications',
            iconSize: 24,
            color: const Color.fromARGB(255, 39, 39, 39),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Notifications feature coming soon!"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await fetchVeterinarians();
          if (loggedInUserId != null) {
            await fetchFavorites(loggedInUserId!);
          }
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome Section with Gradient
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.lightBlue, Colors.lightBlue.shade300],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius:
                      BorderRadius.vertical(bottom: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Welcome ${loggedInUserName ?? "User"}',
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

              // Health Tips Slider
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 10),
                      child: Text(
                        'Pet Health Tips',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.lightBlue,
                        ),
                      ),
                    ),
                    Container(
                      height: 220,
                      child: PageView(
                        controller: _pageController,
                        onPageChanged: (page) {
                          setState(() {
                            _currentPage = page;
                          });
                        },
                        children: [
                          _buildAnimalSlider(
                            imagePath: 'assets/disease_awareness.jpg',
                            description:
                                'Is your pet coughing a lot? It might be kennel cough! Learn the signs & treatments.',
                            showIcon: true,
                          ),
                          _buildAnimalSlider(
                            imagePath: 'assets/pet_food.jpg',
                            description:
                                'Not all human foods are safe for pets! Discover the best diet for a healthy pet.',
                            showIcon: true,
                          ),
                          _buildAnimalSlider(
                            imagePath: 'assets/first_aid.jpg',
                            description:
                                'Does your pet have an emergency? Learn quick first-aid tips that can save a life!',
                            showIcon: true,
                          ),
                          _buildAnimalSlider(
                            imagePath: 'assets/grooming.jpg',
                            description:
                                'Bad pet odor? Here`s how to keep your pet fresh, clean, and healthy!',
                            showIcon: true,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 15),
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(4, (index) {
                          return AnimatedContainer(
                            duration: Duration(milliseconds: 300),
                            margin: EdgeInsets.symmetric(horizontal: 5),
                            height: 8,
                            width: _currentPage == index ? 24 : 8,
                            decoration: BoxDecoration(
                              color: _currentPage == index
                                  ? Colors.lightBlue
                                  : Colors.grey[400],
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Map Section
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
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Stack(
                          children: [
                            GoogleMap(
                              initialCameraPosition: CameraPosition(
                                target: _initialPosition,
                                zoom: 12,
                              ),
                              markers: _markers,
                              onMapCreated: (GoogleMapController controller) {
                                _mapController = controller;
                                if (_locationFetched) {
                                  _mapController?.animateCamera(
                                    CameraUpdate.newCameraPosition(
                                      CameraPosition(
                                          target: _initialPosition, zoom: 15),
                                    ),
                                  );
                                }
                              },
                              myLocationEnabled: true,
                              myLocationButtonEnabled: true,
                              zoomControlsEnabled: false,
                            ),
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 4,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: IconButton(
                                  icon: Icon(Icons.fullscreen),
                                  onPressed: _openFullMapView,
                                  tooltip: 'Full Map View',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 30),

              // Veterinarians Section
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
                          onPressed: _viewAllVeterinarians,
                          child: Row(
                            children: [
                              Text(
                                'See All',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.lightBlue,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Icon(Icons.arrow_forward,
                                  size: 16, color: Colors.lightBlue),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),

                    // Veterinarians List
                    isLoading
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20.0),
                              child: CircularProgressIndicator(),
                            ),
                          )
                        : veterinarians.isEmpty
                            ? _buildEmptyState(
                                icon: Icons.person_search,
                                message: "No veterinarians found",
                                subMessage:
                                    "Please check your connection and try again")
                            : ListView.builder(
                                shrinkWrap: true,
                                physics: NeverScrollableScrollPhysics(),
                                itemCount: veterinarians.length,
                                itemBuilder: (context, index) {
                                  final vet = veterinarians[index];
                                  return _buildVeterinarianCard(vet);
                                },
                              ),
                  ],
                ),
              ),
              SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVeterinarianCard(Map<String, dynamic> vet) {
    bool isBookmarked =
        favoriteVeterinarians.any((fav) => fav["id"] == vet["id"]);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorProfilePage(
                  vetId: vet["id"],
                  name: vet["name"]!,
                  clinicName: vet["clinicName"]!,
                  imagePath: vet["imagePath"]!,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Vet Image
                Hero(
                  tag: 'vet_${vet["id"]}',
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 4,
                          spreadRadius: 1,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: vet["imagePath"] != null &&
                              vet["imagePath"]!.startsWith("http")
                          ? Image.network(
                              vet["imagePath"]!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Image.asset(
                                  'assets/default_profile.png',
                                  fit: BoxFit.cover,
                                );
                              },
                            )
                          : Image.asset(
                              'assets/default_profile.png',
                              fit: BoxFit.cover,
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Vet Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              vet["name"]!,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Icon(
                            Icons.verified,
                            size: 18,
                            color: Colors.blueAccent,
                          ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        vet["clinicName"]!,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.redAccent,
                          ),
                          SizedBox(width: 4),
                          Text(
                            "2.5 km", // Sample distance
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Action Buttons
                Column(
                  children: [
                    IconButton(
                      icon: Icon(
                        isBookmarked
                            ? Icons.bookmark
                            : Icons.bookmark_border_outlined,
                        color: isBookmarked ? Colors.lightBlue : Colors.grey,
                        size: 28,
                      ),
                      onPressed: () async {
                        if (isBookmarked) {
                          await removeFavorite(vet["id"]);
                        } else {
                          await bookmarkVeterinarian(vet["id"]);
                        }
                      },
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.lightBlue,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.lightBlue.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 1,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => DoctorProfilePage(
                                vetId: vet["id"],
                                name: vet["name"]!,
                                clinicName: vet["clinicName"]!,
                                imagePath: vet["imagePath"]!,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(
                          Icons.arrow_forward,
                          size: 18,
                          color: Colors.white,
                        ),
                        tooltip: 'View Profile',
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
      ),
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String message,
    required String subMessage,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 30),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 70,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            subMessage,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAnimalSlider({
    required String imagePath,
    required String description,
    bool showIcon = true,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(imagePath),
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withOpacity(0.7),
                      Colors.transparent,
                    ],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
            ),
            if (showIcon)
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  padding: EdgeInsets.all(6),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.amberAccent,
                    size: 22,
                  ),
                ),
              ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
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
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    SizedBox(height: 6),
                    GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Article coming soon!"),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Read More',
                            style: TextStyle(
                              color: Colors.lightBlueAccent,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 4),
                          Icon(
                            Icons.arrow_forward,
                            size: 14,
                            color: Colors.lightBlueAccent,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
