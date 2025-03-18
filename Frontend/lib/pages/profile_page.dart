import 'dart:convert';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/pages/doc_profile.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class AddAnimalDialog extends StatefulWidget {
  final Function(String, String, int, String, String) onAnimalAdded;

  const AddAnimalDialog({Key? key, required this.onAnimalAdded})
      : super(key: key);

  @override
  _AddAnimalDialogState createState() => _AddAnimalDialogState();
}

class _AddAnimalDialogState extends State<AddAnimalDialog> {
  final _nameController = TextEditingController();
  final _breedController = TextEditingController();
  final _ageController = TextEditingController();
  final _speciesController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<String?> _uploadImageToFirebase(File image) async {
    try {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      Reference storageRef = FirebaseStorage.instance.ref().child('animals/$fileName.jpg');
      UploadTask uploadTask = storageRef.putFile(image);
      TaskSnapshot snapshot = await uploadTask;
      return await snapshot.ref.getDownloadURL();
    } catch (e) {
      print("Error uploading image: $e");
      return null;
    }
  }

  void _registerAnimal() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select an image")));
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await _uploadImageToFirebase(_selectedImage!);

    setState(() {
      _isUploading = false;
    });

    if (imageUrl != null) {
      widget.onAnimalAdded(
        _nameController.text,
        _breedController.text,
        int.tryParse(_ageController.text) ?? 0,
        _speciesController.text,
        imageUrl,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Register Animal"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: "Name")),
          TextField(
              controller: _breedController,
              decoration: const InputDecoration(labelText: "Breed")),
          TextField(
              controller: _ageController,
              decoration: const InputDecoration(labelText: "Age"),
              keyboardType: TextInputType.number),
          TextField(
              controller: _speciesController,
              decoration: const InputDecoration(labelText: "Species")),
          const SizedBox(height: 10),
          _selectedImage != null
              ? Image.file(_selectedImage!,
                  height: 100, width: 100, fit: BoxFit.cover)
              : const Text("No image selected"),
          TextButton.icon(
            onPressed: _pickImage,
            icon: const Icon(Icons.photo_library),
            label: const Text("Pick Image"),
          ),
          if (_isUploading) const CircularProgressIndicator(),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
        ElevatedButton(
          onPressed: _registerAnimal,
          child: const Text("Register"),
        ),
      ],
    );
  }
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _registeredAnimals = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    fetchAnimals(1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String name = "Ezra Ariwomoi";
  String role = "Animal Owner";

  Future<void> registerAnimal(String name, String breed, int age,
      String species, String imageUrl, int ownerId) async {
    final url = Uri.parse('http://192.168.201.58:5000/register_animal');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "owner_id": ownerId,
        "name": name,
        "breed": breed,
        "age": age,
        "species": species,
        "image_url": imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      print("Animal registered successfully");
      fetchAnimals(ownerId);
    } else {
      print("Failed to register animal: ${response.body}");
    }
  }

  Future<void> fetchAnimals(int ownerId) async {
    final url =
        Uri.parse("http://192.168.201.187:5000/get_animals?owner_id=$ownerId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      setState(() {
        _registeredAnimals =
            List<Map<String, dynamic>>.from(jsonDecode(response.body));
      });
    } else {
      print("Failed to fetch animals");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.lightBlue,
        elevation: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 18.0),
          child: const Text(
            'Profile',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
            ),
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit_profile') {
                // Navigate to Edit Profile screen
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (context) => EditProfileScreen()),
                // );
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
                        onPressed: () {},
                        child: Text('Logout',
                            style: TextStyle(
                              color: const Color.fromARGB(255, 250, 109, 99),
                            )),
                      ),
                    ],
                  ),
                );
              } else if (value == 'help') {}
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
            ],
            icon: Icon(Icons.settings, color: Colors.black),
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: AssetImage('assets/user_guide1.png'),
              child: Align(
                alignment: Alignment.bottomRight,
                child: GestureDetector(
                  onTap: () {},
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.black,
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
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
            const SizedBox(height: 30),
            Container(
              height: 40,
              decoration: BoxDecoration(
                color: const Color.fromARGB(255, 248, 247, 247),
                borderRadius: BorderRadius.circular(2),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: Colors.lightBlue[100],
                  borderRadius: BorderRadius.circular(2),
                ),
                labelColor: Colors.black,
                unselectedLabelColor: const Color.fromARGB(255, 189, 189, 189),
                indicatorSize: TabBarIndicatorSize.tab,
                tabs: [
                  Tab(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Icon(Icons.menu),
                    ),
                  ),
                  Tab(
                    child: Container(
                      width: double.infinity,
                      alignment: Alignment.center,
                      child: Icon(Icons.bookmark_border_outlined),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildProfileTab(),
                  buildFavoritesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildProfileTab() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "Registered Animals",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => AddAnimalDialog(
                    onAnimalAdded: (name, breed, age, species, imageUrl) {
                      registerAnimal(name, breed, age, species, imageUrl, 1);
                    },
                  ),
                );
              },
              icon: const Icon(
                Icons.add,
                color: Colors.white,
              ),
              label: const Text("Add Animal"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.lightBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
        Expanded(
            child: ListView.builder(
              itemCount: _registeredAnimals.length,
              itemBuilder: (context, index) {
                final animal = _registeredAnimals[index];
                return ListTile(
                  leading: animal['image_url'] != null
                      ? Image.network(animal['image_url'], width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.pets),
                  title: Text(animal['name']),
                  subtitle: Text("${animal['breed']}, ${animal['age']} years"),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget buildFavoritesTab() {
    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const Text(
                "Your Trusted Doctors",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),

        // List of favorite doctors
        Expanded(
          child: ListView.builder(
            itemCount: 3,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DoctorProfilePage(
                        name: "Dr. David",
                        clinicName: "Vet Clinic Name",
                        imagePath: "assets/user_guide1.png",
                      ),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile Image
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.asset(
                                'assets/user_guide1.png',
                                width: 75,
                                height: 75,
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Doctor Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Dr. David',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Icon(
                                        Icons.verified,
                                        size: 16,
                                        color: Colors.blueAccent,
                                      ),
                                    ],
                                  ),
                                  Text(
                                    'Vet Clinic Name',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 5,
                        right: 8,
                        child: Row(
                          children: [
                            // Remove Button
                            SizedBox(
                              height: 28,
                              child: ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  backgroundColor:
                                      const Color.fromARGB(255, 250, 109, 99),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 3),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: const Text(
                                  "Remove",
                                  style: TextStyle(fontSize: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Arrow Button
                            Container(
                              width: 28,
                              height: 28,
                              decoration: const BoxDecoration(
                                color: Colors.black,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => DoctorProfilePage(
                                        name: "Dr. David",
                                        clinicName: "Vet Clinic Name",
                                        imagePath: "assets/user_guide1.png",
                                      ),
                                    ),
                                  );
                                },
                                icon: const Icon(Icons.arrow_forward,
                                    size: 16, color: Colors.white),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
