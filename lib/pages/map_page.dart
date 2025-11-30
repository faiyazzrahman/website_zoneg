import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map_heatmap/flutter_map_heatmap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../widgets/Sidenav.dart';
import 'package:geolocator/geolocator.dart';



class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPage();
}

class _MapPage extends State<MapPage> with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _mapSearchController = TextEditingController();
  LatLng? _userLocation;
  final FocusNode _searchFocusNode = FocusNode();

  List<Map<String, dynamic>> _searchResults = [];

  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 1;
  void _showCrimeInfo(Map<String, dynamic> post) {
  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        child: Container(
          width: 350,
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post['title'] ?? 'Crime Report',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text("Type: ${post['crimeType'] ?? 'Unknown'}"),
              Text("Time: ${post['incidentTime'] ?? 'Not specified'}"),
              const SizedBox(height: 10),

              if (post['imageUrl'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(post['imageUrl'], height: 150, width: double.infinity, fit: BoxFit.cover),
                ),

              const SizedBox(height: 10),
              Text(post['description'] ?? '',
                  style: const TextStyle(fontSize: 14)),

              const SizedBox(height: 16),
              Align(
                alignment: Alignment.bottomRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
Future<List<Map<String, dynamic>>> _getCrimeClusters() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('crime_posts')
      .get();

  final docs = snapshot.docs;

  List<Map<String, dynamic>> crimes = docs.map((d) => d.data()).toList();
  return crimes;
}

Stream<List<Map<String, dynamic>>> _fetchCrimePosts() {
  return FirebaseFirestore.instance
      .collection('crime_posts')
      .orderBy('createdAt', descending: true)
      .snapshots()
      .map((snap) => snap.docs.map((d) => d.data()).toList());
}

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _searchFocusNode.addListener(() {
    if (!_searchFocusNode.hasFocus) {
      // Hide suggestions when search loses focus
      setState(() => _searchResults = []);
    }
  });
    _animationController.forward();
    _mapSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchLocation(_mapSearchController.text.trim());
  }
double _distance(LatLng a, LatLng b) {
  final geolocator = GeolocatorPlatform.instance;
  return Geolocator.distanceBetween(
    a.latitude,
    a.longitude,
    b.latitude,
    b.longitude,
  );
}

List<Polygon> _buildDangerZones(List posts) {
  List<Polygon> polygons = [];

  // Zone size (degrees)
  const zoneSize = 0.02;

  // Map <zone, crimeCount>
  final densityMap = <String, int>{};

  for (var p in posts) {
    final lat = (p["latitude"] / zoneSize).floor();
    final lon = (p["longitude"] / zoneSize).floor();
    final key = "$lat-$lon";

    densityMap[key] = (densityMap[key] ?? 0) + 1;
  }

  densityMap.forEach((key, count) {
    final parts = key.split("-");
    final x = int.parse(parts[0]);
    final y = int.parse(parts[1]);

    final zoneSW = LatLng(x * zoneSize.toDouble(), y * zoneSize.toDouble());
    final zoneNE = LatLng((x + 1) * zoneSize.toDouble(), (y + 1) * zoneSize.toDouble());

    // Color based on count
    Color fillColor;
    if (count > 10) fillColor = Colors.red.withOpacity(0.4);
    else if (count > 5) fillColor = Colors.orange.withOpacity(0.35);
    else fillColor = Colors.yellow.withOpacity(0.25);

    polygons.add(
      Polygon(
        points: [
          LatLng(zoneSW.latitude, zoneSW.longitude),
          LatLng(zoneSW.latitude, zoneNE.longitude),
          LatLng(zoneNE.latitude, zoneNE.longitude),
          LatLng(zoneNE.latitude, zoneSW.longitude),
        ],
        color: fillColor,
        borderColor: Colors.transparent,
      ),
    );
  });

  return polygons;
}


Future<void> _searchLocation(String query, {bool hideAfterSearch = false}) async {
  if (query.isEmpty) {
    setState(() => _searchResults = []);
    return;
  }

  final url =
      "https://api.maptiler.com/geocoding/$query.json?key=23ZkZ1lxbUo3o7Fup9ls";

  final response = await http.get(Uri.parse(url));

  if (response.statusCode != 200) {
    setState(() => _searchResults = []);
    return;
  }

  final data = jsonDecode(response.body);
  final features = data["features"] as List;

  // Raw results
  List<Map<String, dynamic>> results =  features.map((f) {
  final placeName = f["place_name"] ?? "Unknown location";
  final lat = (f["center"]?[1] ?? 0).toDouble();
  final lon = (f["center"]?[0] ?? 0).toDouble();

  return {
    "name": placeName,
    "lat": lat,
    "lon": lon,
  };
}).toList();
  // Sort by distance from user (only if user location exists)
  if (_userLocation != null) {
    results.sort((a, b) {
      final distA = _distance(
          _userLocation!, LatLng(a["lat"], a["lon"]));
      final distB = _distance(
          _userLocation!, LatLng(b["lat"], b["lon"]));
      return distA.compareTo(distB);
    });
  }

  // Hide suggestions immediately if a search button is clicked
  if (hideAfterSearch) {
    if (results.isNotEmpty) {
      final first = results.first;
      _mapController.move(LatLng(first["lat"], first["lon"]), 15);

      setState(() {
        _mapSearchController.text = first["display_name"];
        _searchResults = []; // hide suggestions
      });
    }
    return;
  }

  setState(() => _searchResults = results);
}



Future<LatLng?> _getUserLocation() async {
  try {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await Geolocator.openLocationSettings();
      return null;
    }

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final pos = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.best,
    );

    setState(() {
      _userLocation = LatLng(pos.latitude, pos.longitude);
    });

    return _userLocation;
  } catch (e) {
    return null;
  }
}


  @override
  void dispose() {
    _animationController.dispose();
    _mapSearchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          SideNav(
            currentIndex: _currentIndex,
            onTabSelected: (index) {
              setState(() => _currentIndex = index);
              switch (index) {
                case 0:
                  Navigator.pushReplacementNamed(context, '/dashboard');
                  break;
                case 1:
                  Navigator.pushReplacementNamed(context, '/map');
                  break;
                case 3:
                  Navigator.pushReplacementNamed(context, '/inbox');
                  break;
                case 4:
                  Navigator.pushReplacementNamed(context, '/settings');
                  break;
              }
            },
          ),

          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0F2027),
                      Color(0xFF203A43),
                      Color(0xFF2C5364)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Container(
                          width: 720,
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: _buildForm(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          "Crime Indicator",
          style: TextStyle(
            fontSize: 34,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 1,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 28),
        _buildMapPicker(),
      ],
    );
  }

  Widget _buildMapPicker() {
    final initialCenter = LatLng(23.8103, 90.4125);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),

        _buildSearchBar(),
        const SizedBox(height: 10),

        _buildMap(initialCenter),
      ],
    );
  }

Widget _buildSearchBar() {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Container(
        color: Colors.white.withOpacity(0.25),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _mapSearchController,
                    focusNode: _searchFocusNode,
                    decoration: const InputDecoration(
                      hintText: 'Search location...',
                      border: InputBorder.none,
                    ),
                    style: const TextStyle(color: Colors.black),
                    onChanged: (value) {
                      _searchLocation(value); // show suggestions while typing
                    },
                    onSubmitted: (value) {
                      _searchFocusNode.unfocus(); // hide suggestions
                      _searchLocation(value);
                    },
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.search, color: Colors.black87),
                  onPressed: () {
                    _searchFocusNode.unfocus(); // hide suggestions
                    _searchLocation(_mapSearchController.text);
                  },
                ),
              ],
            ),

            if (_searchResults.isNotEmpty)
              Container(
                height: 150,
                color: Colors.white.withOpacity(0.9),
                child: ListView.builder(
                  itemCount: _searchResults.length,
                  itemBuilder: (context, index) {
                    final item = _searchResults[index];
                    return ListTile(
                      title: Text(
                        item['name'],
                        style: const TextStyle(fontSize: 14),
                      ),
                      onTap: () {
                        final pos = LatLng(item['lat'], item['lon']);
                        _mapController.move(pos, 15);

                        _mapSearchController.text = item['name'];
                        _searchResults = [];
                        _searchFocusNode.unfocus(); // hide suggestions
                        setState(() {});
                      },
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildMap(LatLng center) {
  return SizedBox(
    height: 600,
    child: Stack(
      children: [
        ClipRRect(
          child: FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: center,
              initialZoom: 13,
            ),
            children: [
             TileLayer(
  urlTemplate:
      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=23ZkZ1lxbUo3o7Fup9ls',
  userAgentPackageName: 'com.example.app',
  maxZoom: 20,
),
FutureBuilder(
  future: _getCrimeClusters(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();
    final posts = snapshot.data!;
    return PolygonLayer(
      polygons: _buildDangerZones(posts),
    );
  },
),

StreamBuilder<List<Map<String, dynamic>>>(
  stream: _fetchCrimePosts(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();
    final posts = snapshot.data!;

   return HeatMapLayer(
  heatMapDataSource: InMemoryHeatMapDataSource(
    data: posts.map((p) => WeightedLatLng(
      LatLng(p['latitude'], p['longitude']),
      1.0, // intensity or weight
    )).toList(),
  ),
  heatMapOptions: HeatMapOptions(
    minOpacity: 0.3,
    layerOpacity: 0.8,
    blurFactor: 0.85,
    radius: 50,
    gradient: {
      0.2: Colors.yellow,
      0.4: Colors.orange,
      0.7: Colors.red,
      1.0: Colors.deepPurple,
    },
  ),
);

  },
),


              // Blue Dot Marker
              if (_userLocation != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _userLocation!,
                      width: 20,
                      height: 20,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                        ),
                      ),
                    ),
                  ],
                ),
                // Crime Markers from Firestore
StreamBuilder<List<Map<String, dynamic>>>(
  stream: _fetchCrimePosts(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) return const SizedBox();
    final posts = snapshot.data!;

    return MarkerLayer(
      markers: posts.map((post) {
        final lat = post['latitude'];
        final lon = post['longitude'];
        if (lat == null || lon == null) return const Marker(point: LatLng(0,0), width: 0, height: 0, child: SizedBox());

        return Marker(
          point: LatLng(lat, lon),
          width: 36,
          height: 36,
          child: GestureDetector(
            onTap: () => _showCrimeInfo(post),
            child: Tooltip(
              message: post['title'] ?? 'Crime Report',
              child: const Icon(Icons.location_on, size: 32, color: Colors.redAccent),
            ),
          ),
        );
      }).toList(),
    );
  },
),

            ],
          ),
        ),

        Positioned(
          bottom: 20,
          right: 20,
          child: FloatingActionButton(
            backgroundColor: Colors.white,
            child: const Icon(Icons.my_location, color: Colors.black),
            onPressed: () async {
              final userPos = await _getUserLocation();
              if (userPos != null) {
                _mapController.move(userPos, 16);
              }
            },
          ),
        ),

        
      ],
    ),
  );
}

}