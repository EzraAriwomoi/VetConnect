import 'package:flutter/material.dart';
import 'package:vetconnect/components/Header/page_header.dart';
import 'package:vetconnect/components/extension/custom_theme.dart';

import 'signup/animal_owner_register.dart';
import 'signup/veterinarian_register.dart';

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select an account type to proceed.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
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
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'veterinarian'
                          ? context.theme.primecolor.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(color: context.theme.primecolor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUserType = 'veterinarian';
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
                              "Veterinarian",
                              style: TextStyle(
                                fontSize: 18,
                                color: context.theme.titletext,
                              ),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'For veterinary professionals',
                              style: TextStyle(
                                color: context.theme.subtitletext,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.2,
                            child: Radio(
                              value: 'veterinarian',
                              groupValue: _selectedUserType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserType = value.toString();
                                });
                              },
                              activeColor: context.theme.primecolor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  SizedBox(height: 20),

                  // Animal Owner Option
                  Container(
                    height: 80,
                    decoration: BoxDecoration(
                      color: _selectedUserType == 'Owner'
                          ? context.theme.primecolor.withOpacity(0.1)
                          : Colors.transparent,
                      border: Border.all(color: context.theme.primecolor),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUserType = 'Owner';
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
                              "Animal Owner",
                              style: TextStyle(
                                fontSize: 18,
                                color: context.theme.titletext,
                              ),
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              'For pet and livestock owners',
                              style: TextStyle(
                                color: context.theme.subtitletext,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.2,
                            child: Radio(
                              value: 'Owner',
                              groupValue: _selectedUserType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserType = value.toString();
                                });
                              },
                              activeColor: context.theme.primecolor,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 20),

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
      ),
    );
  }
}
