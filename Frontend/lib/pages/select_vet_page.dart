import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class SelectVeterinarianScreen extends StatefulWidget {
  @override
  _SelectVeterinarianScreenState createState() =>
      _SelectVeterinarianScreenState();
}

class _SelectVeterinarianScreenState extends State<SelectVeterinarianScreen> {
  List<dynamic> veterinarians = [];
  List<dynamic> filteredVeterinarians = [];
  bool isLoading = true;
  bool hasError = false;
  String searchQuery = '';
  
  // Mock online status - in a real app, this would come from a backend service
  final Map<String, bool> onlineStatus = {};

  @override
  void initState() {
    super.initState();
    fetchVeterinarians();
  }

  Future<void> fetchVeterinarians() async {
    final url = Uri.parse('http://192.168.107.58:5000/get_veterinarians');

    try {
      setState(() {
        isLoading = true;
        hasError = false;
      });
      
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        
        // Generate random online status for demo purposes
        for (var vet in data) {
          onlineStatus[vet['email']] = DateTime.now().millisecondsSinceEpoch % 2 == 0;
        }
        
        setState(() {
          veterinarians = data;
          filteredVeterinarians = data;
          isLoading = false;
          hasError = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
      print("Error fetching veterinarians: $e");
    }
  }
  
  void filterVeterinarians(String query) {
    setState(() {
      searchQuery = query;
      if (query.isEmpty) {
        filteredVeterinarians = veterinarians;
      } else {
        filteredVeterinarians = veterinarians.where((vet) {
          final name = vet['name']?.toString().toLowerCase() ?? '';
          final clinic = vet['clinic']?.toString().toLowerCase() ?? '';
          final specialty = vet['specialty']?.toString().toLowerCase() ?? '';
          
          return name.contains(query.toLowerCase()) || 
                 clinic.contains(query.toLowerCase()) ||
                 specialty.contains(query.toLowerCase());
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chat with a Veterinarian',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 3,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: fetchVeterinarians,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search veterinarians...',
                prefixIcon: Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear),
                        onPressed: () {
                          filterVeterinarians('');
                          FocusScope.of(context).unfocus();
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.grey[300]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.lightBlue),
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 12),
              ),
              onChanged: filterVeterinarians,
            ),
          ),
          
          // Status indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                Text(
                  '${filteredVeterinarians.length} veterinarians available',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                        ),
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Online',
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Main content
          Expanded(
            child: isLoading
                ? Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.lightBlue),
                    ),
                  )
                : hasError
                    ? _buildErrorView()
                    : filteredVeterinarians.isEmpty
                        ? _buildEmptyView()
                        : _buildVeterinariansList(),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            color: const Color.fromARGB(255, 250, 109, 99),
            size: 70,
          ),
          SizedBox(height: 16),
          Text(
            "Oops! Couldn't load veterinarians.",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Please check your connection and try again.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: fetchVeterinarians,
            icon: Icon(Icons.refresh),
            label: Text("Retry"),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            color: Colors.grey[400],
            size: 70,
          ),
          SizedBox(height: 16),
          Text(
            "No veterinarians found",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? "There are no veterinarians available at the moment."
                : "Try adjusting your search criteria.",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildVeterinariansList() {
    return ListView.builder(
      itemCount: filteredVeterinarians.length,
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemBuilder: (context, index) {
        final vet = filteredVeterinarians[index];
        final isOnline = onlineStatus[vet['email']] ?? false;
        
        return Card(
          elevation: 2,
          margin: EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || currentUser.email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please sign in to start chatting'))
    );
    return;
  }

  Navigator.pop(context, {
    'vetEmail': vet['email'], // Pass the vet's email separately
    'vetName': "Dr. ${vet['name']}",
    'vetImage': vet['profileImage'],
  });
},
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile image with online indicator
                  Stack(
                    children: [
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              spreadRadius: 1,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: vet['profileImage'] != null
                              ? Image.network(
                                  vet['profileImage'],
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      color: Colors.grey[200],
                                      child: Icon(
                                        Icons.person,
                                        size: 40,
                                        color: Colors.grey[400],
                                      ),
                                    );
                                  },
                                )
                              : Container(
                                  color: Colors.grey[200],
                                  child: Icon(
                                    Icons.person,
                                    size: 40,
                                    color: Colors.grey[400],
                                  ),
                                ),
                        ),
                      ),
                      if (isOnline)
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(width: 16),
                  
                  // Vet information
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                "Dr. ${vet['name']}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isOnline
                                    ? Colors.green.withOpacity(0.1)
                                    : Colors.grey.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                isOnline ? 'Online' : 'Offline',
                                style: TextStyle(
                                  color: isOnline ? Colors.green : Colors.grey,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 4),
                        Text(
                          vet['clinic'] ?? 'Independent Practice',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        
                        // Specialty and experience
                        Row(
                          children: [
                            _buildInfoChip(
                              icon: Icons.medical_services,
                              label: vet['specialty'] ?? 'General',
                              color: Colors.blue,
                            ),
                            SizedBox(width: 8),
                            _buildInfoChip(
                              icon: Icons.star,
                              label: '${vet['experience'] ?? '5'} yrs',
                              color: Colors.amber,
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Chat button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
  final currentUser = FirebaseAuth.instance.currentUser;
  if (currentUser == null || currentUser.email == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Please sign in to start chatting'))
    );
    return;
  }

  Navigator.pop(context, {
    'vetEmail': vet['email'], // Pass the vet's email separately
    'vetName': "Dr. ${vet['name']}",
    'vetImage': vet['profileImage'],
  });
},
                              icon: Icon(Icons.chat_bubble_outline, size: 18),
                              label: Text('Start Chat'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.lightBlue,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: color,
          ),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

