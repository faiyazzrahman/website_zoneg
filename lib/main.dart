import 'package:flutter/material.dart';
import 'app.dart';
import 'package:firebase_core/firebase_core.dart';
import 'services/notification_service.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
   
     try {
    await Firebase.initializeApp();
    await NotificationService().initialize();
  } catch (e) {
    print('Initialization error: $e');
  }
  runApp(MyApp());
}