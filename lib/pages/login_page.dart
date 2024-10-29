import 'package:flutter/material.dart';
import 'package:vetconnect/components/colors.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0),
                      child: Image.asset(
                        'assets/logo.png',
                        height: 150,
                      ),
                    ),
                    SizedBox(height: 10),
                    // Title
                    Text(
                      'Welcome Back!!',
                      style: TextStyle(
                        fontSize: 26,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Email Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Email',
                          style: TextStyle(
                            fontSize: 17,
                          ),
                        ),
                        SizedBox(height: 5),
                        TextField(
                          style: TextStyle(
                            fontSize: 18,
                          ),
                          cursorColor: CustomColors.appblue,
                          cursorHeight: 20,
                          controller: _emailController,
                          decoration: InputDecoration(
                            hintText: 'Enter your email',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: CustomColors.greycolor,
                            ),
                            prefixIcon: Icon(Icons.email, color: CustomColors.greycolor),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: CustomColors.appblue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: CustomColors.appblue, width: 2.0),
                            ),
                          ),
                          keyboardType: TextInputType.emailAddress,
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    // Password Input
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Password',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 5),
                        TextField(
                          style: TextStyle(fontSize: 18),
                          cursorColor: CustomColors.appblue,
                          cursorHeight: 20,
                          controller: _passwordController,
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            hintStyle: TextStyle(
                              fontSize: 18,
                              color: CustomColors.greycolor,
                            ),
                            prefixIcon: Icon(Icons.lock, color: CustomColors.greycolor),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                color: CustomColors.greycolor,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: CustomColors.appblue),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0),
                              borderSide: BorderSide(color: CustomColors.appblue, width: 2.0),
                            ),
                          ),
                          obscureText: _obscurePassword,
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                    // Forgot Password Link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                          onTap: () {
                            // Navigate to the password recovery page
                          },
                          child: Text(
                            'Forgot Password?',
                            style: TextStyle(
                              color: CustomColors.appblue,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Login Button
                    SizedBox(
                      width: double.infinity, // Match width of input fields
                      child: ElevatedButton(
                        onPressed: () {
                          // Implement login functionality
                          String email = _emailController.text;
                          String password = _passwordController.text;
                          // Add your login logic here
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CustomColors.appblue,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                        child: Text(
                          'Login',
                          style: TextStyle(fontSize: 17, color: Colors.white),
                        ),
                      ),
                    ),
                    SizedBox(height: 60),
                    // OR Continue with Section
                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
                          child: Text(
                            "Or continue with",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            thickness: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 20),
                    // Continue with Google Button
                    SizedBox(
                      width: double.infinity, // Match width of input fields
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Implement Google sign-in functionality
                        },
                        icon: Image.asset(
                          'assets/google_icon.png',
                          height: 36,
                        ),
                        label: Text(
                          'Sign in with Google',
                          style: TextStyle(fontSize: 17, color: Colors.black),
                        ),
                        style: ButtonStyle(
                          backgroundColor: MaterialStateProperty.all(Colors.transparent),
                          overlayColor: MaterialStateProperty.all(const Color.fromARGB(255, 230, 229, 229)),
                          elevation: MaterialStateProperty.all(0),
                          side: MaterialStateProperty.all(BorderSide(color: CustomColors.greycolor)),
                          padding: MaterialStateProperty.all(EdgeInsets.symmetric(vertical: 8)),
                          shape: MaterialStateProperty.all(
                            RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.0),
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 70),
                  ],
                ),
              ),
            ),
            // Sign Up Link at the Bottom
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account? ",
                    style: TextStyle(
                      fontSize: 17,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      // Navigate to the sign-up page
                    },
                    child: Text(
                      'Sign Up',
                      style: TextStyle(
                        color: CustomColors.appblue,
                        fontSize: 17,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
