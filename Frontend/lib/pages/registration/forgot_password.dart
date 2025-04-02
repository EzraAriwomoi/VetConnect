import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:vetconnect/components/extension/custom_theme.dart';

class ForgotPasswordPage extends StatefulWidget {
  @override
  _ForgotPasswordPageState createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isEmailValid = true;

  Future<void> sendResetLink() async {
    setState(() {
      _isEmailValid = _emailController.text.isNotEmpty &&
          RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}")
              .hasMatch(_emailController.text);
    });

    if (!_isEmailValid) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final url = Uri.parse('http://192.168.107.58:5000/forgot_password');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({"email": _emailController.text}),
    );

    setState(() {
      _isLoading = false;
    });

    final responseData = jsonDecode(response.body);
    String message =
        responseData['message'] ?? 'Something went wrong. Please try again.';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: context.theme.primecolor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {},
            itemBuilder: (BuildContext context) {
              return [
                PopupMenuItem<String>(
                  value: 'Help',
                  child: Container(
                    color: Colors.white,
                    child: Text(
                      'Help',
                      style: TextStyle(color: Colors.black),
                    ),
                  ),
                  height: 30,
                ),
              ];
            },
            icon: Icon(Icons.more_vert, color: Colors.white),
            offset: Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            constraints: BoxConstraints(
              minWidth: 100,
              maxHeight: 50,
            ),
            color: Colors.white,
          )
        ],
      ),
      body: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset('assets/logo.png', height: 150),
                SizedBox(height: 20),
                Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: context.theme.titletext,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Enter your email to receive a password reset link.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 16, color: context.theme.subtitletext),
                ),
                SizedBox(height: 20),
                _buildEmailField(),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primecolor,
                      disabledBackgroundColor:
                          context.theme.primecolor.withOpacity(0.3),
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
                            'Send Reset Link',
                            style: TextStyle(fontSize: 17, color: Colors.white),
                          ),
                  ),
                ),
                SizedBox(height: 40),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Back to Login',
                    style: TextStyle(
                        fontSize: 17, color: context.theme.primecolor),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: _emailController,
      focusNode: _emailFocusNode,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      decoration: InputDecoration(
        labelText: 'Email',
        labelStyle: TextStyle(fontSize: 18, color: context.theme.subtitletext),
        prefixIcon: Icon(Icons.email, color: context.theme.primecolor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: _isEmailValid
                ? context.theme.primecolor
                : const Color.fromARGB(255, 250, 109, 99),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(
            color: _isEmailValid
                ? context.theme.primecolor
                : const Color.fromARGB(255, 250, 109, 99),
            width: 2.0,
          ),
        ),
        errorText: _isEmailValid ? null : 'Enter a valid email',
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }
}
