import 'package:flutter/material.dart';
import 'package:vetconnect/components/colors.dart';

class VeterinarianRegisterPage extends StatefulWidget {
  @override
  _VeterinarianRegisterPageState createState() =>
      _VeterinarianRegisterPageState();
}

class _VeterinarianRegisterPageState extends State<VeterinarianRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _licenseController = TextEditingController();

  String? _specialization;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 40.0),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20.0),
                child: Image.asset(
                  'assets/logo.png',
                  height: 150,
                ),
              ),
              Text('Veterinarian Registration', style: TextStyle(fontSize: 26)),
              SizedBox(height: 20),

              // Name Input
              _buildTextField(_nameController, 'Full Name', Icons.person),
              SizedBox(height: 15),

              // Email Input
              _buildTextField(_emailController, 'Email', Icons.email,
                  TextInputType.emailAddress),
              SizedBox(height: 15),

              // License Number Input
              _buildTextField(
                  _licenseController, 'License Number', Icons.card_membership),
              SizedBox(height: 15),

              // Specialization Dropdown
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(color: CustomColors.appblue),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    hint: Container(
                      padding: const EdgeInsets.only(left: 14.0),
                      child: Text(
                        _specialization ?? 'Select specialization',
                        style: TextStyle(
                            color: _specialization == null
                                ? CustomColors.greycolor
                                : Colors.black),
                      ),
                    ),
                    value: _specialization,
                    items: <String>[
                      'Small Animal Medicine',
                      'Large Animal Medicine',
                      'Equine Medicine',
                      'Exotic Animal Medicine',
                      'Veterinary Surgery',
                      'Veterinary Dentistry',
                      'Reproduction and Theriogenology'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 12.0, horizontal: 16.0),
                          child: Text(value),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _specialization = value;
                      });
                    },
                    isExpanded: true,
                    icon: Padding(
                      padding: const EdgeInsets.only(right: 16.0),
                      child: Icon(Icons.arrow_drop_down,
                          color: CustomColors.greycolor),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 20),

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
              SizedBox(height: 15),

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
              SizedBox(height: 20),

              // Register Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    // Implement registration logic
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.appblue,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Text('Register',
                      style: TextStyle(fontSize: 17, color: Colors.white)),
                ),
              ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      [TextInputType? keyboardType]) {
    return TextField(
      controller: controller,
      style: TextStyle(fontSize: 18),
      cursorColor: CustomColors.appblue,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(icon, color: CustomColors.greycolor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: CustomColors.appblue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: CustomColors.appblue, width: 2.0),
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
      cursorColor: CustomColors.appblue,
      obscureText: obscureText,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon: Icon(Icons.lock, color: CustomColors.greycolor),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: CustomColors.appblue),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: CustomColors.appblue, width: 2.0),
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off : Icons.visibility,
            color: CustomColors.greycolor,
          ),
          onPressed: () {
            onToggleVisibility(!obscureText);
          },
        ),
      ),
    );
  }
}
