import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/pages/login_page.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

class ResetPasswordPage extends StatefulWidget {
  final String token;

  ResetPasswordPage({required this.token});

  @override
  _ResetPasswordPageState createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isPasswordValid = true;
  bool _isConfirmPasswordValid = true;

  Future<void> resetPassword() async {
    setState(() {
      _isPasswordValid = _passwordController.text.length >= 6;
      _isConfirmPasswordValid = _passwordController.text == _confirmPasswordController.text;
    });

    if (!_isPasswordValid || !_isConfirmPasswordValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://192.168.107.58:5000/reset_password');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "token": widget.token,
          "new_password": _passwordController.text
        }),
      );

      final responseData = jsonDecode(response.body);
      String message = responseData['message'] ?? 'Something went wrong. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );

      if (response.statusCode == 200) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Network error. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: context.theme.primecolor,
          elevation: 0,
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 120),
                SizedBox(height: 20),
                _buildPasswordField(),
                SizedBox(height: 15),
                _buildConfirmPasswordField(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : resetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primecolor,
                      disabledBackgroundColor: context.theme.primecolor.withOpacity(0.3),
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
                            "Reset Password",
                            style: TextStyle(fontSize: 17, color: Colors.white),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: _obscurePassword,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      decoration: InputDecoration(
        labelText: "New Password",
        labelStyle: TextStyle(fontSize: 18, color: context.theme.subtitletext),
        prefixIcon: Icon(Icons.lock, color: context.theme.primecolor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        errorText: _isPasswordValid ? null : 'Password must be at least 6 characters',
        suffixIcon: IconButton(
          icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: context.theme.subtitletext),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordField() {
    return TextField(
      controller: _confirmPasswordController,
      obscureText: _obscureConfirmPassword,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      decoration: InputDecoration(
        labelText: "Confirm New Password",
        labelStyle: TextStyle(fontSize: 18, color: context.theme.subtitletext),
        prefixIcon: Icon(Icons.lock, color: context.theme.primecolor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10.0)),
        errorText: _isConfirmPasswordValid ? null : 'Passwords do not match',
        suffixIcon: IconButton(
          icon: Icon(_obscureConfirmPassword ? Icons.visibility_off : Icons.visibility, color: context.theme.subtitletext),
          onPressed: () {
            setState(() {
              _obscureConfirmPassword = !_obscureConfirmPassword;
            });
          },
        ),
      ),
    );
  }
}
