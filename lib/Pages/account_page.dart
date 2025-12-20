
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
// import 'package:one_solution/Pages/OrdersPage.dart';
// import 'package:one_solution/Pages/help_page.dart';
// import 'package:one_solution/Pages/profile_page.dart';
// import 'package:one_solution/Pages/user_notification_page.dart';
// import 'package:one_solution/main.dart';
// import 'package:one_solution/utils/routes.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:Velorex/Pages/OrdersPage.dart';
import 'package:Velorex/Pages/help_page.dart';
import 'package:Velorex/Pages/profile_page.dart';
import 'package:Velorex/Pages/user_notification_page.dart';
import 'package:Velorex/main.dart';
import 'package:Velorex/utils/routes.dart';

class AccountPage extends StatefulWidget {
  final String? userId;

  const AccountPage({super.key, this.userId});

  @override
  State<AccountPage> createState() => _AccountPageState();
}

class _AccountPageState extends State<AccountPage> {
  String? userName;
  String? userEmail;
  String? userImage;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() {
        userName = user.userMetadata?['full_name'] ?? 'Valued User';
        userEmail = user.email;
        userImage = user.userMetadata?['avatar_url'] ??
            'https://i.pravatar.cc/150?img=3'; // Default avatar
      });
    }
  }

  Future<void> logoutUser(BuildContext context) async {
    showDialog(
      context: navigatorKey.currentContext!,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: Colors.redAccent),
      ),
    );

    try {
      await Supabase.instance.client.auth.signOut();
      navigatorKey.currentState?.pop();

      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AllRoutes.loginRoute,
        (route) => false,
      );

      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        const SnackBar(
          content: Text("Logged out successfully."),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      navigatorKey.currentState?.pop();
      ScaffoldMessenger.of(navigatorKey.currentContext!).showSnackBar(
        SnackBar(
          content: Text("Logout failed: $e"),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> confirmLogout(BuildContext context) async {
    final shouldLogout = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text("Logout Confirmation"),
        content: const Text("Are you sure you want to log out?"),
        actions: [
          CupertinoDialogAction(
            child: const Text("Cancel"),
            onPressed: () => Navigator.pop(context, false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text("Logout"),
            onPressed: () => Navigator.pop(context, true),
          ),
        ],
      ),
    );

    if (shouldLogout == true) {
      await logoutUser(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F1F5),
      appBar: AppBar(
        title: const Text(
          "My Account",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // 🔹 Profile Header Card
          Container(
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundImage: NetworkImage(
                    userImage ?? 'https://i.pravatar.cc/150?img=3',
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName ?? "Loading...",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      userEmail ?? "Loading...",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Menu Items
          _buildMenuItem(
            context,
            icon: CupertinoIcons.home,
            title: "Home",
            onTap: () {
              Navigator.pushNamed(context, AllRoutes.homeRoute);
            },
          ),
          _buildMenuItem(
            context,
            icon: Icons.shopping_bag,
            title: "My Orders",
            onTap: () {
              if (widget.userId != null && widget.userId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrdersPage(userId: widget.userId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please log in first")),
                );
              }
            },
          ),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.person_crop_circle,
            title: "My Profile",
            onTap: () {
              if (widget.userId != null && widget.userId!.isNotEmpty) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfilePage(userId: widget.userId!),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Please log in first")),
                );
              }
            },
          ),
          _buildMenuItem(
  context,
  icon: Icons.notifications_active_outlined,
  title: "My Notifications",
  onTap: () {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => UserNotificationPage(userId: user.id), // ✅ Pass real userId from Supabase
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please log in to view notifications")),
      );
    }
  },
),

          _buildMenuItem(
            context,
            icon: Icons.help_outline,
            title: "Help & Support",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              );
            },
          ),
          const Divider(thickness: 1, color: Colors.black12, height: 32),
          _buildMenuItem(
            context,
            icon: CupertinoIcons.arrow_right_square,
            title: "Logout",
            color: Colors.redAccent,
            onTap: () => confirmLogout(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem(BuildContext context,
      {required IconData icon,
      required String title,
      required VoidCallback onTap,
      Color color = Colors.black}) {
    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          title,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
        onTap: onTap,
      ),
    );
  }
}
