import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import 'package:vetconnect/components/controls/bottom_navigations.dart';
import 'package:vetconnect/pages/registration/forgot_password.dart';
import 'package:vetconnect/pages/registration/selection_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController1 = TextEditingController();
  final TextEditingController _passwordController1 = TextEditingController();
  bool _obscurePassword1 = true;
  bool _isLoading = false;
  bool _isEmailValid = true;
  bool _isPasswordValid = true;
  int? loggedInUserId;
  String? loggedInUserType;

  // Future<void> _login() async {
  //   setState(() {
  //     _isEmailValid = _emailController1.text.isNotEmpty &&
  //         RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
  //             .hasMatch(_emailController1.text);
  //     _isPasswordValid = _passwordController1.text.isNotEmpty;
  //   });

  //   if (!_isEmailValid || !_isPasswordValid) {
  //     return;
  //   }

  //   setState(() {
  //     _isLoading = true;
  //   });

  //   final response = await http.post(
  //     Uri.parse('http://192.168.107.58:5000/login'),
  //     headers: {'Content-Type': 'application/json'},
  //     body: jsonEncode({
  //       'email': _emailController1.text,
  //       'password': _passwordController1.text,
  //     }),
  //   );

  //   final data = jsonDecode(response.body);

  //   if (response.statusCode == 200) {
  //     String userType = data['user_type'];
  //     await fetchUserId(_emailController1.text);

  //     if (loggedInUserId == null) {
  //       print("Fetch user ID failed! Cannot proceed.");
  //       return;
  //     }

  //     try {
  //       await FirebaseAuth.instance.signInWithEmailAndPassword(
  //         email: _emailController1.text,
  //         password: _passwordController1.text,
  //       );

  //       print(
  //           "Logged-in Firebase User: ${FirebaseAuth.instance.currentUser?.email}");

  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(
  //           content:
  //               Text("Login successful", style: TextStyle(color: Colors.white)),
  //           backgroundColor: const Color.fromARGB(255, 54, 155, 58),
  //           duration: Duration(seconds: 2),
  //         ),
  //       );

  //       await Future.delayed(Duration(seconds: 2));

  //       if (userType == 'animal_owner' || userType == 'veterinarian') {
  //         Navigator.pushReplacement(
  //           context,
  //           MaterialPageRoute(
  //             builder: (context) => BottomNavigations(userType: userType),
  //           ),
  //         );
  //       }
  //     } catch (firebaseError) {
  //       print("Firebase Authentication Error: $firebaseError");
  //     }
  //   } else {
  //     print("MySQL login failed: ${data['message']}");
  //   }

  //   setState(() {
  //     _isLoading = false;
  //   });
  // }

  Future<void> _login() async {
  setState(() {
    _isEmailValid = _emailController1.text.isNotEmpty &&
        RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
            .hasMatch(_emailController1.text);
    _isPasswordValid = _passwordController1.text.isNotEmpty;
  });

  if (!_isEmailValid || !_isPasswordValid) {
    return;
  }

  setState(() {
    _isLoading = true;
  });

  final response = await http.post(
    Uri.parse('http://192.168.107.58:5000/login'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'email': _emailController1.text,
      'password': _passwordController1.text,
    }),
  );

  final data = jsonDecode(response.body);

  if (response.statusCode == 200) {
    String userType = data['user_type'];
    String token = data['access_token'];

    await fetchUserId(_emailController1.text);

    if (loggedInUserId == null) {
      print("Fetch user ID failed! Cannot proceed.");
      return;
    }

    try {
      // Firebase authentication
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController1.text,
        password: _passwordController1.text,
      );

      print("Logged-in Firebase User: ${FirebaseAuth.instance.currentUser?.email}");

      // Store JWT token and user details
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('userType', userType);
      await prefs.setInt('userId', data['user_id']);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login successful", style: TextStyle(color: Colors.white)),
          backgroundColor: const Color.fromARGB(255, 54, 155, 58),
          duration: Duration(seconds: 2),
        ),
      );

      await Future.delayed(Duration(seconds: 2));

      if (userType == 'animal_owner' || userType == 'veterinarian') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigations(userType: userType),
          ),
        );
      }
    } catch (firebaseError) {
      print("Firebase Authentication Error: $firebaseError");
    }
  } else {
    print("MySQL login failed: ${data['message']}");
  }

  setState(() {
    _isLoading = false;
  });
}

  Future<void> fetchUserId(String email) async {
    print("Fetching user ID for: $email");

    final response = await http.get(
      Uri.parse('http://192.168.107.58:5000/get_user?email=$email'),
    );

    print("Response from get_user: ${response.body}");

    if (response.statusCode == 200) {
      final userData = jsonDecode(response.body);

      if (userData.containsKey("id")) {
        setState(() {
          loggedInUserId = userData["id"];
          loggedInUserType = userData["user_type"];
        });
        print("User ID: $loggedInUserId, User Type: $loggedInUserType");
      } else {
        print("User ID missing in response");
      }
    } else {
      print("Error fetching user ID: ${response.body}");
    }
  }

  @override
  void dispose() {
    _emailController1.dispose();
    _passwordController1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20.0, vertical: 40.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20.0),
                        child: Image.asset(
                          'assets/logo.png',
                          height: 150,
                        ),
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Welcome Back!!',
                        style: TextStyle(
                          fontSize: 26,
                          color: context.theme.titletext,
                        ),
                      ),
                      SizedBox(height: 20),

                      // Email Input
                      _buildEmailField(_emailController1, 'Email'),
                      SizedBox(height: 15),

                      // Password Input
                      _buildPasswordField(
                        _passwordController1,
                        'Password',
                        _obscurePassword1,
                        (value) {
                          setState(() {
                            _obscurePassword1 = value;
                          });
                        },
                      ),

                      SizedBox(height: 10),

                      // Forgot Password
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => ForgotPasswordPage()),
                              );
                            },
                            child: Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: context.theme.primecolor,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 20),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        child: Opacity(
                          opacity: _isLoading ? 0.3 : 1.0,
                          child: ElevatedButton(
                            onPressed: _isLoading ? () {} : _login,
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
                                    'Login',
                                    style: TextStyle(
                                        fontSize: 17, color: Colors.white),
                                  ),
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
                              color: context.theme.subtitletext,
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 10.0),
                            child: Text(
                              "Or continue with",
                              style: TextStyle(
                                color: context.theme.subtitletext,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              thickness: 1,
                              color: context.theme.subtitletext,
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 20),

                      // Continue with Google Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {},
                          icon: Image.asset(
                            'assets/google_icon.png',
                            height: 36,
                          ),
                          label: Text(
                            'Sign in with Google',
                            style: TextStyle(
                              fontSize: 17,
                              color: context.theme.titletext,
                            ),
                          ),
                          style: ButtonStyle(
                            backgroundColor:
                                MaterialStateProperty.all(Colors.transparent),
                            overlayColor: MaterialStateProperty.all(
                                Color.fromARGB(255, 10, 54, 61)),
                            elevation: MaterialStateProperty.all(0),
                            side: MaterialStateProperty.all(BorderSide(
                              color: context.theme.subtitletext,
                            )),
                            padding: MaterialStateProperty.all(
                                EdgeInsets.symmetric(vertical: 8)),
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

              // Sign Up
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 17,
                        color: context.theme.titletext,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const UserSelectionPage()),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          color: context.theme.primecolor,
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
      ),
    );
  }

  Widget _buildEmailField(TextEditingController controller, String label) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.theme.subtitletext,
          fontSize: 18,
        ),
        prefixIcon: Icon(
          Icons.email,
          color: context.theme.primecolor,
        ),
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
              width: 2.0),
        ),
        errorText: _isEmailValid ? null : 'Enter a valid email',
      ),
      keyboardType: TextInputType.emailAddress,
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
      cursorHeight: 20,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: context.theme.subtitletext,
          fontSize: 18,
        ),
        prefixIcon: Icon(
          Icons.lock,
          color: context.theme.primecolor,
        ),
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
        errorText: _isPasswordValid ? null : 'Password cannot be empty',
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: context.theme.subtitletext,
          ),
          onPressed: () {
            onToggleVisibility(!obscureText);
          },
        ),
      ),
    );
  }
}
