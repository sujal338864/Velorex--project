import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:one_solution/Pages/main_navigation_page.dart';
import 'package:one_solution/Pages/profile_page.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:one_solution/widgets/theme.dart';
import 'package:one_solution/utils/routes.dart';
// Pages
import 'package:one_solution/Pages/home_page.dart';
import 'package:one_solution/Pages/login_page.dart';
import 'package:one_solution/Pages/signup_page.dart';
import 'package:one_solution/Pages/WishlistPage.dart';
import 'package:one_solution/Pages/cart_page.dart';
import 'package:one_solution/Pages/email_me_page.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    print("🔴 Flutter framework error: ${details.exception}");
    print(details.stack);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    print("🔥 Uncaught platform error: $error");
    print(stack);
    return true;
  };

  await Supabase.initialize(
    url: 'https://zyryndjeojrzvoubsqsg.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inp5cnluZGplb2pyenZvdWJzcXNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTc3MzEyOTYsImV4cCI6MjA3MzMwNzI5Nn0.t8cnVhusOVzJRe3YEUFnpp8UtiCvDSnILueuz2hJrls',
    debug: true,
  );

  final results = await Future.wait([
    SharedPreferences.getInstance(),
    Future.delayed(const Duration(milliseconds: 200)), 
  ]);

  final prefs = results[0] as SharedPreferences;
  final session = Supabase.instance.client.auth.currentSession;
  final isLoggedIn = session != null;
  final phoneOrEmail = prefs.getString('phone_or_email');

  runApp(MyApp(isLoggedIn: isLoggedIn, phoneOrEmail: phoneOrEmail));

  Supabase.instance.client.auth.onAuthStateChange.listen((data) async {
    final session = data.session;
    final event = data.event;

    if (event == AuthChangeEvent.signedIn && session != null) {
      await prefs.setBool('isLoggedIn', true);
      navigatorKey.currentState?.pushNamedAndRemoveUntil(
        AllRoutes.profileRoute,
        (r) => false,
      );
    } 
  });
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  final String? phoneOrEmail;
  
  const MyApp({
    super.key,
    required this.isLoggedIn,
    this.phoneOrEmail,
    
     });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey, 
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.light,
      theme: MyTheme.lightTheme(context),
      darkTheme: MyTheme.darkTheme(context),
      initialRoute: isLoggedIn ? AllRoutes.profileRoute : AllRoutes.loginRoute,
      routes: {
AllRoutes.profileRoute: (context) {
  final prefs = SharedPreferences.getInstance();
  return FutureBuilder<SharedPreferences>(
    future: prefs,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      }

      final dynamic storedUserId = snapshot.data!.get('userId');
      final String userId = storedUserId?.toString() ?? '';

      return ProfilePage(userId: userId);
    },
  );
},

       AllRoutes.homeRoute: (context) => const HomePage(),
       AllRoutes.loginRoute: (context) => const LoginPage(),
       AllRoutes.homeRoute: (context) => const MainNavigationPage(),

        AllRoutes.signupRoute: (context) => const SignupPage(),
 AllRoutes.cartRoute: (context) {
  final args = ModalRoute.of(context)!.settings.arguments as Map;
  return CartPage(userId: args["userId"]);
},

        AllRoutes.emailmeRoute: (context) => const EmailMePage(),
        // AllRoutes.ordersRoute: (context) => const OrdersPage(),
AllRoutes.wishlistRoute: (context) {
  final args = ModalRoute.of(context)?.settings.arguments as String?;
  return WishlistPage(userId: args ?? '');
},

     },
    );
  }
}


