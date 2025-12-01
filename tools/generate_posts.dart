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
  apiKey: "AIzaSyCHp48tbETVXBw71JNvLEdBKnjshLWXphI",
  authDomain: "zoneguard-e943a.firebaseapp.com",
  projectId: "zoneguard-e943a",
  storageBucket: "zoneguard-e943a.firebasestorage.app",
  messagingSenderId: "882643778506",
  appId: "1:882643778506:web:6d4b754ad0c4ec8dcb6d33"
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
  "userId": null,                        // same as your app when anonymous
  "username": "Anonymous",               // same as your app
  "title": titles[random.nextInt(titles.length)],
  "description": descriptions[random.nextInt(descriptions.length)],
  "crimeType": crime,
  "incidentTime": DateTime.now()
      .subtract(Duration(days: random.nextInt(60))),
  "latitude": lat,
  "longitude": lng,
  "locationName": locationName,
  "imageUrl": null,
  "createdAt": FieldValue.serverTimestamp(),

  // ⭐ EXACT MATCH TO YOUR REAL APP:
  "area": _areaCategories[random.nextInt(_areaCategories.length)],
});



    if (i % 50 == 0) print("📌 Uploaded $i posts...");
  }

  print("🎉 DONE! $count fake posts added!");
}
