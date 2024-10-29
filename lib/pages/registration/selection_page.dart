import 'package:flutter/material.dart';
import 'package:vetconnect/components/colors.dart';

import 'signup/animal_owner_register.dart';
import 'signup/veterinarian_register.dart';

class UserSelectionPage extends StatefulWidget {
  @override
  _UserSelectionPageState createState() => _UserSelectionPageState();
}

class _UserSelectionPageState extends State<UserSelectionPage> {
  String _selectedUserType = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Top Content (Logo and Details)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20.0),
                  child: Image.asset(
                    'assets/logo.png',
                    height: 150,
                  ),
                ),
                Text(
                  'Welcome to VetConnect',
                  style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Text(
                  'Connecting you to veterinary services',
                  style: TextStyle(fontSize: 16, color: CustomColors.greycolor),
                ),
              ],
            ),

            // Wide Spacer
            Spacer(),

            // User Selection Box with InkWell for full height effect
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                children: [
                  // Veterinarians Option
                  Container(
                    height: 80, // Set container height
                    decoration: BoxDecoration(
                      border: Border.all(color: CustomColors.appblue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUserType = 'veterinarian';
                        });
                      },
                      splashColor: CustomColors.appblue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Veterinarian",
                              style:
                                  TextStyle(fontSize: 18), // Larger font size
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.2, // Increase radio button size
                            child: Radio(
                              value: 'veterinarian',
                              groupValue: _selectedUserType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserType = value.toString();
                                });
                              },
                              activeColor: CustomColors.appblue,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20),

                  // Animal Owner Option
                  Container(
                    height: 80, // Set container height
                    decoration: BoxDecoration(
                      border: Border.all(color: CustomColors.appblue),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _selectedUserType = 'Owner';
                        });
                      },
                      splashColor: CustomColors.appblue.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(10),
                      child: Center(
                        child: ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Padding(
                            padding: const EdgeInsets.only(left: 10.0),
                            child: Text(
                              "Animal Owner",
                              style:
                                  TextStyle(fontSize: 18), // Larger font size
                            ),
                          ),
                          leading: Transform.scale(
                            scale: 1.2, // Increase radio button size
                            child: Radio(
                              value: 'Owner',
                              groupValue: _selectedUserType,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUserType = value.toString();
                                });
                              },
                              activeColor: CustomColors.appblue,
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
                  onPressed: () {
                    if (_selectedUserType == 'veterinarian') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => VeterinarianRegisterPage()),
                      );
                    } else if (_selectedUserType == 'Owner') {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnimalOwnerRegisterPage()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CustomColors.appblue,
                    padding: EdgeInsets.symmetric(vertical: 15),
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
