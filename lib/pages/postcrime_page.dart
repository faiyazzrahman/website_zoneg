import 'dart:convert';
import 'dart:ui';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../widgets/Sidenav.dart';

class PostCrimePage extends StatefulWidget {
  const PostCrimePage({super.key});

  @override
  State<PostCrimePage> createState() => _PostCrimePageState();
}

class _PostCrimePageState extends State<PostCrimePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final MapController _mapController = MapController();
  final _mapSearchController = TextEditingController();
  LatLng? _userLocation;
  bool _isPosting = false;
  bool _isAnonymous = false;
  String? _selectedCrimeType;
  DateTime? _incidentTime;
  LatLng? _selectedLocation;
  String? _selectedAreaType;

  final _crimeCategories = [
    "Theft",
    "Assault",
    "Cyber Crime",
    "Vandalism",
    "Drug Trafficking"
  ];
  final _areaCategories = [
  "Dhanmondi",
  "Gulshan",
  "Banani",
  "Baridhara",
  "Bashundhara R/A",
  "Nikunja",
  "Uttara Sector 1",
  "Uttara Sector 2",
  "Uttara Sector 3",
  "Uttara Sector 4",
  "Uttara Sector 5",
  "Uttara Sector 6",
  "Uttara Sector 7",
  "Uttara Sector 8",
  "Uttara Sector 9",
  "Uttara Sector 10",
  "Uttara Sector 11",
  "Uttara Sector 12",
  "Uttara Sector 13",
  "Uttara Sector 14",
  "Uttara Sector 15",
  "Uttara Sector 16",
  "Uttara Sector 17",
  "Uttara Sector 18",
  "Tejgaon",
  "Karwan Bazar",
  "Farmgate",
  "Shahbagh",
  "Motijheel",
  "Paltan",
  "Kakrail",
  "Shantinagar",
  "Malibagh",
  "Rampura",
  "Banasree",
  "Khilgaon",
  "Mouchak",
  "Eskaton",
  "Kathalbagan",
  "Kalabagan",
  "Panthapath",
  "Mohakhali",
  "Wireless Gate",
  "Badda",
  "Merul Badda",
  "Madhubagh",
  "Hatirjheel",
  "Mirpur 1",
  "Mirpur 2",
  "Mirpur 6",
  "Mirpur 10",
  "Mirpur 11",
  "Mirpur 12",
  "Pallabi",
  "Kafrul",
  "Shewrapara",
  "Kazipara",
  "Agargaon",
  "Ibrahimpur",
  "Rokeya Sarani",
  "Technical",
  "Gabtoli",
  "Shah Ali Bag",
  "Rupnagar",
  "Mirpur DOHS",
  "Mohammadpur",
  "Adabor",
  "Shyamoli",
  "Tajmahal Road",
  "Bosila",
  "Kalyanpur",
  "Beribadh",
  "Town Hall",
  "Chand Udyan",
  "Lalmatia",
  "Jatrabari",
  "Dainik Bangla",
  "Shyampur",
  "Konapara",
  "Matuail",
  "Demra",
  "Kadamtali",
  "Gandaria",
  "Wari",
  "Narinda",
  "Sadarghat",
  "Sutrapur",
  "Tikatuli",
  "Dayaganj",
  "Dholaipar",
  "Postogola",
  "Lalbagh",
  "Nawabganj",
  "Kamrangirchar",
  "Chawkbazar",
  "Bongshal",
  "Armanitola",
  "Islampur",
  "Shankhari Bazar",
  "Banglabazar",
  "Hazaribagh",
  "Rayerbazar",
  "Azimpur",
  "Nilkhet",
  "Dhakeshwari",
  "Shahidnagar",
  "Nayabazar",
  "Aftabnagar",
  "Bashabo",
  "Goran",
  "Sabujbagh",
  "Mugda",
  "Tilpapara",
  "Manda",
  "Cantonment",
  "DOHS Baridhara",
  "DOHS Banani",
  "DOHS Mirpur",
  "Jahangir Gate",
  "Amin Bazar",
  "Ashulia",
  "Tongi",
  "Abdullahpur",
  "Kanchpur",
  "Signboard",
  "Shanir Akhra",
];

Widget _buildAreaDropdown() {
  return DropdownButtonFormField<String>(
    value: _selectedAreaType,
    dropdownColor: const Color(0xFF243B55),
    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
    decoration: _inputDecoration("Area Type *", Icons.map),
    items: _areaCategories
        .map((e) => DropdownMenuItem(
              value: e,
              child: Text(e),
            ))
        .toList(),
    onChanged: (v) => setState(() => _selectedAreaType = v),
    validator: (v) => v == null ? 'Select area type' : null,
  );
}

Future<LatLng?> _getUserLocation() async {
  try {
    final pos = await html.window.navigator.geolocation?.getCurrentPosition();
    if (pos != null) {
      final lat = pos.coords?.latitude ?? 23.8103;
      final lon = pos.coords?.longitude ?? 90.4125;

      setState(() {
        _userLocation = LatLng(lat.toDouble(), lon.toDouble());

        _selectedLocation = null; // optionally mark it on map
      });

      return _userLocation;
    }
    return null;
  } catch (e) {
    print("Geolocation error: $e");
    return null;
  }
}

  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  int _currentIndex = 2;
  List<Map<String, dynamic>> _searchResults = [];

  // Image upload
  PlatformFile? _selectedFile;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _fadeAnimation =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut));
    _animationController.forward();

    _mapSearchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    _searchLocation(_mapSearchController.text.trim());
  }

  Future<void> _searchLocation(String query) async {
    if (query.isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    final url = "https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1";
    final response = await http.get(Uri.parse(url), headers: {'User-Agent': 'FlutterApp'});

    if (response.statusCode == 200) {
      final results = List<Map<String, dynamic>>.from(jsonDecode(response.body));
      setState(() {
        _searchResults = results;
      });
    }
  }

  Future<void> _selectIncidentTime(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentTime ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (picked != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );
      if (time != null) {
        setState(() {
          _incidentTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  // Pick file (web & mobile)
  Future<void> _pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );

  if (result != null && result.files.isNotEmpty) {
    setState(() => _selectedFile = result.files.first);

    if (_selectedFile!.bytes != null) {
      await _uploadToCloudinary(_selectedFile!);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to read image bytes')),
      );
    }
  }
}

Future<void> _uploadToCloudinary(PlatformFile file) async {
  const cloudName = "dcyjussfg";              // REQUIRED
  const uploadPreset = "crime post"; // REQUIRED

  final uri = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  final request = http.MultipartRequest("POST", uri)
    ..fields["upload_preset"] = uploadPreset
    ..files.add(
      http.MultipartFile.fromBytes(
        "file",
        file.bytes!,
        filename: file.name,
      ),
    );

  final response = await request.send();

  if (response.statusCode == 200) {
    final data = jsonDecode(await response.stream.bytesToString());

    setState(() => _uploadedImageUrl = data["secure_url"]);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image uploaded successfully!')),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Failed to upload image')),
    );
  }
}

Future<String> _getLocationName(LatLng position) async {
  final apiKey = "23ZkZ1lxbUo3o7Fup9ls";
  final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${position.longitude},${position.latitude}.json?key=$apiKey');

  try {
    final response = await http.get(url, headers: {'User-Agent': 'FlutterApp'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        return feature['place_name_en'] ?? feature['place_name'] ?? "Unknown location";
      } else {
        return "Unknown location";
      }
    } else {
      return "Unknown location";
    }
  } catch (e) {
    print("Reverse geocoding error: $e");
    return "Unknown location";
  }
}



//submit post function
Future<void> _submitPost() async {
  if (_selectedFile != null && _uploadedImageUrl == null) {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait until image is uploaded')));
    return;
  }
  if (_selectedAreaType == null) {
  ScaffoldMessenger.of(context)
      .showSnackBar(const SnackBar(content: Text('Select an area type')));
  return;
}

  if (!_formKey.currentState!.validate()) return;
  if (_selectedCrimeType == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Select a crime type')));
    return;
  }
  if (_incidentTime == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Select incident time')));
    return;
  }
  if (_selectedLocation == null) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Mark the incident location')));
    return;
  }

  setState(() => _isPosting = true);

  try {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not logged in');

    // Get human-readable location name
    final locationName = await _getLocationName(_selectedLocation!);

    final postRef = _firestore.collection('crime_posts').doc();

    await postRef.set({
      'userId': _isAnonymous ? null : user.uid,
      'username': _isAnonymous ? 'Anonymous' : user.displayName,
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'crimeType': _selectedCrimeType,
      'incidentTime': _incidentTime,
      'latitude': _selectedLocation!.latitude,
      'longitude': _selectedLocation!.longitude,
      'locationName': locationName, // Save location name here
      'imageUrl': _uploadedImageUrl,
      'createdAt': FieldValue.serverTimestamp(),
      'area': _selectedAreaType,

    });

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Crime report submitted!')));
    _clearForm();
  } catch (e) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Error: $e')));
  } finally {
    if (mounted) setState(() => _isPosting = false);
  }
}


  void _clearForm() {
    _titleController.clear();
    _descriptionController.clear();
    setState(() {
      _selectedCrimeType = null;
      _incidentTime = null;
      _selectedLocation = null;
      _isAnonymous = false;
      _searchResults = [];
      _mapSearchController.clear();
      _selectedFile = null;
      _uploadedImageUrl = null;
    });
  }

  String _formatDateTime(DateTime dateTime) =>
      "${dateTime.day}/${dateTime.month}/${dateTime.year} "
      "${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}";

  @override
  void dispose() {
    _animationController.dispose();
    _mapSearchController.removeListener(_onSearchChanged);
    _mapSearchController.dispose();
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
                  colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                ),
                child: Center(
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: SingleChildScrollView(
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
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            "Report Crime",
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 28),
          _buildDropdown(),   // Crime Type
const SizedBox(height: 16),

_buildAreaDropdown(),  // 🔵 NEW AREA DROPDOWN
const SizedBox(height: 16),

          _buildTextField(_titleController, "Title (Optional)", Icons.edit),
          const SizedBox(height: 16),
          _buildTextField(
            _descriptionController,
            "Description *",
            Icons.description,
            maxLines: 5,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return "Provide a description";
              if (v.trim().length < 10) return "At least 10 characters";
              return null;
            },
          ),
          const SizedBox(height: 16),
          _buildDateTimePicker(),
          const SizedBox(height: 16),
          _buildMapPicker(),
          const SizedBox(height: 16),
          _buildFilePicker(),
          const SizedBox(height: 16),
          _buildAnonymousSwitch(),
          const SizedBox(height: 24),
          _buildSubmitButton(),
        ],
      ),
    );
  }
Widget _buildMapPicker() {
  final initialCenter = LatLng(23.8103, 90.4125);

  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        "Mark Incident Location *",
        style: TextStyle(color: Colors.white, fontSize: 15),
      ),
      const SizedBox(height: 10),

      // Search Bar
      ClipRRect(
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
                        decoration: const InputDecoration(
                          hintText: 'Search location...',
                          border: InputBorder.none,
                        ),
                        style: const TextStyle(color: Colors.black),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.search, color: Colors.black87),
                      onPressed: () => _searchLocation(_mapSearchController.text),
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
                            item['display_name'] ?? "Unknown location",
                            style: const TextStyle(fontSize: 14),
                          ),
                          onTap: () {
                            final lat = double.parse(item['lat']);
                            final lon = double.parse(item['lon']);
                            final pos = LatLng(lat, lon);
                            setState(() {
                              _selectedLocation = pos;
                              _mapController.move(pos, 15);
                              _searchResults = [];
                              _mapSearchController.text =
                                  item['display_name'] ?? '';
                            });
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 10),

      // Map with "My Location" button
      SizedBox(
        height: 300,
        child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: initialCenter,
                initialZoom: 13,
                onTap: (tapPos, latLng) {
                  setState(() => _selectedLocation = latLng);
                },
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://api.maptiler.com/maps/streets-v2/{z}/{x}/{y}.png?key=23ZkZ1lxbUo3o7Fup9ls',
                  userAgentPackageName: 'com.example.app',
                  maxZoom: 20,
                ),
                
                  MarkerLayer(
  markers: [
    if (_userLocation != null)
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

      
    if (_selectedLocation != null)
      Marker(
  point: _selectedLocation!,
  width: 40,
  height: 40,
  child: const Icon(
    Icons.location_pin,
    color: Colors.red,
    size: 40,
  ),
),

  ],
),

              ],
            ),

            // My Location Floating Button
            Positioned(
              bottom: 10,
              right: 10,
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
      ),

      if (_selectedLocation != null)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            "Lat: ${_selectedLocation!.latitude.toStringAsFixed(5)}, "
            "Lng: ${_selectedLocation!.longitude.toStringAsFixed(5)}",
            style: const TextStyle(color: Colors.white70),
          ),
        ),
    ],
  );
}


  Widget _buildFilePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Attach Image (Optional)", style: TextStyle(color: Colors.white)),
        const SizedBox(height: 8),
        Row(
          children: [
            ElevatedButton(
              onPressed: _pickFile,
              child: const Text('Pick Image'),
            ),
            const SizedBox(width: 16),
            if (_selectedFile != null)
              SizedBox(
                height: 50,
                width: 50,
                child: Image.memory(_selectedFile!.bytes!, fit: BoxFit.cover),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCrimeType,
      dropdownColor: const Color(0xFF243B55),
      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
      decoration: _inputDecoration("Crime Type *", Icons.category),
      items: _crimeCategories
          .map((e) => DropdownMenuItem(
                value: e,
                child: Text(e),
              ))
          .toList(),
      onChanged: (v) => setState(() => _selectedCrimeType = v),
      validator: (v) => v == null ? 'Select a crime type' : null,
    );
  }

  Widget _buildDateTimePicker() {
    return InkWell(
      onTap: () => _selectIncidentTime(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: Colors.white70),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _incidentTime == null
                    ? 'Select incident time'
                    : _formatDateTime(_incidentTime!),
                style: const TextStyle(color: Colors.white, fontSize: 15),
              ),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildAnonymousSwitch() {
    return Row(
      children: [
        const Icon(Icons.visibility_off, color: Colors.white70),
        const SizedBox(width: 12),
        const Expanded(
            child: Text("Post Anonymously", style: TextStyle(color: Colors.white))),
        Switch(
          value: _isAnonymous,
          activeColor: Colors.blueAccent,
          onChanged: (v) => setState(() => _isAnonymous = v),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: _isPosting ? null : _submitPost,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 18),
        backgroundColor: Colors.blueAccent,
      ),
      child: _isPosting
          ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
          : const Text(
              "Submit Crime Report",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: Colors.white.withOpacity(0.12),
      enabledBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.white24),
      ),
      focusedBorder: const OutlineInputBorder(
        borderSide: BorderSide(color: Colors.blueAccent, width: 1.5),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon,
      {int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      cursorColor: Colors.white,
      style: const TextStyle(color: Colors.white),
      decoration: _inputDecoration(hint, icon),
    );
  }


}
