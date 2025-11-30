import 'package:flutter/material.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
   
     try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    print('Initialization error: $e');
  }
  runApp(MyApp());
}