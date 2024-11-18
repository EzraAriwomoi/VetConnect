import 'package:flutter/material.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool isEditing = false;

  // Dummy user data
  String name = "John Doe";
  String role = "Animal Owner";
  String email = "john.doe@vetconnect.com";
  String phone = "+254 712 345 678";
  String address = "123 Green Valley, Nairobi";

  // Animal list
  List<Map<String, String>> animals = [
    {"name": "Buddy", "breed": "Golden Retriever", "age": "3 years"},
    {"name": "Mittens", "breed": "Persian Cat", "age": "2 years"},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        centerTitle: true,
        backgroundColor: Colors.lightBlue,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Picture
              CircleAvatar(
                radius: 60,
                backgroundImage: AssetImage('assets/user_guide1.png'),
                child: Align(
                  alignment: Alignment.bottomRight,
                  child: GestureDetector(
                    onTap: () {
                      // Logic to change profile picture
                      print("Change profile picture tapped");
                    },
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.lightBlue,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // User Name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                role,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 20),

              // Editable Details
              _buildDetailRow(Icons.email, "Email", email, (value) {
                email = value;
              }),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.phone, "Phone", phone, (value) {
                phone = value;
              }),
              const SizedBox(height: 10),
              _buildDetailRow(Icons.home, "Address", address, (value) {
                address = value;
              }),

              const SizedBox(height: 30),

              // Animal Registration Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Registered Animals",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => _showAnimalFormDialog(context, null),
                    icon: const Icon(Icons.add),
                    label: const Text("Add Animal"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // List of Registered Animals
              ...animals.map((animal) => _buildAnimalCard(context, animal)),

              const SizedBox(height: 20),

              // Save/Cancel Buttons
              if (isEditing)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                        print("Changes saved");
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.lightBlue,
                      ),
                      child: const Text("Save"),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                        });
                        print("Edit canceled");
                      },
                      child: const Text("Cancel"),
                    ),
                  ],
                ),

              // Edit Button
              if (!isEditing)
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.lightBlue,
                  ),
                  child: const Text("Edit Profile"),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String title, String value, Function(String) onChanged) {
    return Row(
      children: [
        Icon(icon, color: Colors.lightBlue),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              isEditing
                  ? TextFormField(
                      initialValue: value,
                      onChanged: onChanged,
                      decoration: const InputDecoration(
                        isDense: true,
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.lightBlue),
                        ),
                      ),
                    )
                  : Text(
                      value,
                      style: const TextStyle(fontSize: 16),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAnimalCard(BuildContext context, Map<String, String> animal) {
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: const Icon(Icons.pets, color: Colors.lightBlue),
        title: Text(animal["name"] ?? ""),
        subtitle: Text("${animal["breed"]}, ${animal["age"]}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showAnimalFormDialog(context, animal),
              icon: const Icon(Icons.edit, color: Colors.grey),
            ),
            IconButton(
              onPressed: () {
                setState(() {
                  animals.remove(animal);
                });
                print("Animal removed");
              },
              icon: const Icon(Icons.delete, color: Colors.red),
            ),
          ],
        ),
      ),
    );
  }

  void _showAnimalFormDialog(BuildContext context, Map<String, String>? animal) {
    final nameController =
        TextEditingController(text: animal != null ? animal["name"] : "");
    final breedController =
        TextEditingController(text: animal != null ? animal["breed"] : "");
    final ageController =
        TextEditingController(text: animal != null ? animal["age"] : "");

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(animal == null ? "Add Animal" : "Edit Animal"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: "Name"),
              ),
              TextField(
                controller: breedController,
                decoration: const InputDecoration(labelText: "Breed"),
              ),
              TextField(
                controller: ageController,
                decoration: const InputDecoration(labelText: "Age"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                if (animal != null) {
                  // Edit existing animal
                  setState(() {
                    animal["name"] = nameController.text;
                    animal["breed"] = breedController.text;
                    animal["age"] = ageController.text;
                  });
                } else {
                  // Add new animal
                  setState(() {
                    animals.add({
                      "name": nameController.text,
                      "breed": breedController.text,
                      "age": ageController.text,
                    });
                  });
                }
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.lightBlue),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
