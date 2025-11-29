import 'package:flutter/material.dart';
import 'package:one_solution/Pages/account_page.dart';
import 'package:one_solution/Pages/home_page.dart';
import 'package:one_solution/Pages/cart_page.dart';
import 'package:one_solution/Pages/categories_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MainNavigationPage extends StatefulWidget {
  const MainNavigationPage({super.key});

  @override
  State<MainNavigationPage> createState() => _MainNavigationPageState();
}

class _MainNavigationPageState extends State<MainNavigationPage> {
  int _currentIndex = 0;
  String? userId;
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    userId = user?.id;
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _pages = [
      const HomePage(),
       CategoryPage(userId: userId ?? ''),
      CartPage(userId: userId ?? ''),
      AccountPage(userId: userId ?? ''), // ✅ fixed
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              // ignore: deprecated_member_use
              color: Colors.black.withOpacity(0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color.fromARGB(255, 255, 66, 66),
          unselectedItemColor: const Color.fromARGB(255, 104, 87, 87),
          showUnselectedLabels: true,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.category_outlined),
              activeIcon: Icon(Icons.category),
              label: "Categories",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: "Cart",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: "You",
            ),
          ],
        ),
      ),
    );
  }
}
