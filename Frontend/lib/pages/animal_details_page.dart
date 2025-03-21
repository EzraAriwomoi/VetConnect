import 'package:flutter/material.dart';
import 'package:vetconnect/pages/edit_animal_details.dart';
import 'package:url_launcher/url_launcher.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Map<String, dynamic> animal;

  const AnimalDetailsPage({Key? key, required this.animal}) : super(key: key);

  @override
  _AnimalDetailsPageState createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> {
  String _selectedSection = "Overview";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Animal Details",
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.lightBlue,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _showEditDialog(context);
              } else if (value == 'delete') {
                _deleteAnimal();
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit, color: Colors.black),
                    SizedBox(width: 10),
                    Text("Edit Details"),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete, color: Colors.redAccent),
                    SizedBox(width: 10),
                    Text("Delete Animal",
                        style: TextStyle(color: Colors.redAccent)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Animal Image
            Hero(
              tag: "animal_${widget.animal['id']}",
              child: ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  widget.animal['image_url'],
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            SizedBox(height: 20),

            // Animal Info
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 2,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.animal['name'],
                      style:
                          TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 5),
                    Text(
                      "${widget.animal['breed']} - ${widget.animal['species']}",
                      style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                    ),
                    SizedBox(height: 10),
                    Row(
                      children: [
                        Icon(Icons.access_time_filled, color: Colors.lightBlue),
                        SizedBox(width: 10),
                        Text("Age: ${widget.animal['age']}",
                            style: TextStyle(
                                fontSize: 16, color: Colors.grey[700])),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.male, color: Colors.blue),
                        SizedBox(width: 10),
                        Text(
                          "Gender: ${widget.animal['gender']}",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.color_lens, color: Colors.brown),
                        SizedBox(width: 10),
                        Text(
                          "Color: ${widget.animal['color']}",
                          style:
                              TextStyle(fontSize: 16, color: Colors.grey[700]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildRoundedButton("Overview", Icons.info, Colors.blue),
                  SizedBox(width: 20),
                  _buildRoundedButton(
                      "Appointments", Icons.event, Colors.green),
                  SizedBox(width: 20),
                  _buildRoundedButton(
                      "Medical History", Icons.local_hospital, Colors.orange),
                  SizedBox(width: 20),
                  _buildRoundedButton("Reports", Icons.assignment, Colors.red),
                ],
              ),
            ),

            SizedBox(height: 20),

            // Dynamic Content Container
            AnimatedSwitcher(
              duration: Duration(milliseconds: 300),
              child: _getContentWidget(),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(BuildContext context) async {
    final updatedAnimal = await showDialog(
      context: context,
      builder: (context) => EditAnimalDialog(animal: widget.animal),
    );

    if (updatedAnimal != null) {
      setState(() {
        widget.animal.clear();
        widget.animal.addAll(updatedAnimal);
      });
    }
  }

  void _deleteAnimal() {}

  Widget _buildRoundedButton(String label, IconData icon, Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedSection = label;
        });
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _getContentWidget() {
    switch (_selectedSection) {
      case "Appointments":
        return _buildAppointmentsSection();
      case "Medical History":
        return _buildMedicalHistorySection();
      case "Reports":
        return _buildReportsSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _buildOverviewSection() {
    // Dummy Data
    Map<String, String> dummyAnimalData = {
      "Name": "Buddy",
      "Breed": "Golden Retriever",
      "Species": "Dog",
      "Gender": "Male",
      "Color": "Golden",
      "Age": "5 years",
      "Date of Birth": "March 15, 2019",
      "Medical Status": "Healthy",
      "Last Checkup": "February 2024",
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Animal Overview",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.lightBlue,
              ),
            ),
            SizedBox(height: 10),
            ...dummyAnimalData.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.pets, color: Colors.lightBlue, size: 18),
                    SizedBox(width: 8),
                    Text(
                      "${entry.key}: ",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(entry.value),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    List<Map<String, String>> appointments = [
      {
        "date": "2025-04-10",
        "time": "10:30 AM",
        "vet": "Dr. Emily Johnson",
        "status": "Upcoming",
        "profileImage": "assets/user_guide1.png",
      },
      {
        "date": "2025-03-05",
        "time": "02:00 PM",
        "vet": "Dr. Mike Peterson",
        "status": "Completed",
        "profileImage": "assets/user_guide1.png",
      },
      {
        "date": "2025-02-15",
        "time": "11:00 AM",
        "vet": "Dr. Sarah Lee",
        "status": "Completed",
        "profileImage": "assets/user_guide1.png",
      },
      {
        "date": "2025-01-10",
        "time": "09:00 AM",
        "vet": "Dr. Alan Wright",
        "status": "Missed",
        "profileImage": "assets/user_guide1.png",
      },
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Appointments for ${widget.animal['name'] ?? 'Unknown'}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold,color: Colors.grey[700],),
            ),
            SizedBox(height: 10),
            ListView.separated(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: appointments.length,
              separatorBuilder: (context, index) => Divider(),
              itemBuilder: (context, index) {
                final appointment = appointments[index];

                return Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        appointment["profileImage"]!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Name: ${appointment["vet"] ?? "No Vet"}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text("Date: ${appointment["date"] ?? "No Date"}"),
                          Text("Time: ${appointment["time"] ?? "No Time"}"),
                        ],
                      ),
                    ),
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: appointment["status"] == "Upcoming"
                            ? Colors.orange.withOpacity(0.2)
                            : appointment["status"] == "Completed"
                                ? Colors.green.withOpacity(0.2)
                                : Colors.red.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            appointment["status"] == "Upcoming"
                                ? Icons.calendar_today
                                : appointment["status"] == "Completed"
                                    ? Icons.check_circle
                                    : Icons.cancel,
                            color: appointment["status"] == "Upcoming"
                                ? Colors.orange
                                : appointment["status"] == "Completed"
                                    ? Colors.green
                                    : Colors.red,
                            size: 14,
                          ),
                          SizedBox(width: 5),
                          Text(
                            appointment["status"]!,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: appointment["status"] == "Upcoming"
                                  ? Colors.orange
                                  : appointment["status"] == "Completed"
                                      ? Colors.green
                                      : Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicalHistorySection() {
    List<Map<String, String>> medicalRecords = [
      {
        "date": "02 April 2025",
        "diagnosis": "General Consultation",
        "notes":
            "Owner reported mild lethargy. No major issues found. Advised hydration and observation.",
        "vet": "Dr. Michael Adams"
      },
      {
        "date": "20 March 2025",
        "diagnosis": "Routine Checkup",
        "notes": "Healthy, no issues detected.",
        "vet": "Dr. Emily Johnson"
      },
      {
        "date": "05 January 2025",
        "diagnosis": "Ear Infection",
        "notes": "Prescribed ear drops, follow-up in 2 weeks.",
        "vet": "Dr. Robert Smith"
      },
      {
        "date": "15 February 2025",
        "diagnosis": "Leg Injury - Possible Fracture",
        "notes": "X-ray recommended due to limping and swelling.",
        "vet": "Dr. Sarah Lee"
      },
      {
        "date": "16 February 2025",
        "diagnosis": "Fractured Tibia",
        "notes": "Confirmed via X-ray. Applied splint, painkillers prescribed.",
        "vet": "Dr. Sarah Lee"
      }
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Medical History for ${widget.animal['name']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            medicalRecords.isEmpty
                ? Text("No medical history available.",
                    style: TextStyle(fontSize: 16, color: Colors.grey))
                : Column(
                    children: medicalRecords.map((record) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.lightBlue),
                              SizedBox(width: 8),
                              Text(record["date"]!,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text("🩺 Diagnosis: ${record["diagnosis"]}"),
                          Text("📋 Notes: ${record["notes"]}",
                              style: TextStyle(color: Colors.grey[600])),
                          Text("👨‍⚕️ Vet: ${record["vet"]}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue)),
                          Divider(thickness: 1, height: 20),
                        ],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    List<Map<String, String>> reports = [
      {
        "date": "15 March 2025",
        "type": "Blood Test",
        "summary": "Normal blood count, no issues detected.",
        "vet": "Dr. Emily Johnson",
        "documentUrl": "https://example.com/blood-test-report.pdf"
      },
      {
        "date": "16 February 2025",
        "type": "X-Ray",
        "summary":
            "Fracture detected in the tibia bone. Treatment plan initiated.",
        "vet": "Dr. Sarah Lee",
        "documentUrl": "https://example.com/x-ray-report.pdf"
      },
      {
        "date": "10 December 2024",
        "type": "Prescription",
        "summary": "Prescribed antibiotics for ear infection.",
        "vet": "Dr. Robert Smith",
        "documentUrl": "https://example.com/prescription.pdf"
      }
    ];

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Medical Reports for ${widget.animal['name']}",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            reports.isEmpty
                ? Text("No reports available.",
                    style: TextStyle(fontSize: 16, color: Colors.grey))
                : Column(
                    children: reports.map((report) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today,
                                  size: 16, color: Colors.lightBlue),
                              SizedBox(width: 8),
                              Text(report["date"]!,
                                  style:
                                      TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 5),
                          Text("📌 Report Type: ${report["type"]}"),
                          Text("📋 Summary: ${report["summary"]}",
                              style: TextStyle(color: Colors.grey[600])),
                          Text("👨‍⚕️ Vet: ${report["vet"]}",
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue)),
                          SizedBox(height: 5),
                          Row(
                            children: [
                              Spacer(), // Pushes button to the right
                              ElevatedButton.icon(
                                onPressed: () {
                                  // Open the report document
                                  launchURL(report["documentUrl"]!);
                                },
                                icon: Icon(Icons.download,
                                    size: 16, color: Colors.white),
                                label: Text("View Report"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.lightBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                              ),
                            ],
                          ),
                          Divider(thickness: 1, height: 20),
                        ],
                      );
                    }).toList(),
                  ),
          ],
        ),
      ),
    );
  }

  void launchURL(String url) async {
    if (await canLaunch(url)) {
      await launch(url);
    } else {
      print("Could not launch $url");
    }
  }
}
