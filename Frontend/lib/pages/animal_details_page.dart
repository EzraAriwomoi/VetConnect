import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:vetconnect/pages/edit_animal_details.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class AnimalDetailsPage extends StatefulWidget {
  final Map<String, dynamic> animal;
  final int animalId;

  const AnimalDetailsPage({
    Key? key, 
    required this.animal, 
    required this.animalId
  }) : super(key: key);

  @override
  _AnimalDetailsPageState createState() => _AnimalDetailsPageState();
}

class _AnimalDetailsPageState extends State<AnimalDetailsPage> with SingleTickerProviderStateMixin {
  String _selectedSection = "Overview";
  List<Map<String, dynamic>> appointments = [];
  List<Map<String, dynamic>> appointmentHistory = [];
  Map<String, dynamic>? animalDetails;
  bool isLoading = true;
  bool isHistoryLoading = false;
  bool isReportsLoading = false;
  bool isDarkMode = false;
  
  // For swipe navigation
  late TabController _tabController;
  final List<String> _sections = ["Overview", "Appointments", "Med History", "Reports"];
  
  // For pull-to-refresh
  final GlobalKey<RefreshIndicatorState> _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  
  // For collapsible sections
  Map<String, bool> _expandedSections = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _sections.length, 
      vsync: this,
      initialIndex: 0,
    );
    
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _selectedSection = _sections[_tabController.index];
          
          // Load data when section is selected
          if (_selectedSection == "Med History") {
            fetchAppointmentHistory();
          }
        });
      }
    });
    
    fetchAnimalDetails();
    fetchAppointments();
    
    // Initialize all sections as collapsed
    for (var i = 0; i < 10; i++) {
      _expandedSections['section_$i'] = false;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshData() async {
    // Reset loading states
    setState(() {
      isLoading = true;
      isHistoryLoading = true;
      isReportsLoading = true;
    });
    
    // Fetch all data
    await Future.wait([
      fetchAnimalDetails(),
      fetchAppointments(),
      fetchAppointmentHistory(forceRefresh: true),
    ]);
    
    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Data refreshed successfully'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> fetchAnimalDetails() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.201.58:5000/get_specific_animal?animal_id=${widget.animalId}'),
      );

      if (response.statusCode == 200) {
        setState(() {
          animalDetails = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        print("Failed to fetch animal details: ${response.body}");
        setState(() => isLoading = false);
      }
    } catch (e) {
      print("Error fetching animal details: $e");
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchAppointments() async {
    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.201.58:5000/get_appointments?animal_id=${widget.animal['id']}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          appointments = List<Map<String, dynamic>>.from(data);
        });
      } else {
        print("Failed to fetch appointments: ${response.body}");
      }
    } catch (e) {
      print("Error fetching appointments: $e");
    }
  }

  Future<void> fetchAppointmentHistory({bool forceRefresh = false}) async {
    if (appointmentHistory.isNotEmpty && !forceRefresh) return; // Don't fetch if already loaded
    
    setState(() {
      isHistoryLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.201.58:5000/get_animal_appointment_history?animal_id=${widget.animal['id']}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        setState(() {
          appointmentHistory = List<Map<String, dynamic>>.from(data);
          isHistoryLoading = false;
        });
      } else {
        print("Failed to fetch appointment history: ${response.body}");
        setState(() => isHistoryLoading = false);
      }
    } catch (e) {
      print("Error fetching appointment history: $e");
      setState(() => isHistoryLoading = false);
    }
  }

  // This function will fetch completed appointments with notes and prescriptions
  Future<List<Map<String, dynamic>>> fetchMedicalReports() async {
    setState(() {
      isReportsLoading = true;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'http://192.168.201.58:5000/get_animal_appointment_history?animal_id=${widget.animal['id']}'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        List<Map<String, dynamic>> allAppointments = List<Map<String, dynamic>>.from(data);
        
        // Filter for completed appointments with notes or prescriptions
        List<Map<String, dynamic>> reports = allAppointments
            .where((appointment) => 
                appointment['status'] == 'Completed' && 
                (appointment['notes']?.isNotEmpty == true || 
                 appointment['prescription']?.isNotEmpty == true))
            .toList();
        
        setState(() {
          isReportsLoading = false;
        });
        
        return reports;
      } else {
        print("Failed to fetch medical reports: ${response.body}");
        setState(() => isReportsLoading = false);
        return [];
      }
    } catch (e) {
      print("Error fetching medical reports: $e");
      setState(() => isReportsLoading = false);
      return [];
    }
  }

  void toggleDarkMode() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
    
    // Provide haptic feedback
    HapticFeedback.lightImpact();
  }

  @override
  Widget build(BuildContext context) {
    // Apply dark mode theme if enabled
    final ThemeData theme = isDarkMode 
        ? ThemeData.dark().copyWith(
            primaryColor: Colors.lightBlue,
            cardColor: Colors.grey[850],
            scaffoldBackgroundColor: Colors.grey[900],
          )
        : ThemeData.light().copyWith(
            primaryColor: Colors.lightBlue,
            scaffoldBackgroundColor: Colors.grey[100],
          );
    
    return Theme(
      data: theme,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text("Animal Details",
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: theme.primaryColor,
          elevation: 0,
          actions: [
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: toggleDarkMode,
              tooltip: isDarkMode ? "Switch to light mode" : "Switch to dark mode",
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditDialog(context);
                } else if (value == 'delete') {
                  _deleteAnimal();
                } else if (value == 'share') {
                  _shareAnimalProfile();
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: theme.iconTheme.color),
                      SizedBox(width: 10),
                      Text("Edit Details"),
                    ],
                  ),
                ),
                PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share, color: theme.iconTheme.color),
                      SizedBox(width: 10),
                      Text("Share Profile"),
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
        body: RefreshIndicator(
          key: _refreshIndicatorKey,
          onRefresh: _refreshData,
          color: theme.primaryColor,
          child: GestureDetector(
            // Handle swipe gestures for navigation
            onHorizontalDragEnd: (details) {
              if (details.primaryVelocity! > 0) {
                // Swipe right - go to previous section
                final currentIndex = _sections.indexOf(_selectedSection);
                if (currentIndex > 0) {
                  _tabController.animateTo(currentIndex - 1);
                }
              } else if (details.primaryVelocity! < 0) {
                // Swipe left - go to next section
                final currentIndex = _sections.indexOf(_selectedSection);
                if (currentIndex < _sections.length - 1) {
                  _tabController.animateTo(currentIndex + 1);
                }
              }
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              physics: AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Animal Image with Hero animation
                  Hero(
                    tag: "animal_${widget.animal['id']}",
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 10,
                            offset: Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          widget.animal['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: Icon(Icons.pets, size: 80, color: Colors.grey[400]),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: Center(
                                child: CircularProgressIndicator(
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / 
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Animal Info Card
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black26,
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.animal['name'],
                                      style: TextStyle(
                                        fontSize: 24, 
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    Text(
                                      "${widget.animal['breed']} - ${widget.animal['species']}",
                                      style: TextStyle(
                                        fontSize: 16, 
                                        color: isDarkMode ? Colors.grey[400] : Colors.grey[700],
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: theme.primaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  widget.animal['gender'],
                                  style: TextStyle(
                                    color: theme.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 15),
                          Divider(),
                          SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.access_time_filled, 
                            label: "Age", 
                            value: widget.animal['age'],
                            iconColor: Colors.amber,
                          ),
                          SizedBox(height: 10),
                          _buildInfoRow(
                            icon: Icons.color_lens, 
                            label: "Color", 
                            value: widget.animal['color'],
                            iconColor: Colors.deepOrange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Section Navigation
                  Container(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _sections.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: _buildRoundedButton(
                            _sections[index], 
                            _getSectionIcon(_sections[index]), 
                            _getSectionColor(_sections[index]),
                            index,
                          ),
                        );
                      },
                    ),
                  ),

                  SizedBox(height: 20),

                  // Dynamic Content Container with animation
                  AnimatedSwitcher(
                    duration: Duration(milliseconds: 400),
                    transitionBuilder: (Widget child, Animation<double> animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.05, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: _getContentWidget(),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Add a floating action button for quick actions
        floatingActionButton: _buildFloatingActionButton(),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    // Show different FABs based on the selected section
    switch (_selectedSection) {
      case "Appointments":
        return FloatingActionButton(
          onPressed: () {
            // Navigate to book appointment page
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Book appointment feature coming soon"))
            );
          },
          backgroundColor: Colors.green,
          child: Icon(Icons.add),
          tooltip: "Book new appointment",
        );
      case "Med History":
        return FloatingActionButton(
          onPressed: () {
            // Refresh history data
            fetchAppointmentHistory(forceRefresh: true);
          },
          backgroundColor: Colors.orange,
          child: Icon(Icons.refresh),
          tooltip: "Refresh Med History",
        );
      case "Reports":
        return FloatingActionButton(
          onPressed: () {
            // Export all reports
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Export reports feature coming soon"))
            );
          },
          backgroundColor: Colors.red,
          child: Icon(Icons.download),
          tooltip: "Export all reports",
        );
      default:
        return FloatingActionButton(
          onPressed: () {
            // Share animal profile
            _shareAnimalProfile();
          },
          backgroundColor: Colors.blue,
          child: Icon(Icons.share),
          tooltip: "Share animal profile",
        );
    }
  }

  void _shareAnimalProfile() {
    // Simulate sharing functionality
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Sharing ${widget.animal['name']}'s profile..."),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon, 
    required String label, 
    required String value,
    Color? iconColor,
  }) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? Colors.blue).withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor ?? Colors.blue, size: 20),
        ),
        SizedBox(width: 15),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getSectionIcon(String section) {
    switch (section) {
      case "Appointments":
        return Icons.event;
      case "Med History":
        return Icons.local_hospital;
      case "Reports":
        return Icons.assignment;
      default:
        return Icons.info;
    }
  }

  Color _getSectionColor(String section) {
    switch (section) {
      case "Appointments":
        return Colors.green;
      case "Med History":
        return Colors.orange;
      case "Reports":
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  void _showEditDialog(BuildContext context) async {
    HapticFeedback.selectionClick();
    final updatedAnimal = await showDialog(
      context: context,
      builder: (context) => EditAnimalDialog(animal: widget.animal),
    );

    if (updatedAnimal != null) {
      setState(() {
        widget.animal.clear();
        widget.animal.addAll(updatedAnimal);
      });
      
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Animal details updated successfully'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _deleteAnimal() {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("Delete Animal"),
        content: Text("Are you sure you want to delete ${widget.animal['name']}? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              // Simulate deletion
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Delete functionality coming soon"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text("Delete"),
          ),
        ],
      ),
    );
  }

  Widget _buildRoundedButton(String label, IconData icon, Color color, int index) {
    bool isSelected = _selectedSection == label;
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() {
          _selectedSection = label;
          _tabController.animateTo(index);
          
          // Load data when section is selected
          if (label == "Med History") {
            fetchAppointmentHistory();
          }
        });
      },
      child: AnimatedContainer(
        duration: Duration(milliseconds: 300),
        width: 80,
        child: Column(
          children: [
            AnimatedContainer(
              duration: Duration(milliseconds: 300),
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isSelected ? color : color.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: isSelected ? [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: Offset(0, 4),
                  ),
                ] : [],
              ),
              child: Icon(
                icon, 
                color: isSelected ? Colors.white : color, 
                size: 28,
              ),
            ),
            SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, 
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getContentWidget() {
    switch (_selectedSection) {
      case "Appointments":
        return _buildAppointmentsSection();
      case "Med History":
        return _buildMedicalHistorySection();
      case "Reports":
        return _buildReportsSection();
      default:
        return _buildOverviewSection();
    }
  }

  Widget _buildOverviewSection() {
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              color: Colors.lightBlue,
            ),
            SizedBox(height: 16),
            Text("Loading animal details...",
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      );
    }

    if (animalDetails == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red),
            SizedBox(height: 16),
            Text("Animal details not found",
                style: TextStyle(color: Colors.red)),
          ],
        ),
      );
    }

    // Define the order of fields to be displayed
    final List<MapEntry<String, dynamic>> orderedFields = [
      MapEntry("Name", animalDetails!["name"]),
      MapEntry("Date of Birth", animalDetails!["date_of_birth"]),
      MapEntry("Breed", animalDetails!["breed"]),
      MapEntry("Color", animalDetails!["color"]),
      MapEntry("Gender", animalDetails!["gender"]),
      MapEntry("Species", animalDetails!["species"]),
    ];

    return Column(
      children: [
        // Overview Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.pets, color: Colors.lightBlue, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Animal Overview",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                ...orderedFields.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            "${entry.key}:",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            entry.value.toString(),
                            style: TextStyle(
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Health Summary Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.health_and_safety, color: Colors.green, size: 22),
                        SizedBox(width: 8),
                        Text(
                          "Health Summary",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: Icon(
                        _expandedSections['section_health'] == true 
                            ? Icons.keyboard_arrow_up 
                            : Icons.keyboard_arrow_down,
                        color: Colors.grey,
                      ),
                      onPressed: () {
                        setState(() {
                          _expandedSections['section_health'] = 
                              !(_expandedSections['section_health'] ?? false);
                        });
                      },
                    ),
                  ],
                ),
                
                if (_expandedSections['section_health'] == true) ...[
                  SizedBox(height: 15),
                  // Health status indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildHealthIndicator("Weight", "Normal", Colors.green),
                      _buildHealthIndicator("Vaccinations", "Up to date", Colors.green),
                      _buildHealthIndicator("Checkups", "Regular", Colors.green),
                    ],
                  ),
                ],
                
                if (_expandedSections['section_health'] != true)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Text(
                      "Tap to view health metrics and vaccination status",
                      style: TextStyle(
                        color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        SizedBox(height: 20),
        
        // Recent Activity Card
        Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: Colors.black26,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.history, color: Colors.purple, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Recent Activity",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.purple,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                
                // Recent activity list
                appointments.isEmpty && appointmentHistory.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Text(
                            "No recent activity found",
                            style: TextStyle(
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      )
                    : Column(
                        children: [
                          if (appointments.isNotEmpty)
                            _buildActivityItem(
                              date: appointments[0]["date"] ?? "",
                              title: "Upcoming Appointment",
                              description: "With ${appointments[0]["vet_name"] ?? "Unknown Vet"}",
                              icon: Icons.event,
                              color: Colors.blue,
                            ),
                          if (appointmentHistory.isNotEmpty)
                            _buildActivityItem(
                              date: appointmentHistory[0]["date"] ?? "",
                              title: appointmentHistory[0]["appointment_type"] ?? "Checkup",
                              description: "Status: ${appointmentHistory[0]["status"] ?? "Unknown"}",
                              icon: Icons.medical_services,
                              color: Colors.orange,
                            ),
                        ],
                      ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHealthIndicator(String label, String status, Color color) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              Icons.check_circle,
              color: color,
              size: 30,
            ),
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
        Text(
          status,
          style: TextStyle(
            color: color,
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildActivityItem({
    required String date,
    required String title,
    required String description,
    required IconData icon,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  description,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatDate(date),
            style: TextStyle(
              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppointmentsSection() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event, color: Colors.green, size: 22),
                SizedBox(width: 8),
                Text(
                  "Appointments for ${widget.animal['name'] ?? 'Unknown'}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            
            // Search and filter
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "Search appointments...",
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                  Icon(Icons.filter_list, color: Colors.grey),
                ],
              ),
            ),
            
            SizedBox(height: 15),
            
            appointments.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        SizedBox(height: 20),
                        Icon(
                          Icons.event_busy,
                          size: 64,
                          color: isDarkMode ? Colors.grey[700] : Colors.grey[300],
                        ),
                        SizedBox(height: 16),
                        Text(
                          "No appointments found",
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Tap the + button to schedule a new appointment",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 20),
                      ],
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: appointments.length,
                    separatorBuilder: (context, index) => Divider(height: 30),
                    itemBuilder: (context, index) {
                      final appointment = appointments[index];
                      
                      return InkWell(
                        onTap: () {
                          // Show appointment details
                          _showAppointmentDetails(appointment);
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: _getStatusColor(appointment["status"])
                                      .withOpacity(0.2),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getStatusIcon(appointment["status"]),
                                    color: _getStatusColor(appointment["status"]),
                                    size: 30,
                                  ),
                                ),
                              ),
                              SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      appointment["appointment_type"] ?? "Unknown",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Vet: ${appointment["vet_name"] ?? "No Vet"}",
                                      style: TextStyle(
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.calendar_today,
                                          size: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          _formatDate(appointment["date"] ?? ""),
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Icon(
                                          Icons.access_time,
                                          size: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          appointment["time"] ?? "No Time",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(appointment["status"])
                                      .withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  appointment["status"] ?? "Unknown",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _getStatusColor(appointment["status"]),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  void _showAppointmentDetails(Map<String, dynamic> appointment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDarkMode ? Colors.grey[900] : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              margin: EdgeInsets.only(top: 10),
              width: 40,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[400],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                "Appointment Details",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem(
                      "Type",
                      appointment["appointment_type"] ?? "Unknown",
                      Icons.medical_services,
                    ),
                    _buildDetailItem(
                      "Date",
                      _formatDate(appointment["date"] ?? ""),
                      Icons.calendar_today,
                    ),
                    _buildDetailItem(
                      "Time",
                      appointment["time"] ?? "No Time",
                      Icons.access_time,
                    ),
                    _buildDetailItem(
                      "Veterinarian",
                      appointment["vet_name"] ?? "Unknown",
                      Icons.person,
                    ),
                    _buildDetailItem(
                      "Status",
                      appointment["status"] ?? "Unknown",
                      _getStatusIcon(appointment["status"]),
                      valueColor: _getStatusColor(appointment["status"]),
                    ),
                    SizedBox(height: 20),
                    Text(
                      "Actions",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildActionButton(
                          "Reschedule",
                          Icons.edit_calendar,
                          Colors.orange,
                        ),
                        _buildActionButton(
                          "Cancel",
                          Icons.cancel,
                          Colors.red,
                        ),
                        _buildActionButton(
                          "Directions",
                          Icons.directions,
                          Colors.blue,
                        ),
                      ],
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

  Widget _buildDetailItem(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDarkMode ? Colors.grey[800] : Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: valueColor ?? Colors.blue, size: 24),
          ),
          SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                    fontSize: 14,
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

  Widget _buildActionButton(String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(icon, color: color),
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("$label feature coming soon"),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case "Upcoming":
        return Colors.yellow[700]!;
      case "Completed":
        return Colors.green[600]!;
      case "Missed":
        return Colors.red[600]!;
      default:
        return Colors.orange[400]!;
    }
  }

  IconData _getStatusIcon(String? status) {
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

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildMedicalHistorySection() {
    // Trigger fetch if not already loading
    if (!isHistoryLoading && appointmentHistory.isEmpty) {
      fetchAppointmentHistory();
    }

    if (isHistoryLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: Colors.orange),
            SizedBox(height: 16),
            Text("Loading Med History...",
                style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
          ],
        ),
      );
    }

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      elevation: 4,
      shadowColor: Colors.black26,
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.local_hospital, color: Colors.orange, size: 22),
                SizedBox(width: 8),
                Text(
                  "Med History for ${widget.animal['name']}",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            
            appointmentHistory.isEmpty
                ? Center(
                    child: Column(
                      children: [
                        Icon(Icons.history_toggle_off, 
                             size: 64, 
                             color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                        SizedBox(height: 16),
                        Text("No Med History available",
                            style: TextStyle(
                              fontSize: 16, 
                              color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            )),
                        SizedBox(height: 8),
                        Text(
                          "Medical records will appear here after appointments",
                          style: TextStyle(
                            fontSize: 14,
                            color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: appointmentHistory.length,
                    itemBuilder: (context, index) {
                      final record = appointmentHistory[index];
                      return Column(
                        children: [
                          ListTile(
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _getStatusColor(record["status"]).withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  _getStatusIcon(record["status"]),
                                  color: _getStatusColor(record["status"]),
                                  size: 20,
                                ),
                              ),
                            ),
                            title: Text(
                              record["appointment_type"] ?? "General Checkup",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              "Vet: ${record["veterinarian_name"] ?? "Unknown"}",
                            ),
                            trailing: Text(
                              _formatDate(record["date"] ?? ""),
                              style: TextStyle(
                                color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                              ),
                            ),
                            onTap: () {
                              setState(() {
                                _expandedSections['record_$index'] = 
                                    !(_expandedSections['record_$index'] ?? false);
                              });
                            },
                          ),
                          
                          if (_expandedSections['record_$index'] == true) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (record["notes"] != null && record["notes"].toString().isNotEmpty) ...[
                                    Text(
                                      "Medical Notes:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(record["notes"]),
                                    ),
                                  ],
                                  if (record["prescription"] != null && record["prescription"].toString().isNotEmpty) ...[
                                    Text(
                                      "Prescription:",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Container(
                                      margin: EdgeInsets.symmetric(vertical: 8),
                                      padding: EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: Text(record["prescription"]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                          
                          Divider(),
                        ],
                      );
                    },
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportsSection() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchMedicalReports(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 16),
                Text("Loading medical reports...",
                    style: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[600])),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                SizedBox(height: 16),
                Text("Error loading reports: ${snapshot.error}",
                    style: TextStyle(color: Colors.red)),
              ],
            ),
          );
        }
        
        final reports = snapshot.data ?? [];
        
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 4,
          shadowColor: Colors.black26,
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.assignment, color: Colors.red, size: 22),
                    SizedBox(width: 8),
                    Text(
                      "Medical Reports for ${widget.animal['name']}",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 15),
                
                reports.isEmpty
                    ? Center(
                        child: Column(
                          children: [
                            Icon(Icons.description_outlined, 
                                 size: 64, 
                                 color: isDarkMode ? Colors.grey[700] : Colors.grey[300]),
                            SizedBox(height: 16),
                            Text("No medical reports available",
                                style: TextStyle(
                                  fontSize: 16, 
                                  color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                  fontWeight: FontWeight.bold,
                                )),
                            SizedBox(height: 8),
                            Text(
                              "Reports are generated from completed appointments",
                              style: TextStyle(
                                fontSize: 14,
                                color: isDarkMode ? Colors.grey[500] : Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        physics: NeverScrollableScrollPhysics(),
                        itemCount: reports.length,
                        itemBuilder: (context, index) {
                          final report = reports[index];
                          bool hasPrescription = report["prescription"] != null && 
                                               report["prescription"].toString().isNotEmpty;
                          bool hasNotes = report["notes"] != null && 
                                        report["notes"].toString().isNotEmpty;
                          
                          String reportType = hasPrescription ? "Prescription" : "Medical Notes";
                          
                          return Card(
                            margin: EdgeInsets.only(bottom: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                            child: InkWell(
                              onTap: () {
                                _showReportDetails(report);
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(Icons.description, 
                                                color: Colors.red, 
                                                size: 20),
                                            SizedBox(width: 8),
                                            Text(
                                              reportType,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Text(
                                          _formatDate(report["date"] ?? ""),
                                          style: TextStyle(
                                            color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 10),
                                    Text(
                                      report["appointment_type"] ?? "Checkup",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(height: 8),
                                    if (hasNotes)
                                      Text(
                                        "Notes: ${report["notes"]}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    if (hasPrescription)
                                      Text(
                                        "Prescription: ${report["prescription"]}",
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDarkMode ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                    SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        OutlinedButton.icon(
                                          icon: Icon(Icons.visibility, size: 16),
                                          label: Text("View"),
                                          onPressed: () {
                                            _showReportDetails(report);
                                          },
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                            side: BorderSide(color: Colors.red),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.download, size: 16),
                                          label: Text("Export"),
                                          onPressed: () {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              SnackBar(
                                                content: Text("Export feature coming soon"),
                                                behavior: SnackBarBehavior.floating,
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                            foregroundColor: Colors.white,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
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
              ],
            ),
          ),
        );
      }
    );
  }

  void _showReportDetails(Map<String, dynamic> report) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.description, color: Colors.red),
            SizedBox(width: 8),
            Text("Medical Report Details"),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Date: ${_formatDate(report["date"] ?? "")}",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text("Appointment Type: ${report["appointment_type"] ?? "Checkup"}"),
                SizedBox(height: 8),
                Text("Veterinarian: ${report["veterinarian_name"] ?? "Unknown"}"),
                SizedBox(height: 16),
                if (report["notes"] != null && report["notes"].toString().isNotEmpty) ...[
                  Text("Medical Notes:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(report["notes"]),
                  ),
                  SizedBox(height: 16),
                ],
                if (report["prescription"] != null && report["prescription"].toString().isNotEmpty) ...[
                  Text("Prescription:", style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[800] : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isDarkMode ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                    ),
                    child: Text(report["prescription"]),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text("Close"),
          ),
          ElevatedButton.icon(
            onPressed: () {
              // Here you would implement printing or sharing functionality
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Report export feature coming soon"))
              );
            },
            icon: Icon(Icons.print, size: 16),
            label: Text("Print"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
            ),
          ),
        ],
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