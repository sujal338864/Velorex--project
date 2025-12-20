// ignore_for_file: deprecated_member_use

import 'dart:ui';

import 'package:Velorex/services/api_service.dart';
import 'package:flutter/material.dart';

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final emailController = TextEditingController();
  bool loading = false;

  @override
  void initState() {
    super.initState();

    Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
      final session = data.session;
      if (session != null) {
        final user = session.user;
        final supabaseId = user.id;
        final email = user.email ?? '';
        final name = user.userMetadata?['name'] ?? email.split('@')[0];

        final userId = await ApiService.syncUser(supabaseId, email, name);
        if (userId != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('userId', user.id);
          await prefs.setString('email', user.email ?? '');
          if (mounted) Navigator.pushReplacementNamed(context, '/profile');
        }
      }
    });
  }

  Future<void> sendMagicLink() async {
    setState(() => loading = true);
    try {
      final email = emailController.text.trim();
      if (email.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Email cannot be empty")));
        return;
      }

      await Supabase.instance.client.auth.signInWithOtp(email: email);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Magic link sent! Check your email.")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> loginWithGoogle() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'io.supabase.flutter://login-callback/',
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Google login failed: $e")));
    }
  }

  Future<void> loginWithApple() async {
    try {
      await Supabase.instance.client.auth.signInWithOAuth(OAuthProvider.apple);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Apple login failed: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: Stack(
        children: [
          // 🌈 Subtle Gradient Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0E7FF), Color(0xFFFDFCFB), Color(0xFFDCEFFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // 🌫️ Glass Panel Center
          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(25),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
                child: Container(
                  width: 350,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(color: Colors.white.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        blurRadius: 30,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🌤️ Logo / Title
                      ShaderMask(
                        shaderCallback: (rect) => const LinearGradient(
                          colors: [Color(0xFF007BFF), Color(0xFF00C9A7)],
                        ).createShader(rect),
                        child: const Text(
                          " VeloreX",
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        "Welcome 👋",
                        style: TextStyle(
                          color: Colors.black.withOpacity(0.7),
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 30),

                      // ✉️ Email Input
                      TextField(
                        controller: emailController,
                        decoration: InputDecoration(
                          labelText: "Enter your email",
                          prefixIcon: const Icon(Icons.email_outlined,
                              color: Color(0xFF007BFF)),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.8),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide:
                                const BorderSide(color: Color(0xFFB0C4DE)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFF007BFF),
                              width: 1.5,
                            ),
                          ),
                        ),
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 25),

                      // 🔹 Magic Link Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: loading ? null : sendMagicLink,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF007BFF),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 5,
                          ),
                          child: loading
                              ? const CircularProgressIndicator(
                                  color: Colors.white)
                              : const Text(
                                  "Send Magic Link",
                                  style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                      const SizedBox(height: 25),

                      // 🔘 Divider
                      Row(
                        children: [
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.withOpacity(0.3),
                                  thickness: 1)),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Text(
                              "or continue with",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Expanded(
                              child: Divider(
                                  color: Colors.grey.withOpacity(0.3),
                                  thickness: 1)),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // 🌐 Social Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _socialButton(
                            icon: Icons.g_mobiledata,
                            color: Colors.redAccent,
                            onTap: loginWithGoogle,
                          ),
                          const SizedBox(width: 18),
                          _socialButton(
                            icon: Icons.apple,
                            color: Colors.black87,
                            onTap: loginWithApple,
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
                      Text(
                        "Powered by VeloreX",
                        style: TextStyle(
                            color: Colors.black.withOpacity(0.4),
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _socialButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 10,
              spreadRadius: 1,
            )
          ],
        ),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}
