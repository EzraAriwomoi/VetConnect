import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';

class AppointmentDetailsPage extends StatefulWidget {
  final Map<String, dynamic> appointment;

  const AppointmentDetailsPage({Key? key, required this.appointment})
      : super(key: key);

  @override
  _AppointmentDetailsPageState createState() => _AppointmentDetailsPageState();
}

class _AppointmentDetailsPageState extends State<AppointmentDetailsPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _prescriptionController = TextEditingController();
  String _status = "Pending";
  Map<String, dynamic>? animalDetails;
  bool isLoading = true;
  bool _isSaving = false;
  bool _isAccepting = false;

  // Add history tracking
  List<Map<String, dynamic>> _appointmentHistory = [];

  // Add tab controller for multi-section view
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    // Initialize status as Pending, but respect existing status if already set
    _status = widget.appointment['status'] ?? "Pending";
    _notesController.text = widget.appointment['notes'] ?? "";
    _prescriptionController.text = widget.appointment['prescription'] ?? "";
    _fetchAnimalDetails();
    _fetchAppointmentHistory();
    _tabController = TabController(length: 3, vsync: this);
    
    // Check if appointment date has passed and status is still Pending or Upcoming
    _checkIfMissed();
  }

  void _checkIfMissed() {
    try {
      final appointmentDate = DateTime.parse(widget.appointment['date']);
      final appointmentTime = widget.appointment['time'] ?? "00:00";
      final timeParts = appointmentTime.split(':');
      
      final appointmentDateTime = DateTime(
        appointmentDate.year,
        appointmentDate.month,
        appointmentDate.day,
        int.parse(timeParts[0]),
        int.parse(timeParts[1]),
      );
      
      if (DateTime.now().isAfter(appointmentDateTime) && 
          (_status == "Pending" || _status == "Upcoming")) {
        setState(() {
          _status = "Missed";
        });
      }
    } catch (e) {
      print("Error checking if appointment was missed: ${e.toString()}");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _notesController.dispose();
    _prescriptionController.dispose();
    super.dispose();
  }

  Future<void> _fetchAnimalDetails() async {
    final animalId = widget.appointment['animal_id'];
    // Use a configuration file for base URLs in a production app
    final url = Uri.parse(
        "http://192.168.201.58:5000/get_specific_animal?animal_id=$animalId");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          animalDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        _showErrorMessage("Failed to fetch animal details.");
      }
    } catch (e) {
      _showErrorMessage("Error fetching animal details: ${e.toString()}");
    }
  }

  Future<void> _fetchAppointmentHistory() async {
    final animalId = widget.appointment['animal_id'];
    final url = Uri.parse(
        "http://192.168.201.58:5000/get_animal_appointment_history?animal_id=$animalId");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        setState(() {
          _appointmentHistory =
              List<Map<String, dynamic>>.from(jsonDecode(response.body));
        });
      } else {
        // Silently fail for history - not critical
        print("Failed to fetch appointment history");
      }
    } catch (e) {
      print("Error fetching appointment history: ${e.toString()}");
    }
  }

  Future<void> _updateAppointment() async {
    setState(() {
      _isSaving = true;
    });

    // When saving, automatically set status to Completed if it was Upcoming
    if (_status == "Upcoming") {
      setState(() {
        _status = "Completed";
      });
    }

    final url =
        Uri.parse("http://192.168.201.58:5000/update_appointment_status");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "appointment_id": widget.appointment['id'],
          "status": _status,
          "notes": _notesController.text,
          "prescription": _prescriptionController.text,
        }),
      );

      setState(() {
        _isSaving = false;
      });

      if (response.statusCode == 200) {
        _showSuccessMessage("Appointment updated successfully!");
        Navigator.pop(context, true);
      } else {
        _showErrorMessage("Failed to update appointment. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isSaving = false;
      });
      _showErrorMessage("Error updating appointment: ${e.toString()}");
    }
  }

  Future<void> _acceptAppointment() async {
    setState(() {
      _isAccepting = true;
    });

    final url =
        Uri.parse("http://192.168.201.58:5000/update_appointment_status");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "appointment_id": widget.appointment['id'],
          "status": "Upcoming",
          "notes": _notesController.text,
          "prescription": _prescriptionController.text,
        }),
      );

      setState(() {
        _isAccepting = false;
      });

      if (response.statusCode == 200) {
        setState(() {
          _status = "Upcoming";
        });
        _showSuccessMessage("Appointment accepted!");
      } else {
        _showErrorMessage("Failed to accept appointment. Please try again.");
      }
    } catch (e) {
      setState(() {
        _isAccepting = false;
      });
      _showErrorMessage("Error accepting appointment: ${e.toString()}");
    }
  }

  void _showErrorMessage(String message) {
    setState(() {
      isLoading = false;
      _isSaving = false;
      _isAccepting = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.red,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
    ));
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: EdgeInsets.all(10),
    ));
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('MMMM d, yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case "upcoming":
        return Colors.yellow[400]!;
      case "completed":
        return Colors.green[400]!;
      case "missed":
        return Colors.red[600]!;
      default:
        return Colors.orange[400]!;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case "Upcoming":
        return Icons.calendar_today;
      case "Completed":
        return Icons.check_circle;
      case "Missed":
        return Icons.cancel;
      default:
        return Icons.access_time_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment Details"),
        backgroundColor: Theme.of(context).primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.share),
            onPressed: () {
              // Implement share functionality
              _showSuccessMessage("Sharing appointment details...");
            },
          ),
          IconButton(
            icon: Icon(Icons.print),
            onPressed: () {
              // Implement print functionality
              _showSuccessMessage("Preparing to print...");
            },
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Loading appointment details...",
                      style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: _buildAnimalProfile(),
                  ),
                  SliverToBoxAdapter(
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Theme.of(context).primaryColor,
                      unselectedLabelColor: Colors.grey,
                      indicatorColor: Theme.of(context).primaryColor,
                      tabs: [
                        Tab(text: "Details", icon: Icon(Icons.info_outline)),
                        Tab(
                            text: "Medical",
                            icon: Icon(Icons.medical_services_outlined)),
                        Tab(text: "History", icon: Icon(Icons.history)),
                      ],
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildMedicalTab(),
                  _buildHistoryTab(),
                ],
              ),
            ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(16.0),
        child: _status == "Pending" 
            ? Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isAccepting ? null : _acceptAppointment,
                      icon: _isAccepting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ))
                          : Icon(Icons.check_circle),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      label: Text(_isAccepting ? "Accepting..." : "Accept Appointment",
                          style: TextStyle(fontSize: 16, color: Colors.white)),
                    ),
                  ),
                ],
              )
            : ElevatedButton.icon(
                onPressed: _isSaving ? null : _updateAppointment,
                icon: _isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ))
                    : Icon(Icons.save),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                label: Text(_isSaving ? "Saving..." : "Save Changes",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
      ),
    );
  }

  Widget _buildAnimalProfile() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.7)
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Hero(
            tag: 'animal_${animalDetails?['id']}',
            child: Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: CircleAvatar(
                radius: 50,
                backgroundImage: (animalDetails?['image_url'] != null &&
                        animalDetails?['image_url'].isNotEmpty)
                    ? NetworkImage(animalDetails!['image_url'])
                    : null,
                child: (animalDetails?['image_url'] == null ||
                        animalDetails?['image_url'].isEmpty)
                    ? Text(
                        animalDetails?['name'][0].toUpperCase(),
                        style:
                            const TextStyle(fontSize: 28, color: Colors.white),
                      )
                    : null,
                backgroundColor: Colors.blueAccent,
              ),
            ),
          ),
          SizedBox(height: 12),
          Text(
            animalDetails?['name'] ?? "Unknown",
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          SizedBox(height: 4),
          Text(
            "${animalDetails?['breed']} | ${animalDetails?['species']}",
            style:
                TextStyle(fontSize: 16, color: Colors.white.withOpacity(0.9)),
          ),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(_status),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getStatusIcon(_status),
                  color: Colors.white,
                  size: 16,
                ),
                SizedBox(width: 6),
                Text(
                  _status,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Appointment Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Divider(),
              SizedBox(height: 8),
              _buildInfoSection(Icons.calendar_today, "Date",
                  _formatDate(widget.appointment['date'])),
              _buildInfoSection(Icons.access_time, "Time",
                  widget.appointment['time'] ?? "Not specified"),
              _buildInfoSection(Icons.person, "Owner",
                  widget.appointment['owner_name'] ?? "Unknown"),
              _buildInfoSection(Icons.medical_services, "Type",
                  widget.appointment['appointment_type']),
              SizedBox(height: 20),
              Text(
                "Animal Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Divider(),
              SizedBox(height: 8),
              _buildInfoSection(
                  Icons.pets, "Color", animalDetails?['color'] ?? "Unknown"),
              _buildInfoSection(Icons.cake, "Date of Birth",
                  _formatDate(animalDetails?['date_of_birth'] ?? "Unknown")),
              _buildInfoSection(Icons.transgender, "Gender",
                  animalDetails?['gender'] ?? "Unknown"),
              SizedBox(height: 20),
              Text(
                "Status Information",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              Divider(),
              SizedBox(height: 8),
              _buildInfoSection(
                Icons.flag, 
                "Current Status", 
                _status,
                valueColor: _getStatusColor(_status),
              ),
              if (_status == "Pending")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Click 'Accept Appointment' below to confirm this appointment.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              if (_status == "Upcoming")
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    "Click 'Save Changes' after completing the appointment to mark it as completed.",
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicalTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note_alt,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Medical Notes",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  TextField(
                    controller: _notesController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Enter medical notes...",
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.medication,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Prescription",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  TextField(
                    controller: _prescriptionController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      hintText: "Enter prescription details...",
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                  ),
                  SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () {
                      // Implement medication selection
                      _showSuccessMessage("Medication selector coming soon");
                    },
                    icon: Icon(Icons.add),
                    label: Text("Add from medication list"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                      side: BorderSide(color: Theme.of(context).primaryColor),
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 16),
          Card(
            elevation: 2,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.attach_file,
                          color: Theme.of(context).primaryColor),
                      SizedBox(width: 8),
                      Text(
                        "Attachments",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ],
                  ),
                  Divider(),
                  SizedBox(height: 8),
                  Center(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Implement file upload
                        _showSuccessMessage("File upload coming soon");
                      },
                      icon: Icon(Icons.upload_file),
                      label: Text("Upload files or images"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).primaryColor,
                        side: BorderSide(color: Theme.of(context).primaryColor),
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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

  Widget _buildHistoryTab() {
    return _appointmentHistory.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey[400]),
                SizedBox(height: 16),
                Text(
                  "No previous appointments",
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  "This is the first appointment for this animal",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: _appointmentHistory.length,
            itemBuilder: (context, index) {
              final appointment = _appointmentHistory[index];
              return Card(
                margin: EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Leading circle avatar
                      CircleAvatar(
                        backgroundColor:
                            _getStatusColor(appointment['status'] ?? 'pending'),
                        child: Icon(Icons.event, color: Colors.white, size: 20),
                        radius: 20,
                      ),
                      SizedBox(width: 12),
                      // Content
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              appointment['appointment_type'] ?? 'Appointment',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            SizedBox(height: 4),
                            Text(
                              _formatDate(appointment['date'] ?? ''),
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 14),
                            ),
                            SizedBox(height: 4),
                            Text(
                              appointment['notes'] ?? 'No notes',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontStyle: FontStyle.italic, fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      // Trailing icon
                      Icon(Icons.chevron_right, color: Colors.grey),
                    ],
                  ),
                ),
              );
            },
          );
  }

  // 🔹 Helper Method to Build Information Sections
  Widget _buildInfoSection(IconData icon, String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).primaryColor, size: 20),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}