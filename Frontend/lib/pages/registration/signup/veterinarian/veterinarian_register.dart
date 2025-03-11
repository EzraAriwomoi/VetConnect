import 'package:flutter/material.dart';
import 'package:vetconnect/components/Header/page_header.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';
import './create_password.dart';

class VeterinarianRegisterPage extends StatefulWidget {
  const VeterinarianRegisterPage({super.key});

  @override
  _VeterinarianRegisterPageState createState() =>
      _VeterinarianRegisterPageState();
}

class _VeterinarianRegisterPageState extends State<VeterinarianRegisterPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _licenseController = TextEditingController();
  final TextEditingController _nationalID = TextEditingController();
  final TextEditingController _clinic = TextEditingController();
  String? _specialization;

  final _formKey = GlobalKey<FormState>();

  Future<void> navigateToCreatePassword() async {
    if (_formKey.currentState!.validate()) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => CreatePassword(
            name: _nameController.text,
            email: _emailController.text,
            licenseNumber: _licenseController.text,
            nationalID: _nationalID.text,
            clinic: _clinic.text,
            specialization: _specialization,
          ),
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
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                PageHeader(
                  title: 'Veterinarian Registration',
                  subtitle: '',
                ),
                _buildTextField(_nameController, 'Full Name', required: true),
                SizedBox(height: 10),
                _buildTextField(_emailController, 'Email',
                    keyboardType: TextInputType.emailAddress, email: true),
                SizedBox(height: 10),
                _buildTextField(_nationalID, 'National ID',
                    keyboardType: TextInputType.number, nationalID: true),
                SizedBox(height: 10),
                _buildTextField(_clinic, 'Clinic', required: true),
                SizedBox(height: 10),
                _buildTextField(
                    _licenseController, 'License Number (e.g., KVB)',
                    required: true),
                SizedBox(height: 10),
                _buildSpecializationDropdown(),
                SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: navigateToCreatePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.theme.primecolor,
                      padding: EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text('Continue',
                        style: TextStyle(fontSize: 17, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {TextInputType? keyboardType,
      bool required = false,
      bool email = false,
      bool nationalID = false}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(fontSize: 18),
      cursorColor: context.theme.primecolor,
      cursorHeight: 18,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 17, color: context.theme.subtitletext),
        floatingLabelBehavior: FloatingLabelBehavior.auto,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.0),
          borderSide: BorderSide(color: context.theme.primecolor, width: 2.0),
        ),
      ),
      validator: (value) {
        if (required && (value == null || value.isEmpty)) {
          return 'This field is required';
        }
        if (email &&
            value != null &&
            !RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$")
                .hasMatch(value)) {
          return 'Enter a valid email';
        }
        if (nationalID &&
            value != null &&
            (value.length != 8 || !RegExp(r'^\d{8}$').hasMatch(value))) {
          return 'National ID must be exactly 8 digits';
        }
        return null;
      },
    );
  }

  Widget _buildSpecializationDropdown() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(color: context.theme.primecolor),
      ),
      child: DropdownButtonFormField<String>(
        value: _specialization, // This ensures the selected value is displayed
        hint: Padding(
          padding: const EdgeInsets.only(left: 14.0),
          child: Text(
            'Select Specialization',
            style: TextStyle(fontSize: 17, color: context.theme.subtitletext),
          ),
        ),
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
            child: Text(value, style: TextStyle(fontSize: 17)),
          );
        }).toList(),
        onChanged: (value) {
          setState(() {
            _specialization = value;
          });
        },
        validator: (value) {
          if (value == null) {
            return 'Please select a specialization';
          }
          return null;
        },
        isExpanded: true,
        decoration: InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          border: InputBorder.none,
        ),
        icon: Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Icon(Icons.arrow_drop_down, color: context.theme.subtitletext),
        ),
      ),
    );
  }
}
