import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:planova/main_wrapper.dart';
import 'package:planova/utils/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'signup_page.dart';
import 'forgot_password_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _userInputController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAutoLogin());
  }

  Future<void> _checkAutoLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final bool rememberMe = prefs.getBool('remember_me') ?? false;
    final user = FirebaseAuth.instance.currentUser;

    if (rememberMe && user != null && mounted) {
      _navigateToDashboard();
    }
  }

  Future<void> _handleLogin() async {
    String input = _userInputController.text.trim();
    String password = _passwordController.text.trim();

    if (input.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    setState(() => _isLoading = true);

    try {
      String email = input;
      // 1. Handle Username to Email conversion
      if (!input.contains('@')) {
        final querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('username', isEqualTo: input)
            .limit(1)
            .get();

        if (querySnapshot.docs.isEmpty) {
          _showSnackBar("Username not found");
          setState(() => _isLoading = false);
          return;
        }
        email = querySnapshot.docs.first.get('email');
      }

      // 2. Firebase Authentication
      UserCredential userCredential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (userCredential.user != null) {
        final String uid = userCredential.user!.uid;
        final activityColl = FirebaseFirestore.instance.collection('user_activity');

        // 3. Record Login Activity
        await activityColl.add({
          'userId': uid,
          'type': 'LOGIN',
          'timestamp': FieldValue.serverTimestamp(),
          'deviceName': 'Mobile Device',
        });

        // 4. Purge logs (Keep only 4 latest)
        final logs = await activityColl
            .where('userId', isEqualTo: uid)
            .orderBy('timestamp', descending: true)
            .get();

        if (logs.docs.length > 4) {
          for (var i = 4; i < logs.docs.length; i++) {
            await activityColl.doc(logs.docs[i].id).delete();
          }
        }

        if (mounted) {
          // 5. Save "Remember Me" preference
          final prefs = await SharedPreferences.getInstance();
          await prefs.setBool('remember_me', _rememberMe);

          // 6. Direct Navigation to Dashboard
          _navigateToDashboard();
        }
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Authentication failed");
    } catch (e) {
      _showSnackBar("An unexpected error occurred");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _navigateToDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MainWrapper()),
          (route) => false,
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryNavy = Color(0xFF1A4789);
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardOpen = keyboardHeight > 0;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: primaryNavy,
        resizeToAvoidBottomInset: false,
        body: Stack(
          children: [
            _buildBackgroundDecoration(),
            SafeArea(
              child: CustomScrollView(
                physics: const ClampingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          height: isKeyboardOpen ? 10 : 60,
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isKeyboardOpen ? 0.0 : 1.0,
                          child: isKeyboardOpen ? const SizedBox.shrink() : _buildHeader(),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.only(
                        left: 30,
                        right: 30,
                        top: 40,
                        bottom: isKeyboardOpen ? keyboardHeight + 30 : 40,
                      ),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(50)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            "Login",
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: primaryNavy,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildSignupRedirect(),
                          const SizedBox(height: 40),
                          _buildTextField(
                            controller: _userInputController,
                            icon: Icons.person_outline,
                            hint: "Email or Username",
                          ),
                          const SizedBox(height: 20),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: "Password",
                            isPassword: true,
                          ),
                          const SizedBox(height: 10),
                          _buildRememberMeAndForgot(primaryNavy),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator(color: primaryNavy)
                              : _buildActionButton("Login", primaryNavy, _handleLogin),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -50,
      right: -50,
      child: Opacity(
        opacity: 0.2,
        child: Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          "Log in to stay on\ntop of your tasks\nand projects.",
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildSignupRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupPage())),
          child: const Text(
            "Sign up",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  Widget _buildRememberMeAndForgot(Color primaryNavy) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            SizedBox(
              height: 24,
              width: 24,
              child: Checkbox(
                value: _rememberMe,
                activeColor: primaryNavy,
                onChanged: (v) => setState(() => _rememberMe = v!),
              ),
            ),
            const SizedBox(width: 8),
            const Text("Remember Me", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ],
        ),
        TextButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordPage())),
          child: const Text(
            "Forgot Password?",
            style: TextStyle(color: AppColors.primaryBlue, fontSize: 13),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    bool isPassword = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? !_isPasswordVisible : false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        )
            : null,
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF3F6F9),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _buildActionButton(String label, Color color, VoidCallback onPressed) {
    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          elevation: 0,
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}