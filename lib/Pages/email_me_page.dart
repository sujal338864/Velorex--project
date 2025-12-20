
import 'package:flutter/material.dart';
import 'package:Velorex/utils/routes.dart';

class EmailMePage extends StatefulWidget {
  const EmailMePage({Key? key}) : super(key: key);

  @override
  _EmailMePageState createState() => _EmailMePageState();
}

class _EmailMePageState extends State<EmailMePage> {
  final _formKey = GlobalKey<FormState>();
  String email = "hh";
  bool isSubmitted = false;

  void submitEmail() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isSubmitted = true;
      });

      // Simulate email sending delay
      Future.delayed(Duration(seconds: 2), () {
        Navigator.pushNamed(context, AllRoutes.profileRoute);
 // Redirect to home or a success page
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Reset Password"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: isSubmitted
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle_outline, color: Colors.green, size: 80),
                    SizedBox(height: 20),
                    Text(
                      "An email has been sent to $email with password reset instructions.",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                  ],
                ),
              )
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Enter your registered email address to reset your password",
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your email';
                        } else if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
                          return 'Please enter a valid email';
                        }
                        return null;
                      },
                      onChanged: (value) {
                        email = value;
                      },
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: submitEmail,
                      child: Text("Send Reset Link"),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
