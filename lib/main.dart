import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:planova/main_wrapper.dart';
import 'package:planova/task_page/detailtask_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_page/splash_screen.dart';
import 'login_page/login_page.dart';
import 'notification/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();

  // Initialize notifications engine and request OS system permissions
  await NotificationService.init();

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

class PlanovaApp extends StatefulWidget {
  final Widget startScreen;
  const PlanovaApp({super.key, required this.startScreen});

  @override
  State<PlanovaApp> createState() => _PlanovaAppState();
}

class _PlanovaAppState extends State<PlanovaApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();

    // 1. Stream Listener: Processes notification taps while app is running/backgrounded
    NotificationService.selectNotificationStream.stream.listen((String? taskId) {
      if (taskId != null) {
        _navigateToTaskDetail(taskId);
      }
    });

    // 2. Cold Boot Check: Catches payloads if the app was completely terminated/closed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService.checkForLaunchNotification();
    });
  }

  // 🚀 Deep Linking Routing Engine
  void _navigateToTaskDetail(String taskId) {
    Future.delayed(const Duration(milliseconds: 350), () {
      if (_navigatorKey.currentState != null) {

        // Step A: Reset navigation stack cleanly to base architecture wrapper
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const MainWrapper()),
              (route) => false,
        );

        // Step B: Push to the Detail view screen with the requested string ID data parameters
        _navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (context) => DetailTaskPage(taskId: taskId),
          ),
        );

        print("🔗 Deep Link Routing completely successful for Task Document ID: $taskId");
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Planova',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/login': (context) => const LoginPage(),
      },
      home: widget.startScreen,
    );
  }
}