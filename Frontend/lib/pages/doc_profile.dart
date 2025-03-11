import 'package:flutter/material.dart';
import 'package:vetconnect/pages/appointment_page.dart';

class DoctorProfilePage extends StatefulWidget {
  final String name;
  final String clinicName;
  final String imagePath;

  const DoctorProfilePage({
    Key? key,
    required this.name,
    required this.clinicName,
    required this.imagePath,
  }) : super(key: key);

  @override
  _DoctorProfilePageState createState() => _DoctorProfilePageState();
}

class _DoctorProfilePageState extends State<DoctorProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.name),
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
                    widget.name,
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
                  SingleChildScrollView(child: buildReviewsTab()),
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
                    "Location: ${widget.clinicName}, Place of vet",
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
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hello! I'm Dr. David, a dedicated veterinarian with 4 years of experience in caring for animals of all shapes and sizes. I specialize in small animal medicine and I believe in a gentle, personalized approach to veterinary care. Whether it's a routine check-up, preventive care, or a complex medical case, I'm here to ensure your furry (or feathered!) friend gets the best treatment possible.",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildReviewsTab() {
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
            SizedBox(
              height: 200,
              child: ListView.builder(
                itemCount: 5,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text("A${index + 1}"),
                      ),
                      title: Text("User ${index + 1}"),
                      subtitle: Text("Great experience with Dr. David!"),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.bottomRight,
              child: TextButton(
                onPressed: () {},
                child: Text("View more",
                    style: TextStyle(color: Colors.blueAccent)),
              ),
            ),
          ],
        ),
      ),
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
                          builder: (context) => AppointmentPage()),
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
