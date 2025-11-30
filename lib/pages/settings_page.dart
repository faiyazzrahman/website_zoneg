import 'dart:io';
import 'dart:ui';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../widgets/Sidenav.dart';
import 'package:crop_your_image/crop_your_image.dart';
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final uid = FirebaseAuth.instance.currentUser!.uid;

  int _currentIndex = 4;
  final CropController _cropController = CropController();
  Uint8List? pickedImageBytes;

  String? profilePic;
  bool emailNotif = true;
  bool pushNotif = false;
  bool monthly = true;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();

    setState(() {
      profilePic = doc["profilePic"];
      emailNotif = doc["emailNotification"];
      pushNotif = doc["pushNotification"];
      monthly = doc["monthlyReports"];
    });
  }


Future<String?> uploadImageToCloudinary(Uint8List bytes) async {
  const cloudName = "dcyjussfg";
  const preset = "userimg";

  final url = Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

  final request = http.MultipartRequest("POST", url)
    ..fields["upload_preset"] = preset
    ..files.add(
      http.MultipartFile.fromBytes(
        'file',
        bytes,
        filename: "profile.jpg",
      ),
    );

  final response = await request.send();
  final body = await response.stream.bytesToString();
  final json = jsonDecode(body);

  return json["secure_url"];
}



Future<String> getUserName() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) return "Unknown User";

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final data = doc.data();

  if (data == null || data['username'] == null) {
    return "Unnamed User";
  }

  return data['username'];
}


Future<void> pickProfileImage() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    allowMultiple: false,
    withData: true, // IMPORTANT for Web/Desktop
  );

  if (result == null || result.files.isEmpty) return;

  // File bytes (works on all platforms)
  pickedImageBytes = result.files.single.bytes;

  if (pickedImageBytes == null) {
    final file = File(result.files.single.path!);
    pickedImageBytes = await file.readAsBytes();
  }

  // Show cropping dialog
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: Colors.black,
      content: SizedBox(
        width: 400,
        height: 400,
        child: Crop(
          controller: _cropController,
          image: pickedImageBytes!,
          onCropped: (croppedBytes) async {
  Navigator.pop(ctx);

  final url = await uploadImageToCloudinary(croppedBytes);

  if (url != null) {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .update({"profilePic": url});

    setState(() => profilePic = url);
  }
},

        ),
      ),
      actions: [
        TextButton(
          onPressed: () => _cropController.crop(),
          child: const Text("Upload image", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child:
              const Text("Cancel", style: TextStyle(color: Colors.redAccent)),
        ),
      ],
    ),
  );
}

Future<String> getUserProfileImageUrl() async {
  final user = FirebaseAuth.instance.currentUser;

  if (user == null) {
    return "https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png";
  }

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final data = doc.data();

  if (data == null || data['profilePic'] == null) {
    return "https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png";
  }

  return data['profilePic'];
}



Future<void> updateUsername(String newName) async {
  if (newName.trim().isEmpty) return;

  final batch = FirebaseFirestore.instance.batch();

  // Update user document
  final userRef = FirebaseFirestore.instance.collection("users").doc(uid);
  batch.update(userRef, {"username": newName});

  // Update all posts by this user
  final posts = await FirebaseFirestore.instance
      .collection("crime_posts")
      .where("uid", isEqualTo: uid)
      .get();

  for (var doc in posts.docs) {
    batch.update(doc.reference, {"username": newName});
  }

  await batch.commit();
}


  Future<void> updatePassword(String newPassword) async {
    await FirebaseAuth.instance.currentUser!.updatePassword(newPassword);
  }

  Future<void> updateEmail(String newEmail) async {
    await FirebaseAuth.instance.currentUser!.verifyBeforeUpdateEmail(newEmail);
  }

  Future<void> updateNotification(String key, bool value) async {
    await FirebaseFirestore.instance.collection("users").doc(uid).update({
      key: value,
    });
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
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF0F2027),
                    Color(0xFF203A43),
                    Color(0xFF2C5364)
                  ],
                ),
              ),

              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Container(
                    width: 900,
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.07),
                      border: Border.all(color: Colors.white24),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Settings",
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 20),

                        Center(
  child: Column(
    children: [
      GestureDetector(
        onTap: () {
          pickProfileImage();
        },
        child: FutureBuilder<String>(
          future: getUserProfileImageUrl(),
          builder: (context, snapshot) {
            final avatarUrl = snapshot.data ??
                "https://upload.wikimedia.org/wikipedia/commons/9/99/Sample_User_Icon.png";

            return Container(
              padding: EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: CircleAvatar(
                radius: 60, // <<< FIXED SIZE
                backgroundImage: NetworkImage(avatarUrl),
              ),
            );
          },
        ),
      ),

      const SizedBox(height: 12),

      FutureBuilder<String>(
        future: getUserName(),
        builder: (context, snapshot) {
          final name = snapshot.data ?? "Loading...";

          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(width: 8),

            ],
          );
        },
      ),
    ],
  ),
),

                        const SizedBox(height: 30),

                        // ACCOUNT SETTINGS
                        settingsSection(
                          title: "Account Settings",
                          children: [
                            ListTile(
                              title: const Text("Username",
                                  style: TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: const Icon(Icons.edit, color: Colors.white70),
                                onPressed: () {
                                  final controller = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Change Username"),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                            labelText: "New Username"),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            updateUsername(controller.text);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text("Save"),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Divider(color: Colors.white24),

                            ListTile(
                              title: const Text("Email",
                                  style: TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: const Icon(Icons.mail, color: Colors.white70),
                                onPressed: () {
                                  final controller = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Change Email"),
                                      content: TextField(
                                        controller: controller,
                                        decoration: const InputDecoration(
                                            labelText: "New Email"),
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            updateEmail(controller.text);
                                            Navigator.pop(ctx);
                                          },
                                          child: const Text("Update"),
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Divider(color: Colors.white24),

                            ListTile(
                              title: const Text("Password",
                                  style: TextStyle(color: Colors.white)),
                              trailing: IconButton(
                                icon: const Icon(Icons.lock, color: Colors.white70),
                                onPressed: () {
                                  final pass = TextEditingController();
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: const Text("Change Password"),
                                      content: TextField(
                                        controller: pass,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                            labelText: "New Password"),
                                      ),
                                      actions: [
                                        TextButton(
                                            onPressed: () {
                                              updatePassword(pass.text);
                                              Navigator.pop(ctx);
                                            },
                                            child: const Text("Update"))
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 28),

                        // NOTIFICATIONS
                        settingsSection(
                          title: "Notifications",
                          children: [
                            switchTile("Email Notifications", emailNotif, (v) {
                              setState(() => emailNotif = v);
                              updateNotification("emailNotification", v);
                            }),
                            switchTile("Push Notifications", pushNotif, (v) {
                              setState(() => pushNotif = v);
                              updateNotification("pushNotification", v);
                            }),
                            switchTile("Monthly Reports", monthly, (v) {
                              setState(() => monthly = v);
                              updateNotification("monthlyReports", v);
                            }),
                          ],
                        ),
                      ],
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

  Widget settingsSection({required String title, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: Colors.white)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget switchTile(String title, bool value, Function(bool) onChange) {
    return Column(
      children: [
        SwitchListTile(
          title: Text(title, style: const TextStyle(color: Colors.white)),
          value: value,
          onChanged: onChange,
          activeColor: Colors.lightBlueAccent,
        ),
        Divider(color: Colors.white24),
      ],
    );
  }
}
