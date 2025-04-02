import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'api_service.dart';

class LocationService {
  // API key for Google Maps services
  static const String _apiKey = 'YOUR_GOOGLE_MAPS_API_KEY';

  // Check and request location permissions
  static Future<bool> checkLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  // Get current user location
  static Future<Position?> getCurrentLocation() async {
    final permissionGranted = await checkLocationPermission();
    
    if (!permissionGranted) {
      return null;
    }

    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      print('Error getting location: $e');
      return null;
    }
  }

  // Get address from coordinates (reverse geocoding)
  static Future<String> getAddressFromLatLng(double lat, double lng) async {
    final url = 'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$_apiKey';
    
    try {
      final response = await http.get(Uri.parse(url));
      final data = json.decode(response.body);
      
      if (data['status'] == 'OK') {
        return data['results'][0]['formatted_address'];
      } else {
        return 'Unknown location';
      }
    } catch (e) {
      return 'Error getting address';
    }
  }

  // Get nearby vet clinics
  static Future<List<Marker>> getNearbyVetClinics(Function(String) onTap) async {
    final clinics = await ApiService.getNearbyVetClinics();
    
    return clinics.map((clinic) {
      return Marker(
        markerId: MarkerId(clinic['id']),
        position: LatLng(clinic['latitude'], clinic['longitude']),
        infoWindow: InfoWindow(
          title: clinic['name'],
          snippet: '${clinic['vet_name']} - ${clinic['address']}',
          onTap: () => onTap(clinic['id']),
        ),
      );
    }).toList();
  }

  // Calculate distance between two points
  static double calculateDistance(double startLat, double startLng, double endLat, double endLng) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng) / 1000; // Convert to km
  }
}
