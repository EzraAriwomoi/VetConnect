import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/pages/homepage.dart';

class PasswordFileOwnerPage extends StatefulWidget {
  const PasswordFileOwnerPage({super.key});

  @override
  _PasswordFileOwnerPageState createState() => _PasswordFileOwnerPageState();
}

class _PasswordFileOwnerPageState extends State<PasswordFileOwnerPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

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
                  onPressed: () {
                    // Navigator.push(
                    //   context,
                    //   MaterialPageRoute(builder: (context) => HomePage()),
                    // );
                  },
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
      ],
    );
  }
}
