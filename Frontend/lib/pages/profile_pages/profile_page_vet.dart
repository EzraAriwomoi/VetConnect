import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/pages/appointment_details_page.dart';

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
      Uri.parse('http://192.168.201.58:5000/get_user?email=${user.email}'),
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
    Uri.parse('http://192.168.201.58:5000/get_vet_appointments?veterinarian_id=$loggedInVetId'),
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
