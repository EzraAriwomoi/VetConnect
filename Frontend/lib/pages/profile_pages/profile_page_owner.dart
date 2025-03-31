import 'dart:convert';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:vetconnect/pages/animal_details_page.dart';
import 'package:vetconnect/pages/doc_profile.dart';

class ProfilePageOwner extends StatefulWidget {
  @override
  _ProfilePageOwnerState createState() => _ProfilePageOwnerState();
}

class AddAnimalDialog extends StatefulWidget {
  final Function(String, String, String, String, String, String, String)
      onAnimalAdded;

  const AddAnimalDialog({Key? key, required this.onAnimalAdded})
      : super(key: key);

  @override
  _AddAnimalDialogState createState() => _AddAnimalDialogState();
}

class _AddAnimalDialogState extends State<AddAnimalDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _colorController = TextEditingController();
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  File? _selectedImage;
  String? _selectedSpecies;
  String? _selectedBreed;
  bool _isUploading = false;

  final List<String> speciesList = ['Dog', 'Cat', 'Bird', 'Reptile', 'Other'];
  final Map<String, List<String>> breedOptions = {
    'Dog': ['German Shepherd', 'Labrador', 'Bulldog', 'Poodle'],
    'Cat': ['Persian', 'Maine Coon', 'Siamese', 'Bengal'],
    'Bird': ['Parrot', 'Canary', 'Cockatoo', 'Finch'],
    'Reptile': ['Iguana', 'Gecko', 'Python', 'Tortoise'],
    'Other': ['Unknown'],
  };

  Future<void> _pickImage(ImageSource source) async {
    final pickedFile = await ImagePicker().pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() {
        _selectedDateOfBirth = pickedDate;
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    var uri = Uri.parse('http://192.168.166.58:5000/upload_image');
    var request = http.MultipartRequest('POST', uri);
    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var json = jsonDecode(responseData);
      return json['image_url'];
    } else {
      return null;
    }
  }

  void _registerAnimal() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    String? imageUrl = await _uploadImageToCloudinary(_selectedImage!);

    setState(() {
      _isUploading = false;
    });

    if (imageUrl != null) {
      widget.onAnimalAdded(
        _nameController.text.trim(),
        _selectedBreed!,
        _selectedSpecies!,
        _selectedDateOfBirth!.toIso8601String().split('T')[0],
        _selectedGender ?? "",
        _colorController.text,
        imageUrl,
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to upload image")),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    // fetchVeterinarians();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        "Register Animal",
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.lightBlue,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Name Field
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: "Name",
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a name" : null,
              ),
              SizedBox(height: 12),

              // Species Dropdown
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                items: speciesList.map((species) {
                  return DropdownMenuItem(value: species, child: Text(species));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecies = value;
                    _selectedBreed = null;
                  });
                },
                decoration: InputDecoration(
                  labelText: "Species",
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null ? "Select a species" : null,
              ),
              SizedBox(height: 12),

              // Breed Dropdown
              if (_selectedSpecies != null)
                DropdownButtonFormField<String>(
                  value: _selectedBreed,
                  items: breedOptions[_selectedSpecies!]!.map((breed) {
                    return DropdownMenuItem(value: breed, child: Text(breed));
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedBreed = value;
                    });
                  },
                  decoration: InputDecoration(
                    labelText: "Breed",
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null ? "Select a breed" : null,
                ),
              SizedBox(height: 12),

              // Date of Birth Picker
              GestureDetector(
                onTap: _pickDate,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: "Date of Birth",
                    border: OutlineInputBorder(),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDateOfBirth == null
                            ? "Select Date"
                            : DateFormat('yyyy-MM-dd')
                                .format(_selectedDateOfBirth!),
                        style: TextStyle(fontSize: 16, color: Colors.black87),
                      ),
                      Icon(Icons.calendar_today, color: Colors.lightBlue),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),

              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: ["Male", "Female"]
                    .map((gender) =>
                        DropdownMenuItem(value: gender, child: Text(gender)))
                    .toList(),
                onChanged: (value) => setState(() => _selectedGender = value),
                decoration: InputDecoration(labelText: "Gender"),
              ),
              SizedBox(height: 12),

              TextField(
                  controller: _colorController,
                  decoration: InputDecoration(labelText: "Color")),
              SizedBox(height: 12),

              // Image Preview
              _selectedImage != null
                  ? Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(_selectedImage!,
                              height: 120, width: 120, fit: BoxFit.cover),
                        ),
                        TextButton(
                          onPressed: () =>
                              setState(() => _selectedImage = null),
                          child: Text(
                            "Remove Image",
                            style: TextStyle(
                              color: const Color.fromARGB(255, 250, 109, 99),
                            ),
                          ),
                        )
                      ],
                    )
                  : Text("No image selected",
                      style: TextStyle(color: Colors.grey)),

              // Image Upload & Take Photo Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: Icon(Icons.photo_library, color: Colors.white),
                    label: Text("Upload"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: Icon(Icons.camera_alt, color: Colors.white),
                    label: Text("Take Photo"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),

              if (_isUploading)
                const CircularProgressIndicator(
                  color: Colors.lightBlue,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text("Cancel", style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _registerAnimal,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
          child: Text("Register"),
        ),
      ],
    );
  }
}

class _ProfilePageOwnerState extends State<ProfilePageOwner>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _registeredAnimals = [];
  int? loggedInUserId;
  List<Map<String, dynamic>> favoriteVeterinarians = [];
  bool isLoading = true;
  bool isFetchingUser = true;
  String ownerName = "Owner";

  @override
  void initState() {
    super.initState();
    fetchAnimalsForCurrentUser();
    _tabController = TabController(length: 2, vsync: this);
    fetchUserId(FirebaseAuth.instance.currentUser?.email ?? "").then((_) {
      if (loggedInUserId != null) {
        setState(() {
          fetchFavorites(loggedInUserId!);
        });
      }
    });
  }

  Future<void> fetchUserId(String email) async {
    print("Fetching user ID for: $email");

    final response = await http.get(
      Uri.parse('http://192.168.166.58:5000/get_user?email=$email'),
    );

    print("Response from get_user: ${response.body}");

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      if (userData.containsKey("id")) {
        setState(() {
          loggedInUserId = userData["id"];
          ownerName = userData['name'];
        });
        print("User ID set: $loggedInUserId");
      } else {
        print("User ID missing in response");
      }
    } else {
      print("Error fetching user ID: ${response.body}");
    }
  }

  Future<List<Map<String, dynamic>>> fetchFavorites(int ownerId) async {
    try {
      final response = await http.get(
        Uri.parse('http://192.168.166.58:5000/get_favorites?owner_id=$ownerId'),
      );

      print("Raw Favorites Response: ${response.body}");

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);

        print("Parsed Favorites Data: $data");

        return data.map((vet) {
          return {
            "id": vet["id"] is int
                ? vet["id"]
                : int.tryParse(vet["id"].toString()) ?? 0,
            "name": vet["name"] ?? "Unknown Vet",
            "clinic": vet["clinic"] ?? "Unknown Clinic",
            "profile_image":
                vet["profile_image"] ?? "assets/default_profile.png",
          };
        }).toList();
      } else {
        throw Exception("Failed to load favorites");
      }
    } catch (e) {
      print("Error fetching favorites: $e");
      return [];
    }
  }

  Future<void> removeFavorite(int ownerId, int vetId) async {
    try {
      final response = await http.delete(
        Uri.parse('http://192.168.166.58:5000/remove_favorite'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"owner_id": ownerId, "veterinarian_id": vetId}),
      );

      if (response.statusCode == 200) {
        print("Favorite removed successfully");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Removed from favorites!"),
            backgroundColor: const Color.fromARGB(255, 54, 155, 58),
          ),
        );
        setState(() {
          favoriteVeterinarians.removeWhere((vet) => vet["id"] == vetId);
        });

        fetchFavorites(ownerId);
      } else {
        print("Error removing favorite: ${response.body}");
      }
    } catch (e) {
      print("Exception: $e");
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String role = "Animal Owner";

  Future<void> registerAnimal(
      String name,
      String breed,
      String species,
      String dob,
      String gender,
      String color,
      String imageUrl,
      int ownerId) async {
    final url = Uri.parse('http://192.168.166.58:5000/register_animal');

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "owner_id": ownerId,
        "name": name,
        "breed": breed,
        "species": species,
        "date_of_birth": dob,
        "gender": gender,
        "color": color,
        "image_url": imageUrl,
      }),
    );

    if (response.statusCode == 201) {
      print("Animal registered successfully");

      await fetchAnimals(ownerId);
    } else {
      print("Failed to register animal: ${response.body}");
    }
  }

  void fetchAnimalsForCurrentUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final response = await http.get(
          Uri.parse("http://192.168.166.58:5000/get_user?email=${user.email}"),
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          int ownerId = data['id'];
          fetchAnimals(ownerId);
        } else {
          print("Failed to fetch user details: ${response.body}");
        }
      } catch (e) {
        print("Error fetching user ID: $e");
      }
    }
  }

  Future<void> fetchAnimals(int ownerId) async {
    final url =
        Uri.parse("http://192.168.166.58:5000/get_animals?owner_id=$ownerId");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      List<Map<String, dynamic>> animals =
          List<Map<String, dynamic>>.from(jsonDecode(response.body));

      print("Fetched Animals: $animals");

      setState(() {
        _registeredAnimals = animals;
      });
    } else {
      print("Failed to fetch animals: ${response.body}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
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
            icon: const Icon(Icons.settings, color: Colors.black,),
            tooltip: 'Settings',
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            color: Colors.white,
          ),
        ],
      ),
      body: RefreshIndicator(
        color: Colors.lightBlue,
        onRefresh: () async {
          fetchAnimalsForCurrentUser();
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundImage: AssetImage('assets/default_profile.png'),
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
                  ownerName,
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
                    unselectedLabelColor:
                        const Color.fromARGB(255, 189, 189, 189),
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
                SizedBox(
                  height: MediaQuery.of(context).size.height - 200,
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      buildProfileTab(),
                      buildFavoritesTab(loggedInUserId ?? 0),
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

  Widget buildProfileTab() {
    return Column(
      children: [
        if (_registeredAnimals.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Registered Animals",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    final user = FirebaseAuth.instance.currentUser;
                    if (user != null) {
                      try {
                        final response = await http.get(
                          Uri.parse(
                              "http://192.168.166.58:5000/get_user?email=${user.email}"),
                        );

                        if (response.statusCode == 200) {
                          final data = jsonDecode(response.body);
                          if (data.containsKey('id')) {
                            int ownerId = data['id'];
                            showDialog(
                              context: context,
                              builder: (context) => AddAnimalDialog(
                                onAnimalAdded: (name, breed, species, dob,
                                    gender, color, imageUrl) {
                                  registerAnimal(name, breed, species, dob,
                                      gender, color, imageUrl, ownerId);
                                },
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print("Error fetching user ID: $e");
                      }
                    }
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
          ),

        const SizedBox(height: 10),

        // No Data Section
        if (_registeredAnimals.isEmpty)
          SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/no_data.png",
                  height: 150,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No animals registered yet",
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Start by adding your first animal!",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddAnimalDialog(
                        onAnimalAdded: (name, breed, species, dob, gender,
                            color, imageUrl) async {
                          final user = FirebaseAuth.instance.currentUser;
                          if (user != null) {
                            try {
                              final response = await http.get(
                                Uri.parse(
                                    "http://192.168.166.58:5000/get_user?email=${user.email}"),
                              );

                              if (response.statusCode == 200) {
                                final data = jsonDecode(response.body);
                                if (data.containsKey('id')) {
                                  int ownerId = data['id'];

                                  registerAnimal(name, breed, species, dob,
                                      gender, color, imageUrl, ownerId);
                                }
                              }
                            } catch (e) {
                              print("Error fetching user ID: $e");
                            }
                          }
                        },
                      ),
                    );
                  },
                  icon: const Icon(
                    Icons.add,
                    color: Colors.lightBlue,
                  ),
                  label: const Text("Add Animal"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    backgroundColor: const Color.fromARGB(255, 248, 253, 255),
                    side: BorderSide(color: Colors.lightBlue),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: _registeredAnimals.length,
              itemBuilder: (context, index) {
                final animal = _registeredAnimals[index];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => AnimalDetailsPage(
                          animal: animal,
                          animalId: animal['id'],
                        ),
                      ),
                    );
                  },
                  child: Container(
                    margin:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
                    padding: const EdgeInsets.all(6),
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
                            ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: animal['image_url'] != null &&
                                      animal['image_url'].startsWith('http')
                                  ? Image.network(
                                      animal['image_url'],
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.asset(
                                      'assets/logo.png',
                                      width: 75,
                                      height: 75,
                                      fit: BoxFit.cover,
                                    ),
                            ),
                            const SizedBox(width: 15),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    animal['name'],
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${animal['breed']}, ${animal['age']}',
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
                        Positioned(
                          bottom: 0,
                          right: 5,
                          child: SizedBox(
                            height: 28,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => AnimalDetailsPage(
                                      animal: animal,
                                      animalId: animal['id'],
                                    ),
                                  ),
                                );
                              },
                              style: OutlinedButton.styleFrom(
                                backgroundColor: Colors.white,
                                side: BorderSide(color: Colors.lightBlue),
                                foregroundColor: Colors.lightBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Text(
                                    "View more",
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  SizedBox(width: 5),
                                  Icon(
                                    Icons.arrow_forward,
                                    size: 14,
                                    color: Colors.lightBlue,
                                  ),
                                ],
                              ),
                            ),
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

  Widget buildFavoritesTab(int ownerId) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: fetchFavorites(ownerId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(
            color: Colors.lightBlue,
          ));
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text("Error loading favorites"),
            ),
          );
        }

        List<Map<String, dynamic>> favoriteVeterinarians = snapshot.data ?? [];

        if (favoriteVeterinarians.isEmpty) {
          return SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  "assets/no_data.png",
                  height: 150,
                ),
                const SizedBox(height: 10),
                const Text(
                  "No favorite veterinarians yet",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
                  "Start by adding your trusted veterinarians!",
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                const SizedBox(height: 15),
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pushNamed(context, "/home");
                  },
                  icon: const Icon(
                    Icons.search,
                    color: Colors.lightBlue,
                  ),
                  label: const Text("Find Veterinarians"),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.lightBlue,
                    backgroundColor: const Color.fromARGB(255, 248, 253, 255),
                    side: const BorderSide(color: Colors.lightBlue),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          );
        }

        return Column(
          children: [
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
            Expanded(
              child: ListView.builder(
                itemCount: favoriteVeterinarians.length,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemBuilder: (context, index) {
                  final vet = favoriteVeterinarians[index];

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DoctorProfilePage(
                            vetId: vet["id"],
                            name: vet["name"],
                            clinicName: vet["clinic"],
                            imagePath: vet["profile_image"] ??
                                "assets/default_profile.png",
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
                                  child: vet["profile_image"] != null &&
                                          vet["profile_image"]
                                              .startsWith("http")
                                      ? Image.network(
                                          vet["profile_image"],
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                          errorBuilder:
                                              (context, error, stackTrace) {
                                            return Image.asset(
                                                'assets/default_profile.png',
                                                width: 75,
                                                height: 75,
                                                fit: BoxFit.cover);
                                          },
                                        )
                                      : Image.asset(
                                          'assets/default_profile.png',
                                          width: 75,
                                          height: 75,
                                          fit: BoxFit.cover,
                                        ),
                                ),
                                const SizedBox(width: 12),

                                // Doctor Details
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            vet["name"],
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Icon(
                                            Icons.verified,
                                            size: 16,
                                            color: Colors.blueAccent,
                                          ),
                                        ],
                                      ),
                                      Text(
                                        vet["clinic"],
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
                                    onPressed: () {
                                      removeFavorite(ownerId, vet["id"]);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color.fromARGB(
                                          255, 238, 110, 110),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 3),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: const Text("Remove",
                                        style: TextStyle(fontSize: 12)),
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
                                          builder: (context) =>
                                              DoctorProfilePage(
                                            vetId: vet["id"],
                                            name: vet["name"],
                                            clinicName: vet["clinic"],
                                            imagePath: vet["profile_image"] ??
                                                "assets/default_profile.png",
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
      },
    );
  }
}
