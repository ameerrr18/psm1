import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // --- Logic to Generate Sequential ID ---
  Future<String> _generateCustomId() async {
    final counterRef = FirebaseFirestore.instance.collection('metadata').doc('user_counter');

    return await FirebaseFirestore.instance.runTransaction((transaction) async {
      DocumentSnapshot snapshot = await transaction.get(counterRef);

      if (!snapshot.exists) {
        // Fallback if document doesn't exist
        transaction.set(counterRef, {'current_count': 1});
        return "UID_0001";
      }

      int newCount = (snapshot.get('current_count') as int) + 1;
      transaction.update(counterRef, {'current_count': newCount});

      // Formats the number to be 4 digits (e.g., 1 -> 0001)
      String formattedNumber = newCount.toString().padLeft(4, '0');
      return "UID_$formattedNumber";
    });
  }

  Future<void> _handleSignup() async {
    final username = _usernameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (username.isEmpty || email.isEmpty || password.isEmpty) {
      _showSnackBar("Please fill in all fields");
      return;
    }

    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create Auth User
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 2. Generate the Sequential Custom ID
      String customId = await _generateCustomId();

      // 3. Store in Firestore using the customId as the Document Name
      await FirebaseFirestore.instance.collection('users').doc(customId).set({
        'uid': userCredential.user!.uid, // Still keep the Firebase Auth UID for reference
        'custom_id': customId,           // This is your UID_0001
        'username': username,
        'email': email,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.updateDisplayName(username);

      if (mounted) {
        _showSnackBar("Account created: $customId");
        Navigator.pop(context);
      }
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Authentication failed");
    } catch (e) {
      _showSnackBar("Error: ${e.toString()}");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
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
                          duration: const Duration(milliseconds: 300),
                          height: isKeyboardOpen ? 10 : 50,
                        ),
                        AnimatedOpacity(
                          duration: const Duration(milliseconds: 300),
                          opacity: isKeyboardOpen ? 0.0 : 1.0,
                          child: isKeyboardOpen ? const SizedBox.shrink() : _buildHeader(),
                        ),
                        const SizedBox(height: 20),
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
                            "Sign up",
                            style: TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w900,
                              color: primaryNavy,
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 8),
                          _buildLoginRedirect(),
                          const SizedBox(height: 30),
                          _buildTextField(
                            controller: _usernameController,
                            icon: Icons.person_outline,
                            hint: "Username",
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _emailController,
                            icon: Icons.email_outlined,
                            hint: "Email Address",
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _passwordController,
                            icon: Icons.lock_outline,
                            hint: "Password",
                            isPassword: true,
                            obscure: _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 15),
                          _buildTextField(
                            controller: _confirmPasswordController,
                            icon: Icons.lock_outline,
                            hint: "Confirm Password",
                            isPassword: true,
                            obscure: _obscurePassword,
                            onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          const SizedBox(height: 30),
                          _isLoading
                              ? const CircularProgressIndicator(color: primaryNavy)
                              : _buildActionButton("Sign up", primaryNavy, _handleSignup),
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

  // --- UI Helpers remain the same ---
  Widget _buildBackgroundDecoration() {
    return Positioned(
      top: -30, right: -20,
      child: Opacity(
        opacity: 0.15,
        child: Container(
          width: 150, height: 150,
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
          "Create Your Account\nand Simplify Your\nWorkday",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
            height: 1.2,
          ),
        ),
      ),
    );
  }

  Widget _buildLoginRedirect() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("Already have an account? ", style: TextStyle(color: Colors.grey, fontSize: 14)),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Text(
            "Log in",
            style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold, fontSize: 14),
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
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: isPassword ? obscure : false,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey, size: 22),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: Colors.grey,
            size: 20,
          ),
          onPressed: onToggle,
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