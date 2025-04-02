import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/pages/login_page.dart';

class CreatePassword extends StatefulWidget {
  final String name;
  final String email;
  final String licenseNumber;
  final String nationalID;
  final String clinic;
  final String? specialization;

  const CreatePassword({
    super.key,
    required this.name,
    required this.email,
    required this.licenseNumber,
    required this.nationalID,
    required this.clinic,
    this.specialization,
  });

  @override
  _CreatePasswordState createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPasswordValid = true;

  Future<void> registerVeterinarian() async {
    if (_passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password fields cannot be empty!')),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Passwords do not match!')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final Uri url =
        Uri.parse('http://192.168.107.58:5000/register/veterinarian');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": widget.name,
          "email": widget.email,
          "password": _passwordController.text,
          "license_number": widget.licenseNumber,
          "national_id": widget.nationalID,
          "clinic": widget.clinic,
          "specialization": widget.specialization,
        }),
      );

      if (!mounted) return;
      setState(() {
        _isLoading = false;
      });

      final data = jsonDecode(response.body);
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Account created successfully!",
                style: TextStyle(color: Colors.white)),
            backgroundColor: const Color.fromARGB(255, 46, 160, 50),
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(Duration(seconds: 2));

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message'] ?? 'Registration failed. Try again!'),
            backgroundColor: const Color.fromARGB(255, 250, 109, 99),
          ),
        );
      }
    } catch (error) {
      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Something went wrong. Please try again later.'),
          backgroundColor: const Color.fromARGB(255, 250, 109, 99),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Icon(
                  Icons.lock,
                  size: 80,
                  color: context.theme.primecolor,
                ),
              ),
              Text(
                'You are almost there!!',
                style: TextStyle(
                  fontSize: 28,
                  color: context.theme.titletext,
                ),
              ),
              SizedBox(height: 10),
              Text(
                'Finish creating your account. Use a strong password.',
                style: TextStyle(
                  fontSize: 17,
                  color: context.theme.subtitletext,
                ),
              ),

              SizedBox(height: 40),

              // Password Input
              _buildPasswordField(
                _passwordController,
                'Password',
                _obscurePassword,
                (value) {
                  setState(() {
                    _obscurePassword = value;
                  });
                },
              ),
              SizedBox(height: 20),

              // Confirm Password Input
              _buildPasswordField(
                _confirmPasswordController,
                'Confirm Password',
                _obscureConfirmPassword,
                (value) {
                  setState(() {
                    _obscureConfirmPassword = value;
                  });
                },
              ),
              SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? () {} : registerVeterinarian,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primecolor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Text(
                          'Register',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                ),
              ),
              SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField(
    TextEditingController controller,
    String label,
    bool obscureText,
    Function(bool) onToggleVisibility,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      cursorHeight: 18,
      obscureText: obscureText,
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
            color: _isPasswordValid
                ? context.theme.primecolor
                : const Color.fromARGB(255, 250, 109, 99),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
              color: _isPasswordValid
                  ? context.theme.primecolor
                  : const Color.fromARGB(255, 250, 109, 99),
              width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: context.theme.subtitletext,
            size: 24,
          ),
          onPressed: () {
            onToggleVisibility(!obscureText);
          },
        ),
      ),
    );
  }
}
