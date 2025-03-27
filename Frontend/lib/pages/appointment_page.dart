import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class AppointmentPage extends StatefulWidget {
  final int vetId;

  const AppointmentPage({Key? key, required this.vetId}) : super(key: key);

  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime selectedDate = DateTime.now().add(Duration(days: 1));
  String? selectedTime;
  String? selectedAppointmentType;
  int? loggedInUserId;
  List<Map<String, dynamic>> registeredAnimals = [];
  int? selectedAnimalId;
  Map<String, dynamic>? selectedAnimal;

  List<String> availableTimes = [
    "08:00",
    "10:00",
    "11:00",
    "12:00",
    "14:00",
    "16:00"
  ];

  @override
  void initState() {
    super.initState();
    fetchUserId();
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
        loggedInUserId = data["id"];
      });

      // Fetch animals after getting the user ID
      fetchAnimals(loggedInUserId!);
    }
  }

  Future<void> fetchAnimals(int ownerId) async {
    final response = await http.get(
      Uri.parse('http://192.168.201.58:5000/get_animals?owner_id=$ownerId'),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      setState(() {
        registeredAnimals = List<Map<String, dynamic>>.from(data);
      });
    } else {
      print("Failed to fetch animals: ${response.body}");
    }
  }

  void showConfirmationSheet() {
    if (selectedTime == null ||
        selectedAppointmentType == null ||
        selectedAnimal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Please select all fields before proceeding")),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Confirm Appointment",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),
              ListTile(
                leading: const Icon(
                  Icons.pets,
                  color: Colors.lightBlue,
                ),
                title: Text("Animal: ${selectedAnimal!["name"]}"),
              ),
              ListTile(
                leading: const Icon(
                  Icons.calendar_today,
                  color: Colors.lightBlue,
                ),
                title: Text(
                    "Date: ${selectedDate.toLocal().toString().split(" ")[0]}"),
              ),
              ListTile(
                leading: const Icon(
                  Icons.access_time,
                  color: Colors.lightBlue,
                ),
                title: Text("Time: $selectedTime"),
              ),
              ListTile(
                leading: const Icon(
                  Icons.medical_services,
                  color: Colors.lightBlue,
                ),
                title: Text("Type: $selectedAppointmentType"),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(
                        color: Color.fromARGB(255, 250, 109, 99),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      bookAppointment();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                    ),
                    child: const Text("Confirm Booking",
                        style: TextStyle(color: Colors.white)),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> bookAppointment() async {
    if (loggedInUserId == null ||
        selectedAnimalId == null ||
        selectedTime == null ||
        selectedAppointmentType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select all fields before booking")),
      );
      return;
    }

    final response = await http.post(
      Uri.parse('http://192.168.201.58:5000/book_appointment'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "owner_id": loggedInUserId,
        "animal_id": selectedAnimalId,
        "veterinarian_id": widget.vetId,
        "date": selectedDate.toIso8601String().split("T")[0],
        "time": selectedTime,
        "appointment_type": selectedAppointmentType,
      }),
    );

    if (response.statusCode == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Appointment booked! Await confirmation",
            style: TextStyle(
              color: Colors.white,
            ),
          ),
          backgroundColor: const Color.fromARGB(255, 185, 167, 5),
        ),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to book appointment")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Appointment"),
        backgroundColor: Colors.lightBlue,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Select Date",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Theme(
                data: ThemeData(
                  colorScheme: ColorScheme.light(
                    primary: const Color.fromARGB(255, 198, 236, 253),
                    onPrimary: const Color.fromARGB(255, 8, 118, 168),
                    onSurface: Colors.black,
                  ),
                  // textTheme: TextTheme(
                  //   bodyLarge: TextStyle(fontWeight: FontWeight.bold),
                  // ),
                ),
                child: CalendarDatePicker(
                  initialDate: selectedDate,
                  firstDate: DateTime.now().add(Duration(days: 1)),
                  lastDate: DateTime(2025, 12, 31),
                  onDateChanged: (date) {
                    setState(() => selectedDate = date);
                  },
                  selectableDayPredicate: (date) {
                    return date.isAfter(DateTime.now());
                  },
                  currentDate: DateTime.now(),
                ),
              ),
              const SizedBox(height: 20),
              const Text("Available Time",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: availableTimes.map((time) {
                  return GestureDetector(
                    onTap: () => setState(() => selectedTime = time),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 20),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.cyan),
                        borderRadius: BorderRadius.circular(10),
                        color: selectedTime == time
                            ? Colors.cyan.withOpacity(0.2)
                            : Colors.transparent,
                      ),
                      child: Text(time,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              Text("Select Animal",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedAnimalId,
                    hint: Text("Choose an Animal",
                        style: TextStyle(fontSize: 16)),
                    isExpanded: true,
                    onChanged: (int? newValue) {
                      setState(() {
                        selectedAnimalId = newValue;
                        selectedAnimal = registeredAnimals.firstWhere(
                          (animal) => animal["id"] == newValue,
                          orElse: () => {},
                        );
                      });
                    },
                    items: registeredAnimals.map((animal) {
                      return DropdownMenuItem<int>(
                        value: animal["id"],
                        child: Text("${animal["name"]} - ${animal["species"]}"),
                      );
                    }).toList(),
                  ),
                ),
              ),
              SizedBox(height: 10),
              Text("Appointment Type",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[700]!),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedAppointmentType,
                    hint: Text("Choose", style: TextStyle(fontSize: 16)),
                    isExpanded: true,
                    onChanged: (String? newValue) {
                      setState(() => selectedAppointmentType = newValue);
                    },
                    items: ["General Checkup", "Emergency", "Vaccination"]
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type, style: TextStyle(fontSize: 16)),
                          ),
                        )
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (selectedAnimalId != null &&
                            selectedTime != null &&
                            selectedAppointmentType != null)
                        ? showConfirmationSheet
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (selectedAnimalId != null &&
                              selectedTime != null &&
                              selectedAppointmentType != null)
                          ? Colors.lightBlue
                          : Colors.lightBlue.withOpacity(0.5),
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text("Book Appointment",
                        style: TextStyle(fontSize: 16, color: Colors.white)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
