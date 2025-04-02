import 'dart:convert';
import 'api_service.dart';

class MpesaService {
  // Initiate payment through Flask backend
  static Future<Map<String, dynamic>> initiateSTKPush({
    required String phoneNumber,
    required double amount,
    required String description,
  }) async {
    try {
      return await ApiService.initiatePayment(
        phoneNumber: phoneNumber,
        amount: amount,
        description: description,
      );
    } catch (e) {
      return {'success': false, 'message': 'Exception: $e'};
    }
  }
  
  // Handle one-time consultation payment
  static Future<Map<String, dynamic>> payForConsultation({
    required String phoneNumber,
    required String vetId,
  }) async {
    
    return await ApiService.payForConsultation(
      phoneNumber: phoneNumber,
      vetId: vetId,
    );
  }
  
  // Handle monthly subscription payment
  static Future<Map<String, dynamic>> payForMonthlySubscription({
    required String phoneNumber,
  }) async {
    
    return await ApiService.payForMonthlySubscription(
      phoneNumber: phoneNumber,
    );
  }
  
  // Check payment status
  static Future<Map<String, dynamic>> checkPaymentStatus(String transactionId) async {
    try {
      final response = await ApiService.authenticatedRequest(
        method: 'GET',
        endpoint: '/payments/status/$transactionId',
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Failed to check payment status'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
}
