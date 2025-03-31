import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:location/location.dart';
import 'package:vetconnect/pages/doc_profile.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'package:flutter/services.dart';

class FullMapView extends StatefulWidget {
  final List<Map<String, dynamic>> veterinarians;

  const FullMapView({
    Key? key,
    required this.veterinarians,
  }) : super(key: key);

  @override
  _FullMapViewState createState() => _FullMapViewState();
}

class _FullMapViewState extends State<FullMapView> {
  final Completer<GoogleMapController> _controller = Completer();
  final Location _location = Location();
  
  Set<Marker> _markers = {};
  LatLng _currentPosition = LatLng(-1.286389, 36.817223); // Default position (Nairobi)
  bool _isLoading = true;
  bool _locationEnabled = false;
  BitmapDescriptor? _vetMarkerIcon;
  BitmapDescriptor? _userMarkerIcon;
  
  // For filtering
  List<Map<String, dynamic>> _filteredVets = [];
  String _searchQuery = '';
  
  @override
  void initState() {
    super.initState();
    _filteredVets = widget.veterinarians;
    _initLocationService();
    _createCustomMarkers();
  }
  
  Future<void> _createCustomMarkers() async {
  try {
    // Create custom marker for veterinarians
    // final Uint8List vetMarkerIcon = await _getBytesFromAsset('assets/vet_marker_min.png', 120);
    // _vetMarkerIcon = BitmapDescriptor.fromBytes(vetMarkerIcon);
    
    // Create custom marker for user location
    final Uint8List userMarkerIcon = await _getBytesFromAsset('assets/user_location.png', 120);
    _userMarkerIcon = BitmapDescriptor.fromBytes(userMarkerIcon);
  } catch (e) {
    print("Error creating custom markers: $e");
    // Continue with default markers
  }
  
  _updateMarkers();
}
  
  Future<Uint8List> _getBytesFromAsset(String path, int width) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer
        .asUint8List();
  }
  
  Future<void> _initLocationService() async {
  bool _serviceEnabled;
  PermissionStatus _permissionGranted;
  
  try {
    // Check if location service is enabled
    _serviceEnabled = await _location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _location.requestService();
      if (!_serviceEnabled) {
        // If service is still not enabled, continue with default location
        print("Location services disabled");
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
    
    // Check if permission is granted
    _permissionGranted = await _location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await _location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        // If permission is still not granted, continue with default location
        print("Location permission denied");
        setState(() {
          _isLoading = false;
        });
        return;
      }
    }
    
    // Get current location with timeout
    final locationData = await _location.getLocation().timeout(
      Duration(seconds: 10),
      onTimeout: () {
        print("Location fetch timed out");
        // Return a LocationData object with null values to trigger the fallback
        return LocationData.fromMap({});
      },
    );
    
    if (locationData.latitude != null && locationData.longitude != null) {
      setState(() {
        _currentPosition = LatLng(
          locationData.latitude!,
          locationData.longitude!
        );
        _locationEnabled = true;
      });
      
      // Update camera position to current location
      _animateToCurrentLocation();
      
      // Set up location change subscription
      _location.onLocationChanged.listen((LocationData currentLocation) {
        if (currentLocation.latitude != null && currentLocation.longitude != null) {
          setState(() {
            _currentPosition = LatLng(
              currentLocation.latitude!,
              currentLocation.longitude!
            );
          });
          _updateMarkers();
        }
      });
    } else {
      print("Location data is null or incomplete");
    }
  } catch (e) {
    print("Error getting location: $e");
  } finally {
    // Always update markers and set loading to false, regardless of success or failure
    _updateMarkers();
    setState(() {
      _isLoading = false;
    });
  }
}
  
  void _updateMarkers() {
  if (!mounted) return;
  
  Set<Marker> markers = {};
  
  // Add user location marker first
  if (_locationEnabled) {
    markers.add(
      Marker(
        markerId: const MarkerId('current_location'),
        position: _currentPosition,
        icon: _userMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        infoWindow: const InfoWindow(title: 'Your Location'),
        zIndex: 2,
      ),
    );
  }
  
  // Add veterinarian markers
  for (var vet in _filteredVets) {
    // Ensure we have valid coordinates
    double lat, lng;
    
    if (vet["location"]?["lat"] != null && vet["location"]?["lng"] != null) {
      lat = vet["location"]["lat"];
      lng = vet["location"]["lng"];
    } else {
      // More distinct fallback positions
      lat = _currentPosition.latitude + (vet["id"] * 0.01);
      lng = _currentPosition.longitude + (vet["id"] * 0.01);
    }
    
    markers.add(
      Marker(
        markerId: MarkerId('vet_${vet["id"]}'),
        position: LatLng(lat, lng),
        icon: _vetMarkerIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        infoWindow: InfoWindow(
          title: vet["name"],
          snippet: vet["clinicName"],
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => DoctorProfilePage(
                  vetId: vet["id"],
                  name: vet["name"],
                  clinicName: vet["clinicName"],
                  imagePath: vet["imagePath"],
                ),
              ),
            );
          },
        ),
        zIndex: 1,
      ),
    );
  }
  
  setState(() {
    _markers = markers;
  });
}
  
  Future<void> _animateToCurrentLocation() async {
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: _currentPosition,
          zoom: 14.0,
        ),
      ),
    );
  }
  
  void _filterVeterinarians(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredVets = widget.veterinarians;
      } else {
        _filteredVets = widget.veterinarians.where((vet) {
          return vet["name"].toLowerCase().contains(query.toLowerCase()) ||
                 vet["clinicName"].toLowerCase().contains(query.toLowerCase());
        }).toList();
      }
    });
    _updateMarkers();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Veterinarians Map',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color.fromARGB(255, 39, 39, 39),
          ),
        ),
        backgroundColor: Colors.lightBlue,
        elevation: 2,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Refresh',
            onPressed: () {
              _updateMarkers();
              _animateToCurrentLocation();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          // Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentPosition,
              zoom: 13.0,
            ),
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: true,
            compassEnabled: true,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          
          // Search bar
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search veterinarians...',
                  prefixIcon: Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear),
                          onPressed: () {
                            _filterVeterinarians('');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 15),
                ),
                onChanged: _filterVeterinarians,
              ),
            ),
          ),
          
          // Veterinarian count
          Positioned(
            top: 80,
            left: 16,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                '${_filteredVets.length} Veterinarians',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlue,
                ),
              ),
            ),
          ),
          
          // Bottom card with veterinarian list
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      margin: EdgeInsets.only(top: 10, bottom: 10),
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  
                  // Title
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Nearby Veterinarians',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.lightBlue,
                      ),
                    ),
                  ),
                  
                  // List
                  Expanded(
                    child: _filteredVets.isEmpty
                        ? Center(
                            child: Text(
                              'No veterinarians found',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            scrollDirection: Axis.horizontal,
                            itemCount: _filteredVets.length,
                            itemBuilder: (context, index) {
                              final vet = _filteredVets[index];
                              return _buildVetCard(vet);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            heroTag: 'location_button',
            onPressed: _animateToCurrentLocation,
            backgroundColor: Colors.white,
            child: Icon(
              Icons.my_location,
              color: Colors.lightBlue,
            ),
            mini: true,
          ),
          SizedBox(height: 240), // Space for the bottom card
        ],
      ),
    );
  }
  
  Widget _buildVetCard(Map<String, dynamic> vet) {
  return GestureDetector(
    onTap: () {
      // Center map on this vet
      _centerMapOnVet(vet);
    },
    child: Container(
      width: 200,
      margin: EdgeInsets.only(right: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            spreadRadius: 1,
            offset: Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vet image
          ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            child: Container(
              height: 70, // Reduced height to give more space for content
              width: double.infinity,
              child: vet["imagePath"] != null && vet["imagePath"].toString().startsWith("http")
                  ? Image.network(
                      vet["imagePath"],
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Image.asset(
                          'assets/default_profile.png',
                          fit: BoxFit.cover,
                        );
                      },
                    )
                  : Image.asset(
                      'assets/default_profile.png',
                      fit: BoxFit.cover,
                    ),
            ),
          ),
          
          // Vet info - using Expanded to ensure it takes remaining space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Name with tooltip for full name on hover/long press
                  Tooltip(
                    message: vet["name"],
                    child: Text(
                      vet["name"],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13, // Slightly smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 2),
                  // Clinic name with tooltip
                  Tooltip(
                    message: vet["clinicName"],
                    child: Text(
                      vet["clinicName"],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 11, // Smaller font
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  
                  // Spacer to push buttons to bottom
                  Spacer(),
                  
                  // Action buttons in a more compact layout
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // View profile button - more compact
                      SizedBox(
                        height: 28, // Fixed height
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => DoctorProfilePage(
                                  vetId: vet["id"],
                                  name: vet["name"],
                                  clinicName: vet["clinicName"],
                                  imagePath: vet["imagePath"],
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.lightBlue,
                            padding: EdgeInsets.symmetric(horizontal: 8),
                            minimumSize: Size(0, 0),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                          child: Text(
                            'Profile',
                            style: TextStyle(fontSize: 11),
                          ),
                        ),
                      ),
                      
                      // Directions button
                      SizedBox(
                        height: 28, // Fixed height
                        child: IconButton(
                          onPressed: () {
                            _openDirections(vet);
                          },
                          icon: Icon(
                            Icons.directions,
                            color: Colors.lightBlue,
                            size: 18,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                          tooltip: 'Get Directions',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
  
  Future<void> _centerMapOnVet(Map<String, dynamic> vet) async {
    final double lat = vet["location"]?["lat"] ?? -1.286389 + (vet["id"] * 0.005);
    final double lng = vet["location"]?["lng"] ?? 36.817223 + (vet["id"] * 0.005);
    
    final GoogleMapController controller = await _controller.future;
    controller.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(lat, lng),
          zoom: 16.0,
        ),
      ),
    );
    
    // Show info window for this vet
    controller.showMarkerInfoWindow(MarkerId('vet_${vet["id"]}'));
  }
  
  void _openDirections(Map<String, dynamic> vet) {
    final double lat = vet["location"]?["lat"] ?? -1.286389 + (vet["id"] * 0.005);
    final double lng = vet["location"]?["lng"] ?? 36.817223 + (vet["id"] * 0.005);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Opening directions to ${vet["name"]}"),
        behavior: SnackBarBehavior.floating,
      ),
    );
    
    // In a real app, you would launch a maps app with directions
    // For example, using url_launcher to open Google Maps
  }

// Add this method to show a snackbar when location is found or when there's an error
void _showLocationSnackBar(String message, {bool isError = false}) {
  if (!mounted) return;
  
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: isError ? Colors.red : Colors.green,
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 3),
    ),
  );
}
}

