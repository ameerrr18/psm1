import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planova/main_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page/splash_screen.dart';
import 'login_page/login_page.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  final prefs = await SharedPreferences.getInstance();
  final bool rememberMe = prefs.getBool('remember_me') ?? false;


  final User? user = FirebaseAuth.instance.currentUser;


  Widget initialScreen;

  if (rememberMe && user != null) {
    initialScreen = const MainWrapper();
  } else {
    initialScreen = const SplashScreen();
  }


  runApp(PlanovaApp(startScreen: initialScreen));
}

class PlanovaApp extends StatelessWidget {
  final Widget startScreen;

  const PlanovaApp({super.key, required this.startScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planova',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true, // Recommended for modern Flutter looks
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(), // Ensure your Login class is imported here
      },
      // Use the screen we decided on in the main function
      home: startScreen,
    );
  }
}