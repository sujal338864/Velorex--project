import 'package:flutter/material.dart';
import 'package:one_solution/services/profile_services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ProfilePage extends StatefulWidget {
  final String userId;

  const ProfilePage({super.key, required this.userId}); // ✅ must be defined

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  Map<String, dynamic>? userData;
  bool loading = true;
  bool saving = false;

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final mobileController = TextEditingController();
  final addressController = TextEditingController();
  final cityController = TextEditingController();
  final stateController = TextEditingController();
  final countryController = TextEditingController();
  final pincodeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchProfile();
  }

 Future<void> fetchProfile() async {
  try {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final profile = await ProfileService.getUserProfile(user.id);

    if (profile == null) {
      // First login → create new
      await ProfileService.createUserProfile({
        'userId': user.id,
        'email': user.email,
        'name': user.userMetadata?['full_name'] ?? '',
        'mobile': '',
        'address': '',
        'city': '',
        'state': '',
        'country': '',
        'pincode': '',
      });
      userData = await ProfileService.getUserProfile(user.id);
    } else {
      // Returning user → load existing
      userData = profile;
    }

    setState(() {
      nameController.text = userData?['name'] ?? '';
      emailController.text = user.email ?? '';
      mobileController.text = userData?['mobile'] ?? '';
      addressController.text = userData?['address'] ?? '';
      cityController.text = userData?['city'] ?? '';
      stateController.text = userData?['state'] ?? '';
      countryController.text = userData?['country'] ?? '';
      pincodeController.text = userData?['pincode'] ?? '';
      loading = false;
    });
  } catch (e) {
    setState(() => loading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error loading profile: $e")),
    );
  }
}

  Future<void> saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => saving = true);

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) throw Exception("User not logged in");

      final data = {
        'name': nameController.text,
        'email': emailController.text,
        'mobile': mobileController.text,
        'address': addressController.text,
        'city': cityController.text,
        'state': stateController.text,
        'country': countryController.text,
        'pincode': pincodeController.text,
      };

      await ProfileService.updateUserProfile(user.id, data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profile updated successfully!")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to update: $e")),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("My Profile")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              buildTextField("Name", nameController),
              buildTextField("Email", emailController, readOnly: true),
              buildTextField("Mobile", mobileController),
              buildTextField("Address", addressController),
              buildTextField("City", cityController),
              buildTextField("State", stateController),
              buildTextField("Country", countryController),
              buildTextField("Pincode", pincodeController),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                icon: saving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Icon(Icons.save),
                label: const Text("Save Changes"),
                onPressed: saving ? null : saveProfile,
              ),
                  const SizedBox(height: 12),

    OutlinedButton.icon(
      icon: const Icon(Icons.home_outlined),
      label: const Text("Go to Home"),
      onPressed: () {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/home', // 🔁 Make sure this matches your home route name
          (route) => false,
          );
            }
    )
             ],
          ),
        ),
      ),
    );
  }

  Widget buildTextField(String label, TextEditingController controller,
      {bool readOnly = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            (value == null || value.isEmpty) ? "Required field" : null,
      ),
    );
  }
}
