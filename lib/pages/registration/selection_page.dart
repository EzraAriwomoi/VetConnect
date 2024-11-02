import 'package:flutter/material.dart';
import 'package:vetconnect/components/Header/page_header.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

import 'signup/animal_owner/animal_owner_register.dart';
import 'signup/veterinarian/veterinarian_register.dart';

class UserSelectionPage extends StatefulWidget {
  const UserSelectionPage({super.key});

  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  String _selectedUserType = '';

  void _proceed() {
    if (_selectedUserType == 'veterinarian') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const VeterinarianRegisterPage(),
        ),
      );
    } else if (_selectedUserType == 'Owner') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AnimalOwnerRegisterPage(),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.warning,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Please select an account type to proceed.',
                  style: TextStyle(
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: const Color.fromARGB(255, 250, 109, 99),
          behavior: SnackBarBehavior.floating,
          margin: EdgeInsets.only(bottom: 80.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                PageHeader(
                  title: 'Welcome to VetConnect',
                  subtitle: 'Select the type of account to create...',
                ),
                SizedBox(height: 10),
                Text(
                  'Follow each STEP to get started with your account.',
                  style: TextStyle(
                    color: context.theme.subtitletext,
                  ),
                ),
                Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Column(
                    children: [
                      // Veterinarian Option
                      _buildUserOption(
                        label: "Veterinarian",
                        description: 'For veterinary professionals',
                        value: 'veterinarian',
                      ),
                      SizedBox(height: 20),
                      // Animal Owner Option
                      _buildUserOption(
                        label: "Animal Owner",
                        description: 'For pet and livestock owners',
                        value: 'Owner',
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 45),
                // Proceed Button
                Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _proceed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.theme.primecolor,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        'Proceed',
                        style: TextStyle(fontSize: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 10,
              left: 10,
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserOption({
    required String label,
    required String description,
    required String value,
  }) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: _selectedUserType == value
            ? context.theme.primecolor.withOpacity(0.1)
            : Colors.transparent,
        border: Border.all(color: context.theme.primecolor),
        borderRadius: BorderRadius.circular(10),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedUserType = value;
          });
        },
        splashColor: context.theme.primecolor.withOpacity(0.3),
        borderRadius: BorderRadius.circular(10),
        child: Center(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Padding(
              padding: const EdgeInsets.only(left: 10.0),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  color: context.theme.titletext,
                ),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              child: Text(
                description,
                style: TextStyle(
                  color: context.theme.subtitletext,
                  fontSize: 14,
                ),
              ),
            ),
            leading: Transform.scale(
              scale: 1.2,
              child: Radio(
                value: value,
                groupValue: _selectedUserType,
                onChanged: (val) {
                  setState(() {
                    _selectedUserType = val.toString();
                  });
                },
                activeColor: context.theme.primecolor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
