import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';
import '../models/review.dart';
import '../models/help_desk_post.dart';
import '../models/notification.dart';

class ApiService {
  // Replace with your actual Flask backend URL
  static const String baseUrl = 'http://192.168.107.58:5000/api';
  
  // Authentication token storage
  static Future<String?> getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('auth_token');
  }
  
  static Future<void> setAuthToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }
  
  static Future<void> clearAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }
  
  // Helper method for authenticated requests
  static Future<http.Response> _authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    final token = await getAuthToken();
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    
    var uri = Uri.parse('$baseUrl$endpoint');
    if (queryParams != null) {
      uri = uri.replace(queryParameters: queryParams);
    }
    
    http.Response response;
    
    switch (method) {
      case 'GET':
        response = await http.get(uri, headers: headers);
        break;
      case 'POST':
        response = await http.post(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'PUT':
        response = await http.put(
          uri,
          headers: headers,
          body: body != null ? json.encode(body) : null,
        );
        break;
      case 'DELETE':
        response = await http.delete(uri, headers: headers);
        break;
      default:
        throw Exception('Unsupported HTTP method: $method');
    }
    
    return response;
  }
  
  // Add this public method that can be used by other classes
  static Future<http.Response> authenticatedRequest({
    required String method,
    required String endpoint,
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
  }) async {
    return _authenticatedRequest(
      method: method,
      endpoint: endpoint,
      body: body,
      queryParams: queryParams,
    );
  }
  
  // Authentication methods
  static Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
      }),
    );
    
    final data = json.decode(response.body);
    
    if (response.statusCode == 200) {
      if (data.containsKey('token')) {
        await setAuthToken(data['token']);
      }
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Login failed'};
    }
  }
  
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(userData),
    );
    
    final data = json.decode(response.body);
    
    if (response.statusCode == 201) {
      return {'success': true, 'data': data};
    } else {
      return {'success': false, 'message': data['message'] ?? 'Registration failed'};
    }
  }
  
  static Future<bool> logout() async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/auth/logout',
      );
      
      await clearAuthToken();
      return response.statusCode == 200;
    } catch (e) {
      await clearAuthToken();
      return false;
    }
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/users/me',
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get user data'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  // Chat methods
  static Future<List<Message>> getMessages(String chatId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/chats/$chatId/messages',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> messagesJson = json.decode(response.body);
        return messagesJson.map((json) => Message.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load messages');
      }
    } catch (e) {
      print('Error getting messages: $e');
      return [];
    }
  }
  
  static Future<bool> sendMessage(String chatId, String content) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/chats/$chatId/messages',
        body: {
          'content': content,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error sending message: $e');
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getChatRooms() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/chats',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> chatsJson = json.decode(response.body);
        return chatsJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load chat rooms');
      }
    } catch (e) {
      print('Error getting chat rooms: $e');
      return [];
    }
  }
  
  static Future<bool> markMessagesAsRead(String chatId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'PUT',
        endpoint: '/chats/$chatId/read',
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking messages as read: $e');
      return false;
    }
  }
  
  static Future<int> getMessageCount(String chatId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/chats/$chatId/count',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['count'] ?? 0;
      } else {
        return 0;
      }
    } catch (e) {
      print('Error getting message count: $e');
      return 0;
    }
  }
  
  // Reviews methods
  static Future<List<Review>> getReviews(String vetId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/vets/$vetId/reviews',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> reviewsJson = json.decode(response.body);
        return reviewsJson.map((json) => Review.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load reviews');
      }
    } catch (e) {
      print('Error getting reviews: $e');
      return [];
    }
  }
  
  static Future<bool> addReview({
    required String vetId,
    required String reviewText,
    required double rating,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/vets/$vetId/reviews',
        body: {
          'reviewText': reviewText,
          'rating': rating,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding review: $e');
      return false;
    }
  }
  
  static Future<bool> addReplyToReview({
    required String vetId,
    required String reviewId,
    required String replyText,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/vets/$vetId/reviews/$reviewId/replies',
        body: {
          'replyText': replyText,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding reply: $e');
      return false;
    }
  }
  
  // Help desk methods
  static Future<List<HelpDeskPost>> getHelpDeskPosts() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/helpdesk',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> postsJson = json.decode(response.body);
        return postsJson.map((json) => HelpDeskPost.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load help desk posts');
      }
    } catch (e) {
      print('Error getting help desk posts: $e');
      return [];
    }
  }
  
  static Future<bool> addHelpDeskPost({
    required String title,
    required String content,
    required String animalType,
    String? imageUrl,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/helpdesk',
        body: {
          'title': title,
          'content': content,
          'animalType': animalType,
          if (imageUrl != null) 'imageUrl': imageUrl,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding help desk post: $e');
      return false;
    }
  }
  
  static Future<bool> addCommentToHelpDesk({
    required String postId,
    required String comment,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/helpdesk/$postId/comments',
        body: {
          'comment': comment,
        },
      );
      
      return response.statusCode == 201;
    } catch (e) {
      print('Error adding comment: $e');
      return false;
    }
  }
  
  // Notifications
  static Future<List<AppNotification>> getNotifications() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/notifications',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> notificationsJson = json.decode(response.body);
        return notificationsJson.map((json) => AppNotification.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load notifications');
      }
    } catch (e) {
      print('Error getting notifications: $e');
      return [];
    }
  }
  
  static Future<bool> markNotificationAsRead(String notificationId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'PUT',
        endpoint: '/notifications/$notificationId/read',
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error marking notification as read: $e');
      return false;
    }
  }
  
  // Clinic location methods
  static Future<bool> updateClinicLocation({
    required String vetId,
    required double latitude,
    required double longitude,
    required String clinicName,
    required String address,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'PUT',
        endpoint: '/vets/$vetId/clinic',
        body: {
          'name': clinicName,
          'address': address,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      
      return response.statusCode == 200;
    } catch (e) {
      print('Error updating clinic location: $e');
      return false;
    }
  }
  
  static Future<List<Map<String, dynamic>>> getNearbyVetClinics() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/vets/clinics',
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> clinicsJson = json.decode(response.body);
        return clinicsJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to load vet clinics');
      }
    } catch (e) {
      print('Error getting vet clinics: $e');
      return [];
    }
  }
  
  // Payment methods
  static Future<Map<String, dynamic>> initiatePayment({
    required String phoneNumber,
    required double amount,
    required String description,
  }) async {
    try {
      final response = await _authenticatedRequest(
        method: 'POST',
        endpoint: '/payments/mpesa',
        body: {
          'phoneNumber': phoneNumber,
          'amount': amount,
          'description': description,
        },
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        final data = json.decode(response.body);
        return {'success': false, 'message': data['message'] ?? 'Payment failed'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<Map<String, dynamic>> payForConsultation({
    required String phoneNumber,
    required String vetId,
  }) async {
    return await initiatePayment(
      phoneNumber: phoneNumber,
      amount: 100.0, // KES
      description: 'One-time consultation with vet',
    );
  }
  
  static Future<Map<String, dynamic>> payForMonthlySubscription({
    required String phoneNumber,
  }) async {
    return await initiatePayment(
      phoneNumber: phoneNumber,
      amount: 500.0, // KES
      description: 'Monthly subscription for VetConnect',
    );
  }
  
  // Report generation
  static Future<String?> generateUserReport() async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/reports/user',
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['reportUrl'];
      } else {
        return null;
      }
    } catch (e) {
      print('Error generating report: $e');
      return null;
    }
  }
  
  // Vet profile methods
  static Future<Map<String, dynamic>> getVetProfile(String vetId) async {
    try {
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/vets/$vetId',
      );
      
      if (response.statusCode == 200) {
        return {'success': true, 'data': json.decode(response.body)};
      } else {
        return {'success': false, 'message': 'Failed to get vet profile'};
      }
    } catch (e) {
      return {'success': false, 'message': 'Error: $e'};
    }
  }
  
  static Future<List<Map<String, dynamic>>> searchVets({
    String? query,
    String? specialization,
    double? latitude,
    double? longitude,
    double? maxDistance,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null) queryParams['query'] = query;
      if (specialization != null) queryParams['specialization'] = specialization;
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (maxDistance != null) queryParams['maxDistance'] = maxDistance.toString();
      
      final response = await _authenticatedRequest(
        method: 'GET',
        endpoint: '/vets/search',
        queryParams: queryParams,
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> vetsJson = json.decode(response.body);
        return vetsJson.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to search vets');
      }
    } catch (e) {
      print('Error searching vets: $e');
      return [];
    }
  }
}
