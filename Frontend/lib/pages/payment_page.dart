import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class PaymentScreen extends StatefulWidget {
  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String selectedPaymentOption = 'Unlimited Chat';
  TextEditingController phoneNumberController = TextEditingController();

  // Define the prices for each option in Ksh
  final Map<String, double> paymentOptionPrices = {
    'Unlimited Chat': 5000.0, // Ksh 5000
    'Monthly Subscription': 1000.0, // Ksh 1000
    'Specific Number of Chats (50)': 1500.0, // Ksh 1500 for 50 messages
    'Specific Number of Chats (20)': 800.0, // Ksh 800 for 20 messages
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Make Payment", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).primaryColor, // Use app primary color
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Select Payment Option",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            Column(
              children: paymentOptionPrices.keys.map((option) {
                return RadioListTile<String>(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(option, style: TextStyle(fontSize: 16)),
                      Text(
                        'Ksh ${paymentOptionPrices[option]}', // Display the price in Ksh
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                      ),
                    ],
                  ),
                  value: option,
                  groupValue: selectedPaymentOption,
                  onChanged: (value) {
                    setState(() {
                      selectedPaymentOption = value!;
                    });
                  },
                );
              }).toList(),
            ),
            SizedBox(height: 20),
            TextField(
              controller: phoneNumberController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Enter Phone Number',
                labelStyle: TextStyle(color: Colors.grey),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Theme.of(context).primaryColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
                prefixIcon: Icon(Icons.phone, color: Theme.of(context).primaryColor),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (phoneNumberController.text.isNotEmpty) {
                  // Proceed with the payment processing
                  Navigator.of(context).pop(); // Go back to ChatScreen
                  _processMpesaPayment(phoneNumberController.text);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Please enter a phone number')));
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor, // App primary color
                padding: EdgeInsets.symmetric(vertical: 14, horizontal: 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                "Proceed to Pay",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processMpesaPayment(String phoneNumber) async {
    final response = await http.post(
      Uri.parse('http://192.168.107.58:5000/mpesa/payment'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        "amount": paymentOptionPrices[selectedPaymentOption]!, // Get the amount based on selected option
        "phone_number": phoneNumber, // User phone number for payment
      }),
    );

    if (response.statusCode == 200) {
      final paymentResponse = json.decode(response.body);
      print('Payment Response: $paymentResponse');
      // Process the response here (e.g., show payment status)
    } else {
      print('Payment initiation failed');
    }
  }
}
