import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/pages/appointment_details_page.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/animal_details_page.dart';
import 'package:vetconnect/pages/doc_profile.dart';
import 'package:vetconnect/pages/login_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pdf/widgets.dart' as pw;
import 'dart:html' as html;
import 'dart:typed_data';

class ProfilePageVet extends StatefulWidget {
  @override
  _ProfilePageVetState createState() => _ProfilePageVetState();
}

class _ProfilePageVetState extends State<ProfilePageVet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _appointments = [];
  int? loggedInVetId;
  String vetName = "Veterinarian";
  String clinicName = "Clinic Name";
    int? loggedInUserId;
  String specialization = "Specialization";
  String? profileImage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchVetData();
  }

  Future<void> fetchVetData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.107.58:5000/get_user?email=${user.email}'),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        loggedInVetId = data['id'];
        vetName = data['name'];
        clinicName = data['clinic'] ?? "No Clinic Provided";
        specialization = data['specialization'] ?? "No Specialization Provided";
        fetchAppointments();
      });
    }
  }

  Future<void> fetchAppointments() async {
  if (loggedInVetId == null) return;

  final response = await http.get(
    Uri.parse('http://192.168.107.58:5000/get_vet_appointments?veterinarian_id=$loggedInVetId'),
  );

  if (response.statusCode == 200) {
    setState(() {
      _appointments = List<Map<String, dynamic>>.from(jsonDecode(response.body));
    });
  } else {
    print("Failed to fetch appointments: ${response.body}");
  }
}

  void navigateToEditDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => EditVetDetailsPage(vetId: loggedInVetId!)),
    );
  }

  Future<void> _logout(BuildContext context) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('token');

    if (token == null) {
      print("No token found, logging out locally.");
      _clearUserData();
      _navigateToLogin(context);
      return;
    }

    print("Sending logout request with token: $token");

    final response = await http.post(
      Uri.parse('http://192.168.107.58:5000/logout'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      print("Successfully logged out from Flask backend.");
      _clearUserData();
      _navigateToLogin(context);
    } else {
      print("Logout failed: ${response.body}");
    }
  }

  void _clearUserData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('userType');
    await prefs.remove('userId');
  }

  void _navigateToLogin(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print("Navigating to login page");

      if (!context.mounted) return;

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginPage()),
        (route) => false,
      );
    });
  }


   Future<void> _generateUserReport(BuildContext context, int userId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.107.58:5000/user_activity/$userId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("API Response: ${response.body}"); // Debugging

        final List activities =
            data['activities'] ?? []; // Ensure it's not null

        final pdf = pw.Document();
        pdf.addPage(
          pw.Page(
            build: (pw.Context context) => pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text("User Activity Report",
                    style: pw.TextStyle(
                        fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 10),
                pw.Text("Name: ${data['name'] ?? 'N/A'}"),
                pw.Text("Email: ${data['email'] ?? 'N/A'}"),
                pw.SizedBox(height: 10),
                pw.Text("Activities:",
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if (activities.isEmpty)
                  pw.Text("No activities recorded.")
                else
                  ...activities.map((activity) => pw.Text(
                        "- ${activity['type']}: ${activity['description']} on ${activity['timestamp']}",
                      )),
              ],
            ),
          ),
        );

        final Uint8List pdfBytes = await pdf.save();

        final blob = html.Blob([pdfBytes], 'application/pdf');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", "activities.pdf")
          ..click();
        html.Url.revokeObjectUrl(url);
      } else {
        print("Failed to fetch user activity. Status: ${response.statusCode}");
      }
    } catch (e) {
      print("Error generating report: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        title: Text(
          'Profile',
          style: TextStyle(color: Colors.black),
        ),
      actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit_profile') {
                // Navigate to Edit Profile screen
              } else if (value == 'logout') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: Text('Logout'),
                    content: Text('Are you sure you want to log out?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Cancel'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _logout(context);
                        },
                        child: Text('Logout',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 250, 109, 99),
                            )),
                      ),
                    ],
                  ),
                );
              } else if (value == 'download_report') {
                if (loggedInUserId != null) {
                  _generateUserReport(context, loggedInUserId!);
                } else {
                  print("Error: User ID is null. Cannot generate report.");
                }
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit_profile',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Edit Profile'),
                  ],
                ),
                height: 35,
              ),
              PopupMenuItem<String>(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help_outline, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Help'),
                  ],
                ),
                height: 35,
              ),
              PopupMenuItem<String>(
                value: 'download_report',
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: Colors.black),
                    SizedBox(width: 10),
                    Text('Report'),
                  ],
                ),
                height: 35,
              ),
              PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(
                      Icons.logout,
                      color: const Color.fromARGB(255, 250, 109, 99),
                    ),
                    SizedBox(width: 10),
                    Text('Logout',
                        style: TextStyle(
                          color: const Color.fromARGB(255, 250, 109, 99),
                        )),
                  ],
                ),
                height: 35,
              ),
            ],
            icon: const Icon(
              Icons.settings,
              color: Colors.black,
            ),
            tooltip: 'Settings',
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.lightBlue,
        onRefresh: fetchAppointments,
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.only(top: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundImage: profileImage != null
                            ? NetworkImage(profileImage!)
                            : AssetImage('assets/default_profile.png')
                                as ImageProvider,
                      ),
                      SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              vetName,
                              style: TextStyle(
                                  fontSize: 22, fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 5),
                            Text(
                              clinicName,
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey),
                            ),
                            SizedBox(height: 5),
                            Text(
                              specialization,
                              style:
                                  TextStyle(fontSize: 14, color: Colors.grey),
                            ),
                            SizedBox(height: 10),
                            SizedBox(
                              width: 120,
                              child: TextButton(
                                style: TextButton.styleFrom(
                                    backgroundColor:
                                        Colors.lightBlue.withOpacity(0.1)),
                                onPressed: navigateToEditDetails,
                                child: Row(
                                  children: [
                                    Icon(Icons.edit,
                                        size: 14, color: Colors.blue),
                                    SizedBox(width: 5),
                                    Text("Edit Details",
                                        style: TextStyle(
                                            color: Colors.blue,
                                            fontSize: 14,
                                            fontFamily: 'Arial')),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  tabs: [
                    Tab(icon: Icon(Icons.schedule), text: 'Appointments'),
                    Tab(icon: Icon(Icons.star_border), text: 'Reviews'),
                  ],
                ),
                SizedBox(
                  height: 500,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      buildAppointmentsTab(),
                      Center(child: Text('No reviews yet.')), // Placeholder
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildAppointmentsTab() {
  String formatDate(String dateString) {
    DateTime date = DateTime.parse(dateString);
    DateTime now = DateTime.now();

    if (date.year == now.year && date.month == now.month && date.day == now.day) {
      return 'Today';
    } else if (date.difference(now).inDays == 1) {
      return 'Tomorrow';
    } else {
      return '${date.day} ${[
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
      ][date.month - 1]}, ${date.year}';
    }
  }

  if (_appointments.isEmpty) {
    return const Center(child: Text('No upcoming appointments.'));
  }

  return ListView.builder(
    shrinkWrap: true,
    itemCount: _appointments.length,
    itemBuilder: (context, index) {
      final appointment = _appointments[index];
      final animalName = appointment['animal_name'] ?? "Unknown Animal";
      final animalImage = appointment['animal_image'];
      final ownerName = appointment['owner_name'] ?? "Unknown Owner";
      final status = appointment['status'] ?? "Pending";

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AppointmentDetailsPage(appointment: appointment),
              ),
            );
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 2,
                  spreadRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.blueAccent,
                      radius: 30,
                      backgroundImage: (animalImage != null && animalImage.isNotEmpty)
                          ? NetworkImage(animalImage)
                          : null,
                      child: (animalImage == null || animalImage.isEmpty)
                          ? Text(
                              animalName[0].toUpperCase(),
                              style: const TextStyle(fontSize: 20, color: Colors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(animalName,
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text("Owner: $ownerName",
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          Text("Appointment: ${appointment['appointment_type']}",
                              style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          Text("Status: $status",
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: status == "Pending"
                                      ? Colors.orange[400]
                                      : (status == "Completed" ? Colors.green[400] : Colors.red[600]))),
                        ],
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.lightBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      formatDate(appointment['date']),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.lightBlue),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}
}

class EditVetDetailsPage extends StatelessWidget {
  final int vetId;

  EditVetDetailsPage({required this.vetId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Details")),
      body: Center(child: Text("Edit details form goes here.")),
    );
  }
}
