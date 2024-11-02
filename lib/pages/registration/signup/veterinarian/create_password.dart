import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

class CreatePassword extends StatefulWidget {
  const CreatePassword({super.key});

  @override
  _CreatePasswordState createState() => _CreatePasswordState();
}

class _CreatePasswordState extends State<CreatePassword> {
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
            onPressed: () {
              
            },
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
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.theme.primecolor,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text('Register',
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
            color: context.theme.primecolor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor, width: 2.0),
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
