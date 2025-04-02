import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vetconnect/pages/appointment_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class DoctorProfilePage extends StatefulWidget {
  final String name;
  final String clinicName;
  final String imagePath;
  final int vetId;

  const DoctorProfilePage({
    Key? key,
    required this.name,
    required this.clinicName,
    required this.imagePath,
    required this.vetId,
  }) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String vetName = "";
  late TextEditingController reviewController;
  List<Map<String, dynamic>> reviews = [];
  int? ownerId;
  bool isLoading = true;
  bool isSubmittingReview = false;
  bool isFavorite = false;
  int _currentTabIndex = 0;
  String specialization = "";
  int? loggedInUserId;
  List<Map<String, dynamic>> favoriteVeterinarians = [];
  bool isBookmarked = false;

  @override
  void initState() {
    super.initState();
    reviewController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to update the state when tab changes
    _tabController.addListener(_handleTabChange);

    // Initialize with the name from props while we fetch the real data
    vetName = "Dr. ${widget.name}";

    setState(() {
      isBookmarked = favoriteVeterinarians.any((fav) => fav["id"] == widget.vetId);
    });
    // Load all data
    fetchVetDetails();
    fetchUserId(FirebaseAuth.instance.currentUser?.email ?? "");
    fetchReviews();
  }

  void _handleTabChange() {
    // Only update if the tab index actually changed
    if (_tabController.indexIsChanging ||
        _currentTabIndex != _tabController.index) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    reviewController.dispose();
    super.dispose();
  }

  Future<void> fetchVetDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://192.168.107.58:5000/get_vet_name?vet_id=${widget.vetId}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          vetName = "Dr. ${data['name']}";

          // Ensure specialization is stored as a list
          specialization = data['specialization'];

          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching vet details: $e");
      setState(() {
        isLoading = false;
      });
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
        Uri.parse('http://192.168.107.58:5000/add_favorite'),
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
        Uri.parse('http://192.168.107.58:5000/remove_favorite'),
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
        Uri.parse('http://192.168.107.58:5000/get_favorites?owner_id=$ownerId'),
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

  Future<void> fetchUserId(String email) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final response = await http.get(
        Uri.parse("http://192.168.107.58:5000/get_user?email=${user.email}"),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          ownerId = data["id"];
        });
      }
    } catch (e) {
      print("Error fetching user ID: $e");
    }
  }

  Future<void> fetchReviews() async {
    try {
      final response = await http.get(
        Uri.parse(
            "http://192.168.107.58:5000/get_reviews?vet_id=${widget.vetId}"),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        setState(() {
          reviews = data.map((review) {
            String dateStr = "Recently";
            if (review["created_at"] != null) {
              try {
                DateTime date = DateTime.parse(review["created_at"]);
                date = date.toLocal();
                dateStr = DateFormat('MMM d, yyyy • h:mm a').format(date);
              } catch (e) {
                print("Error parsing date: $e");
              }
            }

            return {
              "user_name": review["user_name"] ?? "Anonymous",
              "review_text": review["review_text"] ?? "No review provided",
              "date": dateStr,
            };
          }).toList();
        });
      } else {
        print("Failed to fetch reviews: ${response.body}");
      }
    } catch (e) {
      print("Error fetching reviews: $e");
    }
  }

  Future<void> submitReview(String reviewText) async {
    if (ownerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please sign in to submit a review")),
      );
      return;
    }

    if (reviewText.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please enter a review")),
      );
      return;
    }

    setState(() {
      isSubmittingReview = true;
    });

    try {
      final response = await http.post(
        Uri.parse('http://192.168.107.58:5000/submit_review'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "veterinarian_id": widget.vetId,
          "owner_id": ownerId,
          "review_text": reviewText,
        }),
      );

      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Review submitted successfully"),
            backgroundColor: Colors.green,
          ),
        );

        await fetchReviews();
        reviewController.clear();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to submit review. Please try again."),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("An error occurred. Please try again."),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmittingReview = false;
      });
    }
  }

  void toggleFavorite() {
    setState(() {
      isFavorite = !isFavorite;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(isFavorite
            ? "Added Dr. ${widget.name} to favorites"
            : "Removed Dr. ${widget.name} from favorites"),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vetName),
        backgroundColor: Colors.lightBlue,
        actions: [
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
                          await removeFavorite(widget.vetId);
                        } else {
                          await bookmarkVeterinarian(widget.vetId);
                        }
                      },
                    ),
        ],
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Doctor Image
                  Container(
                    height: 250,
                    width: double.infinity,
                    child: Image.asset(
                      widget.imagePath,
                      fit: BoxFit.cover,
                    ),
                  ),

                  // Doctor Info
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                vetName,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.location_on,
                                color: Colors.grey[600], size: 16),
                            SizedBox(width: 4),
                            Text(
                              widget.clinicName,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 16),
                        specialization.isNotEmpty
                            ? Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children:
                                    specialization.split(',').map((specialty) {
                                  return Chip(
                                    label: Text(specialty.trim()),
                                    backgroundColor:
                                        Colors.blue.withOpacity(0.1),
                                    labelStyle:
                                        TextStyle(color: Colors.blue[700]),
                                  );
                                }).toList(),
                              )
                            : SizedBox(),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.lightBlue,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Colors.lightBlue,
                      tabs: [
                        Tab(text: "About"),
                        Tab(text: "Reviews"),
                      ],
                    ),
                  ),

                  // Tab Content - Using visibility instead of IndexedStack for better performance
                  _currentTabIndex == 0 ? _buildAboutTab() : Container(),
                  _currentTabIndex == 1 ? _buildReviewsTab() : Container(),

                  // Services Section
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Services",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 16),
                        _buildServicesSection(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "About",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Hello! I'm $vetName, a dedicated veterinarian with 4 years of experience in caring for animals of all shapes and sizes. I specialize in small animal medicine and I believe in a gentle, personalized approach to veterinary care.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    "Whether it's a routine check-up, preventive care, or a complex medical case, I'm here to ensure your furry (or feathered!) friend gets the best treatment possible.",
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Working Hours",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  _buildWorkingHoursItem(
                      "Monday - Friday", "9:00 AM - 5:00 PM"),
                  _buildWorkingHoursItem("Saturday", "10:00 AM - 2:00 PM"),
                  _buildWorkingHoursItem("Sunday", "Closed"),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkingHoursItem(String days, String hours) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            width: 120,
            child: Text(
              days,
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reviews (${reviews.length})",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 16),

          // Reviews List
          reviews.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.rate_review_outlined,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No reviews yet",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Be the first to review Dr. ${widget.name}",
                          style: TextStyle(
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    final review = reviews[index];
                    final userName = review["user_name"] ?? "Anonymous";

                    return Card(
                      margin: EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.blue,
                                  child: Text(
                                    userName.isNotEmpty
                                        ? userName[0].toUpperCase()
                                        : "A",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        review["date"] ?? "Recently",
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 12),
                            Text(
                              review["review_text"] ?? "No review text",
                              style: TextStyle(
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

          // Review Input
          SizedBox(height: 24),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Write a Review",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 16),
                  TextField(
                    controller: reviewController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          "Share your experience with Dr. ${widget.name}...",
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      ElevatedButton(
                        onPressed: isSubmittingReview
                            ? null
                            : () => submitReview(reviewController.text),
                        child: isSubmittingReview
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : Text("Submit Review"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.lightBlue,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
                "Book an Appointment",
                Icons.calendar_today,
                Colors.green.shade100,
                Colors.green.shade900,
                () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          AppointmentPage(vetId: widget.vetId),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildServiceCard(
                "Consultation",
                Icons.chat,
                Colors.blue.shade100,
                Colors.blue.shade900,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Consultation feature coming soon")),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildServiceCard(
                "Request a Call",
                Icons.phone,
                Colors.red.shade100,
                Colors.red.shade900,
                () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Call request feature coming soon")),
                  );
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildServiceCard(
    String title,
    IconData icon,
    Color bgColor,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 100,
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 32,
              color: textColor,
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
