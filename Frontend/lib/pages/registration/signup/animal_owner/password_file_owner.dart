import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/pages/login_page.dart';

class PasswordFileOwnerPage extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String location;

  const PasswordFileOwnerPage({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.location,
  });

  @override
  _PasswordFileOwnerPageState createState() => _PasswordFileOwnerPageState();
}

class _PasswordFileOwnerPageState extends State<PasswordFileOwnerPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isPasswordValid = true;

  Future<void> registerAnimalOwner() async {
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
        Uri.parse('http://192.168.201.58:5000/register/animal_owner');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "name": widget.name,
          "email": widget.email,
          "password": _passwordController.text,
          "phone": widget.phone,
          "location": widget.location,
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
                controller: _passwordController,
                label: 'Password',
                obscureText: _obscurePassword,
                onToggle: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
              ),

              SizedBox(height: 20),

              // Confirm Password Input
              _buildPasswordField(
                controller: _confirmPasswordController,
                label: 'Confirm password',
                obscureText: _obscureConfirmPassword,
                onToggle: () {
                  setState(() {
                    _obscureConfirmPassword = !_obscureConfirmPassword;
                  });
                },
              ),

              SizedBox(height: 30),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? () {} : registerAnimalOwner,
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
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
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
            labelText: label,
            labelStyle: TextStyle(
              fontSize: 17,
              color: context.theme.subtitletext,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off : Icons.visibility,
                color: context.theme.subtitletext,
                size: 24,
              ),
              onPressed: onToggle,
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
          ),
        ),
      ],
    );
  }
}
