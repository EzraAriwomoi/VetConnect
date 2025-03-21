import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class EditAnimalDialog extends StatefulWidget {
  final Map<String, dynamic> animal;

  const EditAnimalDialog({Key? key, required this.animal}) : super(key: key);

  @override
  _EditAnimalDialogState createState() => _EditAnimalDialogState();
}

class _EditAnimalDialogState extends State<EditAnimalDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _breedController;
  late TextEditingController _colorController;
  String? _selectedSpecies;
  String? _selectedGender;
  DateTime? _selectedDateOfBirth;
  File? _selectedImage;
  bool _isUpdating = false;

  final List<String> speciesList = ["Dog", "Cat", "Rabbit", "Bird", "Other"];
  final List<String> genderList = ["Male", "Female"];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.animal['name']);
    _breedController = TextEditingController(text: widget.animal['breed']);
    _colorController = TextEditingController(text: widget.animal['color']);
    _selectedSpecies = widget.animal['species'];
    _selectedGender = widget.animal['gender'];
    _selectedDateOfBirth =
        DateTime.tryParse(widget.animal['date_of_birth'] ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _breedController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _captureImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateOfBirth ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _selectedDateOfBirth = picked;
      });
    }
  }

  Future<void> _updateAnimal() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isUpdating = true;
  });

  String imageUrl = widget.animal['image_url'];

  if (_selectedImage != null) {
    imageUrl = await _uploadImageToServer(_selectedImage!);
    if (imageUrl.isEmpty) {
      setState(() {
        _isUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to upload image.")));
      return;
    }
  }

  final url = Uri.parse(
      'http://192.168.201.58:5000/update_animal/${widget.animal['id']}');

  final response = await http.put(
    url,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode({
      "name": _nameController.text,
      "breed": _breedController.text,
      "color": _colorController.text,
      "species": _selectedSpecies,
      "gender": _selectedGender,
      "date_of_birth": _selectedDateOfBirth != null
          ? "${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}"
          : widget.animal['date_of_birth'],
      "image_url": imageUrl,
    }),
  );

  setState(() {
    _isUpdating = false;
  });

  if (response.statusCode == 200) {
    // Update UI with new values
    final updatedAnimal = {
      "id": widget.animal['id'],
      "name": _nameController.text,
      "breed": _breedController.text,
      "color": _colorController.text,
      "species": _selectedSpecies,
      "gender": _selectedGender,
      "date_of_birth": _selectedDateOfBirth != null
          ? "${_selectedDateOfBirth!.year}-${_selectedDateOfBirth!.month.toString().padLeft(2, '0')}-${_selectedDateOfBirth!.day.toString().padLeft(2, '0')}"
          : widget.animal['date_of_birth'],
      "image_url": imageUrl,
    };

    Navigator.pop(context, updatedAnimal);
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to update animal details.")));
  }
}

  Future<String> _uploadImageToServer(File imageFile) async {
    var request = http.MultipartRequest(
        'POST', Uri.parse('http://192.168.201.58:5000/upload_image'));

    request.files
        .add(await http.MultipartFile.fromPath('image', imageFile.path));

    var response = await request.send();
    if (response.statusCode == 200) {
      var responseData = await response.stream.bytesToString();
      var jsonResponse = jsonDecode(responseData);
      return jsonResponse['image_url'] ?? "";
    }
    return "";
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Edit Animal",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.lightBlue,
          )),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(labelText: "Name"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a name" : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedSpecies,
                items: speciesList.map((species) {
                  return DropdownMenuItem(value: species, child: Text(species));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedSpecies = value;
                  });
                },
                decoration: InputDecoration(labelText: "Species"),
                validator: (value) => value == null ? "Select a species" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _breedController,
                decoration: InputDecoration(labelText: "Breed"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a breed" : null,
              ),
              SizedBox(height: 10),
              DropdownButtonFormField<String>(
                value: _selectedGender,
                items: genderList.map((gender) {
                  return DropdownMenuItem(value: gender, child: Text(gender));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value;
                  });
                },
                decoration: InputDecoration(labelText: "Gender"),
                validator: (value) => value == null ? "Select a gender" : null,
              ),
              SizedBox(height: 10),
              TextFormField(
                controller: _colorController,
                decoration: InputDecoration(labelText: "Color"),
                validator: (value) =>
                    value!.isEmpty ? "Please enter a color" : null,
              ),
              SizedBox(height: 10),
              ListTile(
                title: Text(
                  _selectedDateOfBirth == null
                      ? "Select Date of Birth"
                      : _selectedDateOfBirth!.toIso8601String().split('T')[0],
                ),
                trailing: Icon(
                  Icons.calendar_today,
                  color: Colors.lightBlue,
                ),
                onTap: _pickDate,
              ),
              SizedBox(height: 10),
              _selectedImage != null
                  ? Image.file(_selectedImage!,
                      height: 100, width: 100, fit: BoxFit.cover)
                  : Image.network(widget.animal['image_url'],
                      height: 100, width: 100, fit: BoxFit.cover),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _pickImage,
                    icon: Icon(
                      Icons.photo_library,
                      color: Colors.lightBlue,
                    ),
                    label: Text(
                      "Upload Image",
                      style: TextStyle(
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _captureImage,
                    icon: Icon(
                      Icons.camera_alt,
                      color: Colors.lightBlue,
                    ),
                    label: Text(
                      "Take Photo",
                      style: TextStyle(
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isUpdating)
                CircularProgressIndicator(
                  color: Colors.lightBlue,
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("Cancel", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          onPressed: _updateAnimal,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.lightBlue,
            foregroundColor: Colors.white,
          ),
          child: Text(
            "Update",
          ),
        ),
      ],
    );
  }
}
