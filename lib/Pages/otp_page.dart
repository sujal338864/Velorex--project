
import 'package:flutter/material.dart';
import 'package:Velorex/Pages/home_page.dart';

import '../services/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OtpPage extends StatefulWidget {
  final String contact;
  const OtpPage({super.key, required this.contact});

  @override
  State<OtpPage> createState() => _OtpPageState();
}

class _OtpPageState extends State<OtpPage> {
  final TextEditingController _otpController = TextEditingController();
  bool _loading = false;
 // ADD THIS import

void _verifyOtp() async {
  final otp = _otpController.text.trim();
  if (otp.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Please enter OTP")),
    );
    return;
  }

  setState(() => _loading = true);

  try {
    final res = await ApiService.verifyOtp(widget.contact, otp);

    if (res["message"] == "OTP verified successfully" || res["success"] == true) {
      // ✅ Save login session
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("✅ OTP Verified Successfully")),
      );

      // 🔹 Navigate to Home
      Future.delayed(const Duration(milliseconds: 800), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
        );
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res["message"] ?? "Invalid OTP")),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error verifying OTP: $e")),
    );
  } finally {
    setState(() => _loading = false);
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Verify OTP")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("OTP sent to ${widget.contact}", textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: "Enter OTP",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
           ElevatedButton(
  onPressed: _loading ? null : _verifyOtp,
  child: _loading
      ? const CircularProgressIndicator(color: Colors.white)
      : const Text("Verify OTP"),
),

          ],
        ),
      ),
    );
  }
}
