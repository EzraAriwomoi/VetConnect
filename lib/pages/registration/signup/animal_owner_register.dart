import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/components/header/page_header.dart';

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
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _animalTypeController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            children: [
              PageHeader(
                title: 'Animal Owner Registration',
                subtitle: '',
              ),

              // Name Input
              _buildTextField(
                controller: _nameController,
                hint: 'Full Name',
              ),

              // Email Input
              _buildTextField(
                controller: _emailController,
                hint: 'Email',
                keyboardType: TextInputType.emailAddress,
              ),

              // Phone Number Input
              _buildTextField(
                controller: _phoneController,
                hint: 'Phone Number (e.g. 254...)',
                keyboardType: TextInputType.phone,
              ),

              // Location Input
              _buildTextField(
                controller: _locationController,
                hint: 'Location (County, Town)',
              ),

              // Animal type Input
              _buildTextField(
                controller: _animalTypeController,
                hint: 'Animal Type (e.g., Cattle, Dog)',
              ),

              // Password Input
              _buildPasswordField(
                controller: _passwordController,
                hint: 'Enter your password',
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              // Confirm Password Input
              _buildPasswordField(
                controller: _confirmPasswordController,
                hint: 'Confirm your password',
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              SizedBox(height: 20),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primecolor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text(
                    'Register',
                    style: TextStyle(fontSize: 17, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 18),
          cursorColor: context.theme.primecolor,
          cursorHeight: 18,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(fontSize: 18, color: context.theme.subtitletext),
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

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          style: TextStyle(fontSize: 18),
          cursorColor: context.theme.primecolor,
          cursorHeight: 18,
          obscureText: obscureText,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontSize: 18,
              color: context.theme.subtitletext,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: context.theme.subtitletext,
                size: 20,
              ),
              onPressed: onToggle,
            ),
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
