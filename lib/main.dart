import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: "AIzaSyAX-BbyN_Z2f1KM-piSd92nzO1ZNNzOZv0",
      authDomain: "dbcrudpastillero.firebaseapp.com",
      projectId: "dbcrudpastillero",
      storageBucket: "dbcrudpastillero.firebasestorage.app",
      messagingSenderId: "715757124697",
      appId: "1:715757124697:web:4fe0e52c3bf197315e0548",
    ),
  );
  runApp(const RelojPastilleroApp());
}

class RelojPastilleroApp extends StatelessWidget {
  const RelojPastilleroApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Reloj Pastillero',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.blue,
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return snapshot.hasData ? const HomeScreen() : const LoginScreen();
        },
      ),
    );
  }
}
