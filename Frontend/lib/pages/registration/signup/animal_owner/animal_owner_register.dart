// import 'package:flutter/material.dart';
// import 'package:vetconnect/components/extension/custom_theme.dart';
// import 'package:vetconnect/components/header/page_header.dart';

// import './password_file_owner.dart';

// class AnimalOwnerRegisterPage extends StatefulWidget {
//   const AnimalOwnerRegisterPage({super.key});

//   @override
//   _AnimalOwnerRegisterPageState createState() =>
//       _AnimalOwnerRegisterPageState();
// }

// class _AnimalOwnerRegisterPageState extends State<AnimalOwnerRegisterPage> {
//   final TextEditingController _nameController = TextEditingController();
//   final TextEditingController _emailController = TextEditingController();
//   final TextEditingController _phoneController = TextEditingController();
//   final TextEditingController _locationController = TextEditingController();
//   final TextEditingController _animalTypeController = TextEditingController();

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         backgroundColor: context.theme.curvedpartcolor,
//         elevation: 0,
//         leading: IconButton(
//           icon: Icon(Icons.arrow_back, color: Colors.white),
//           onPressed: () {
//             Navigator.pop(context);
//           },
//         ),
//         actions: [
//           IconButton(
//             icon: Icon(Icons.more_vert, color: Colors.white),
//             onPressed: () {},
//           ),
//         ],
//       ),
//       body: SafeArea(
//         child: Transform.translate(
//           offset: Offset(0, -50),
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
//             child: Column(
//               children: [
//                 PageHeader(
//                   title: 'Animal Owner Registration',
//                   subtitle: '',
//                 ),

//                 // Name Input
//                 _buildTextField(
//                   controller: _nameController,
//                   label: 'Full Name',
//                 ),

//                 // Email Input
//                 _buildTextField(
//                   controller: _emailController,
//                   label: 'Email',
//                   keyboardType: TextInputType.emailAddress,
//                 ),

//                 // Phone Number Input
//                 _buildTextField(
//                   controller: _phoneController,
//                   label: 'Phone Number (e.g. 254...)',
//                   keyboardType: TextInputType.phone,
//                 ),

//                 // Location Input
//                 _buildTextField(
//                   controller: _locationController,
//                   label: 'Location (County, Town)',
//                 ),

//                 // Animal type Input
//                 _buildTextField(
//                   controller: _animalTypeController,
//                   label: 'Animal Type (e.g., Cattle, Dog)',
//                 ),

//                 SizedBox(height: 30),

//                 // Register Button
//                 SizedBox(
//                   width: double.infinity,
//                   child: ElevatedButton(
//                     onPressed: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => PasswordFileOwnerPage()),
//                       );
//                     },
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: context.theme.primecolor,
//                       padding: EdgeInsets.symmetric(vertical: 16),
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12.0),
//                       ),
//                     ),
//                     child: Text(
//                       'Continue',
//                       style: TextStyle(fontSize: 17, color: Colors.white),
//                     ),
//                   ),
//                 ),
//                 SizedBox(height: 20),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _buildTextField({
//     required TextEditingController controller,
//     required String label,
//     TextInputType keyboardType = TextInputType.text,
//   }) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         TextField(
//           controller: controller,
//           style: TextStyle(fontSize: 18),
//           cursorColor: context.theme.primecolor,
//           cursorHeight: 18,
//           keyboardType: keyboardType,
//           decoration: InputDecoration(
//             labelText: label,
//             labelStyle: TextStyle(
//               fontSize: 17,
//               color: context.theme.subtitletext,
//             ),
//             floatingLabelBehavior: FloatingLabelBehavior.auto,
//             enabledBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10.0),
//               borderSide: BorderSide(
//                 color: context.theme.primecolor,
//               ),
//             ),
//             focusedBorder: OutlineInputBorder(
//               borderRadius: BorderRadius.circular(10.0),
//               borderSide:
//                   BorderSide(color: context.theme.primecolor, width: 2.0),
//             ),
//           ),
//         ),
//         SizedBox(height: 15),
//       ],
//     );
//   }
// }
