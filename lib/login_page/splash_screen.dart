import 'package:flutter/material.dart';
import 'login_page.dart';
import 'package:flutter_svg/flutter_svg.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _bounceAnimation;

  @override
  void initState() {
    super.initState();

    // Animation for the bounce effect on the swipe text
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _bounceAnimation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _navigateToLogin() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 800),
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          const begin = Offset(0.0, 1.0);
          const end = Offset.zero;
          const curve = Curves.easeOutQuart;

          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
          var offsetAnimation = animation.drive(tween);

          return SlideTransition(
            position: offsetAnimation,
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color themeNavy = Color(0xFF1A4789);
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: themeNavy,
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Column(
            children: [
              // Top Section: Illustration
              // On small screens (Vivo), we give it less room to prevent squashing text below
              Expanded(
                flex: screenHeight < 700 ? 4 : 5,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(50, 60, 50, 20),
                  child: SvgPicture.asset(
                    'assets/images/login_illustration.svg',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              // Bottom Section: The White Card
              Expanded(
                flex: screenHeight < 700 ? 6 : 5,
                child: GestureDetector(
                  // Improved swipe detection for both slow and fast swipes
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < -100) {
                      _navigateToLogin();
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 30),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(50),
                        topRight: Radius.circular(50),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Text Content
                        Column(
                          children: [
                            const Text(
                              "PLANOVA",
                              style: TextStyle(
                                fontSize: 38, // Slightly smaller for better fit
                                fontWeight: FontWeight.w900,
                                color: themeNavy,
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 15),
                            Text(
                              "Let's Get You Set Up for Success",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: screenHeight < 700 ? 20 : 24, // Adaptive font
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 15),
                            const Text(
                              "Organize your workflow and manage tasks easily with our simple-powerful app.",
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey, fontSize: 14),
                            ),
                          ],
                        ),

                        // Animated Swipe Indicator
                        AnimatedBuilder(
                          animation: _bounceAnimation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset(0, -_bounceAnimation.value),
                              child: Column(
                                children: [
                                  const Icon(
                                      Icons.keyboard_double_arrow_up_rounded,
                                      color: themeNavy,
                                      size: 35
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    "Swipe up to get started",
                                    style: TextStyle(
                                      color: themeNavy.withOpacity(0.7),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  // Bottom safety padding for modern phones (Poco)
                                  const SizedBox(height: 10),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}