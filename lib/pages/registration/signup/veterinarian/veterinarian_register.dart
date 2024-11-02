import 'package:flutter/material.dart';
import 'package:vetconnect/components/Header/page_header.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

import './create_password.dart';

class VeterinarianRegisterPage extends StatefulWidget {
  const VeterinarianRegisterPage({super.key});

  @override
  _VeterinarianRegisterPageState createState() =>
      _VeterinarianRegisterPageState();
}

class _VeterinarianRegisterPageState extends State<VeterinarianRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _nationalID = TextEditingController();
  final TextEditingController _clinic = TextEditingController();

  String? _specialization;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.curvedpartcolor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            children: [
              PageHeader(
                title: 'Veterinarian Registration',
                subtitle: '',
              ),

              // Name Input
              _buildTextField(_nameController, 'Full Name'),
              SizedBox(height: 10),

              // Email Input
              _buildTextField(
                  _emailController, 'Email', TextInputType.emailAddress),
              SizedBox(height: 10),

              // National ID
              _buildTextField(_nationalID, 'National ID', TextInputType.number),
              SizedBox(height: 10),

              // Clinic Input
              _buildTextField(_clinic, 'Clinic'),
              SizedBox(height: 10),

              // License Number Input
              _buildTextField(_licenseController, 'License Number (e.g., KVB)'),
              SizedBox(height: 10),

              // Specialization Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: context.theme.primecolor,
                  ),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Container(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Text(
                        _specialization ??
                            'Specialization (e.g., Small Animals)',
                        style: TextStyle(
                            fontSize: 17,
                            color: _specialization == null
                                ? context.theme.subtitletext
                                : Colors.black),
                      ),
                    ),
                    value: _specialization,
                    items: <String>[
                      'Small Animal Medicine',
                      'Large Animal Medicine',
                      'Equine Medicine',
                      'Exotic Animal Medicine',
                      'Veterinary Surgery',
                      'Veterinary Dentistry',
                      'Reproduction and Theriogenology'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _specialization = value;
                      });
                    },
                    isExpanded: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(
                        Icons.arrow_drop_down,
                        color: context.theme.subtitletext,
                      ),
                    ),
                  ),
                ),
              ),

              SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CreatePassword()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primecolor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text('Continue',
                      style: TextStyle(fontSize: 17, color: Colors.white)),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      cursorHeight: 18,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontSize: 17,
          color: context.theme.subtitletext,
        ),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: context.theme.primecolor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor, width: 2.0),
        ),
      ),
    );
  }
}
