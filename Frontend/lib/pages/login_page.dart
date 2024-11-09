import 'package:flutter/material.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController1 = TextEditingController();
  final TextEditingController _passwordController1 = TextEditingController();

  bool _obscurePassword1 = true;

  @override
  void dispose() {
    _emailController1.dispose();
    _passwordController1.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                        GestureDetector(
                          onTap: () {},
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
                            color: context.theme.subtitletext,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0),
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
                          style: TextStyle(fontSize: 17, color: context.theme.titletext,),
                        ),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.transparent),
                          overlayColor: MaterialStateProperty.all(
                              Color.fromARGB(255, 10, 54, 61)),
                          elevation: MaterialStateProperty.all(0),
                          side: MaterialStateProperty.all(
                              BorderSide(color: context.theme.subtitletext,)),
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
                  GestureDetector(
                    onTap: () {},
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
        prefixIcon: Icon(Icons.email, color: context.theme.primecolor,),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor,),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor, width: 2.0),
        ),
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
        prefixIcon: Icon(Icons.lock, color: context.theme.primecolor,),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor,),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor, width: 2.0),
        ),
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
