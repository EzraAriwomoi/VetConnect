import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/components/header/page_header.dart';
import 'dart:core';
import 'package:vetconnect/pages/registration/signup/animal_owner/password_file_owner.dart';

class AnimalOwnerRegisterPage extends StatefulWidget {
  const AnimalOwnerRegisterPage({super.key});

  @override
  _AnimalOwnerRegisterPageState createState() =>
      _AnimalOwnerRegisterPageState();
}

class _AnimalOwnerRegisterPageState extends State<AnimalOwnerRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  final _formKey = GlobalKey<FormState>();

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex =
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    if (value.startsWith('07')) {
      if (value.length != 10) {
        return 'Phone number must be 10 digits when starting with 07';
      }
    }
    if (value.startsWith('2547')) {
      if (value.length != 12) {
        return 'Phone number must be 12 digits when starting with 2547';
      }
    }
    return null;
  }

  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('07')) {
      return '254' + phone.substring(1);
    }
    return phone;
  }

  String? _validateRequiredField(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }
    return null;
  }

  Future<void> navigateToPasswordFileOwnerPage() async {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PasswordFileOwnerPage(
            name: _nameController.text,
            email: _emailController.text,
            phone: _formatPhoneNumber(_phoneController.text),
            location: _locationController.text,
          ),
        ),
      );
    }
  }

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
        child: Transform.translate(
          offset: Offset(0, -50),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  PageHeader(
                    title: 'Animal Owner Registration',
                    subtitle: '',
                  ),

                  // Name Input
                  _buildTextField(
                    controller: _nameController,
                    label: 'Full Name',
                    validator: _validateRequiredField,
                  ),

                  // Email Input
                  _buildTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _validateEmail,
                  ),

                  // Phone Number Input
                  _buildTextField(
                    controller: _phoneController,
                    label: 'Phone Number (e.g. 254...)',
                    keyboardType: TextInputType.phone,
                    validator: _validatePhone,
                  ),

                  // Location Input
                  _buildTextField(
                    controller: _locationController,
                    label: 'Location (County, Town)',
                    validator: _validateRequiredField,
                  ),

                  SizedBox(height: 30),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: navigateToPasswordFileOwnerPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primecolor,
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                      child: Text(
                        'Continue',
                        style: TextStyle(fontSize: 17, color: Colors.white),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          style: TextStyle(fontSize: 18),
          cursorColor: context.theme.primecolor,
          cursorHeight: 18,
          keyboardType: keyboardType,
          validator: validator,
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
              borderSide:
                  BorderSide(color: context.theme.primecolor, width: 2.0),
            ),
          ),
        ),
        SizedBox(height: 15),
      ],
    );
  }
}
