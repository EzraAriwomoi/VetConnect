import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class SelectVeterinarianScreen extends StatefulWidget {
  @override
  _SelectVeterinarianScreenState createState() =>
      _SelectVeterinarianScreenState();
}

class _SelectVeterinarianScreenState extends State<SelectVeterinarianScreen> {
  List<dynamic> veterinarians = [];
  bool isLoading = true;
  bool hasError = false;

  @override
  void initState() {
    super.initState();
    fetchVeterinarians();
  }

  Future<void> fetchVeterinarians() async {
    final url = Uri.parse('http://192.168.201.58:5000/get_veterinarians');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        setState(() {
          veterinarians = jsonDecode(response.body);
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Select a Veterinarian',
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 3,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : hasError
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: const Color.fromARGB(255, 250, 109, 99),
                        size: 50,
                      ),
                      SizedBox(height: 10),
                      Text(
                        "Oops! Couldn't load veterinarians.",
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 10),
                      ElevatedButton.icon(
                        onPressed: fetchVeterinarians,
                        icon: Icon(Icons.refresh),
                        label: Text("Retry"),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: veterinarians.length,
                  padding: EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    final vet = veterinarians[index];

                    return Card(
                      elevation: 4,
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(12),
                        leading: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.grey[300],
                          backgroundImage: vet['profileImage'] != null
                              ? NetworkImage(vet['profileImage'])
                              : AssetImage('assets/logo.png') as ImageProvider,
                        ),
                        title: Text(
                          "Dr. ${vet['name']}",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        subtitle: Text(
                          vet['clinic'] ?? 'No clinic info available',
                          style: TextStyle(color: Colors.grey[700]),
                        ),
                        trailing: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.lightBlue.withOpacity(0.1),
                          ),
                          padding: EdgeInsets.all(8),
                          child: Icon(
                            Icons.chat_bubble_outline,
                            color: Colors.lightBlue,
                          ),
                        ),
                        onTap: () {
                          Navigator.pop(context, {
                            'chatRoomId': vet['email'],
                            'vetName': "Dr. ${vet['name']}",
                          });
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
