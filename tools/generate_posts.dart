// tools/generate_posts.dart

import 'dart:math';
import 'dart:convert';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

Future<void> main() async {
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyB43kIDjh1oVACNzVsc1BUGdcZlz-Y4lkQ",
      authDomain: "zoneguard-dev.firebaseapp.com",
      projectId: "zoneguard-dev",
      storageBucket: "zoneguard-dev.firebasestorage.app",
      messagingSenderId: "199160521145",
      appId: "1:199160521145:web:7d2abb999c7f3004755668",
      measurementId: "G-6KKE6MDZVN",
    ),
  );

  print("🔥 Firebase Connected!");
  await generateFakePosts(1000);
}

// -----------------------------------------------------------------------
// 📌 Fake Data Generator
// -----------------------------------------------------------------------

const double baseLat = 23.8130; // Mirpur, Dhaka
const double baseLng = 90.3667;

final List<String> crimeTypes = [
  "Theft",
  "Assault",
  "Cyber Crime",
  "Vandalism",
  "Drug Trafficking",
];

final List<String> titles = [
  "Suspicious Activity",
  "Property Damage",
  "Fight Reported",
  "Pickpocket Case",
  "Harassment Incident",
  "Vehicle Theft",
  "Attempted Robbery",
];

final List<String> descriptions = [
  "Local citizens reported suspicious movement.",
  "Witness saw a group causing disturbance.",
  "Victim reported being attacked.",
  "Mobile phone was snatched from the victim.",
  "Vehicle was forcefully taken.",
  "Harassment was reported by a pedestrian.",
  "Suspect ran away before police arrived.",
];

// -----------------------------------------------------------------------
// 🔹 Reverse geocoding for readable location
// -----------------------------------------------------------------------

Future<String> _getLocationName(LatLng position) async {
  final apiKey = "23ZkZ1lxbUo3o7Fup9ls";
  final url = Uri.parse(
      'https://api.maptiler.com/geocoding/${position.longitude},${position.latitude}.json?key=$apiKey');

  try {
    final response = await http.get(url, headers: {'User-Agent': 'DartScript'});
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data['features'] != null && data['features'].isNotEmpty) {
        final feature = data['features'][0];
        return feature['place_name_en'] ?? feature['place_name'] ?? "Unknown location";
      }
    }
    return "Unknown location";
  } catch (e) {
    print("Reverse geocoding error: $e");
    return "Unknown location";
  }
}

// -----------------------------------------------------------------------
// 🔹 Generate fake posts
// -----------------------------------------------------------------------

Future<void> generateFakePosts(int count) async {
  final firestore = FirebaseFirestore.instance;
  final random = Random();

  for (int i = 1; i <= count; i++) {
    // Random coordinates (~8km radius)
    double lat = baseLat + (random.nextDouble() - 0.5) * 0.5;
    double lng = baseLng + (random.nextDouble() - 0.5) * 0.5;
    final position = LatLng(lat, lng);

    final crime = crimeTypes[random.nextInt(crimeTypes.length)];
    final locationName = await _getLocationName(position);

    final postRef = firestore.collection("crime_posts").doc();
    await postRef.set({
      "postId": postRef.id,
      "userId": null,
      "username": "Anonymous",
      "title": titles[random.nextInt(titles.length)],
      "description": descriptions[random.nextInt(descriptions.length)],
      "crimeType": crime,
      "incidentTime": DateTime.now().subtract(Duration(days: random.nextInt(60))),
      "latitude": lat,
      "longitude": lng,
      "locationName": locationName,
      "imageUrl": null,
      "createdAt": FieldValue.serverTimestamp(),
    });

    if (i % 50 == 0) print("📌 Uploaded $i posts...");
  }

  print("🎉 DONE! $count fake posts added!");
}
