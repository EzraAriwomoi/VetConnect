import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:vetconnect/pages/appointment_page.dart';
import 'package:http/http.dart' as http;

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
  String vetName = "User";
  late TextEditingController reviewController;
  List<Map<String, dynamic>> reviews = [];
  int? ownerId;

  @override
  void initState() {
    super.initState();
    fetchVetDetails();
    fetchUserId();
    fetchReviews();
    reviewController = TextEditingController();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> fetchVetDetails() async {
    final response = await http.get(
      Uri.parse(
          "http://192.168.201.58:5000/get_vet_name?vet_id=${widget.vetId}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        vetName = "Dr. ${data['name']}";
      });
    } else {
      setState(() {
        vetName = "Vet Not Found";
      });
    }
  }

  Future<void> fetchUserId() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await http.get(
      Uri.parse("http://192.168.201.58:5000/get_user?email=${user.email}"),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        ownerId = data["id"];
      });
    }
  }

  Future<void> fetchReviews() async {
    final response = await http.get(
      Uri.parse(
          "http://192.168.201.58:5000/get_reviews?vet_id=${widget.vetId}"),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      setState(() {
        reviews = data.map((review) {
          return {
            "user_name": review["user_name"] ?? "Unknown User",
            "review_text": review["review_text"] ?? "No review provided",
          };
        }).toList();
      });
    } else {
      print("Failed to fetch reviews: ${response.body}");
    }
  }

  Future<void> submitReview(String reviewText) async {
    if (ownerId == null) {
      print("Error: Owner ID not found.");
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.201.58:5000/submit_review'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "veterinarian_id": widget.vetId,
        "owner_id": ownerId,
        "review_text": reviewText,
      }),
    );

    if (response.statusCode == 201) {
      fetchReviews();
      reviewController.clear();
    } else {
      print("Failed to submit review: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(vetName),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              child: Image.asset(
                widget.imagePath,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Text(
                    vetName,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 5),
                  const Icon(Icons.verified,
                      color: Colors.blueAccent, size: 18),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: const Color.fromARGB(255, 196, 230, 247),
                  borderRadius: BorderRadius.circular(2),
                ),
                labelColor: Colors.lightBlue,
                unselectedLabelColor: Colors.grey,
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(text: "About"),
                  Tab(text: "Reviews"),
                ],
              ),
            ),
            SizedBox(
              height: 300,
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildAboutTab(),
                  buildReviewsTab(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  const Icon(Icons.location_on,
                      color: Colors.blueAccent, size: 22),
                  const SizedBox(width: 5),
                  Text(
                    "Location: ${widget.clinicName}",
                    style: const TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text(
                "Services",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            buildServicesSection(),
            const SizedBox(height: 200),
          ],
        ),
      ),
    );
  }

  Widget buildAboutTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      child: Container(
        padding: EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 2,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello! I'm $vetName, a dedicated veterinarian with 4 years of experience in caring for animals of all shapes and sizes. I specialize in small animal medicine and I believe in a gentle, personalized approach to veterinary care. Whether it's a routine check-up, preventive care, or a complex medical case, I'm here to ensure your furry (or feathered!) friend gets the best treatment possible.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReviewsTab() {
    return Column(
      children: [
        Expanded(
          child: reviews.isEmpty
              ? Center(child: Text("No reviews yet. Be the first to review!"))
              : ListView.builder(
                  shrinkWrap: false,
                  physics: AlwaysScrollableScrollPhysics(),
                  itemCount: reviews.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        backgroundImage: reviews[index]["user_image"] != null &&
                                reviews[index]["user_image"].isNotEmpty
                            ? NetworkImage(reviews[index]["user_image"])
                            : null,
                        child: reviews[index]["user_image"] == null ||
                                reviews[index]["user_image"].isEmpty
                            ? Text(
                                reviews[index]["user_name"][0],
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      title: Text(
                        reviews[index]["user_name"],
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(reviews[index]["review_text"]),
                    );
                  },
                ),
        ),
        SafeArea(
          child: Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: reviewController,
                    decoration: InputDecoration(
                      hintText: "Write a review...",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blueAccent),
                  onPressed: () {
                    if (reviewController.text.isNotEmpty) {
                      submitReview(reviewController.text);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            AppointmentPage(vetId: widget.vetId),
                      ),
                    );
                  },
                  child:
                      serviceCard("Book an appointment", Icons.calendar_today),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: serviceCard("Consultation", Icons.chat),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              SizedBox(
                width: MediaQuery.of(context).size.width * 0.45,
                child: serviceCard("Request a call", Icons.phone),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget serviceCard(String title, IconData icon) {
    final Map<String, Color> bgColors = {
      "Book an appointment": const Color.fromARGB(255, 200, 252, 226),
      "Consultation": const Color.fromARGB(255, 216, 230, 252),
      "Request a call": const Color.fromARGB(255, 252, 225, 223),
    };

    // Text colors
    final Map<String, Color> textColors = {
      "Book an appointment": Colors.green.shade900,
      "Consultation": Colors.blue.shade900,
      "Request a call": Colors.red.shade900,
    };

    // Default colors
    Color bgColor = bgColors[title] ?? Colors.grey.shade300;
    Color textColor = textColors[title] ?? Colors.black;

    return Container(
      height: 70,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 23, color: textColor),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
