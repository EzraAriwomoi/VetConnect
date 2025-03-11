import 'package:flutter/material.dart';

class AppointmentPage extends StatefulWidget {
  @override
  _AppointmentPageState createState() => _AppointmentPageState();
}

class _AppointmentPageState extends State<AppointmentPage> {
  DateTime selectedDate = DateTime.now();
  String? selectedTime;
  String? selectedAppointmentType;

  List<String> availableTimes = [
    "08:00",
    "10:00",
    "11:00",
    "12:00",
    "14:00",
    "16:00"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Appointment"),
        backgroundColor: Colors.lightBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Select Date",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Theme(
              data: ThemeData(
                colorScheme: ColorScheme.light(
                  primary: const Color.fromARGB(255, 198, 236, 253),
                  onPrimary: const Color.fromARGB(255, 0, 165, 241),
                  onSurface: Colors.black,
                ),
                // textTheme: TextTheme(
                //   bodyLarge: TextStyle(fontWeight: FontWeight.bold),
                // ),
              ),
              child: CalendarDatePicker(
                initialDate: selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime(2025, 12, 31),
                onDateChanged: (date) {
                  setState(() {
                    selectedDate = date;
                  });
                },
                selectableDayPredicate: (date) {
                  return date
                      .isAfter(DateTime.now().subtract(Duration(days: 1)));
                },
              ),
            ),
            SizedBox(height: 20),
            Text("Available Time",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: availableTimes.map((time) {
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedTime = time;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.cyan),
                      borderRadius: BorderRadius.circular(10),
                      color: selectedTime == time
                          ? Colors.cyan.withOpacity(0.2)
                          : Colors.transparent,
                    ),
                    child: Text(
                      time,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            Text("Appointment Type",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(10),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedAppointmentType,
                  hint: Text("Choose", style: TextStyle(fontSize: 16)),
                  isExpanded: true,
                  onChanged: (String? newValue) {
                    setState(() {
                      selectedAppointmentType = newValue;
                    });
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
            SizedBox(height: 20),
            Center(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (selectedTime != null &&
                        selectedAppointmentType != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              "Appointment booked on ${selectedDate.toLocal()} at $selectedTime"),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
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
    );
  }
}
