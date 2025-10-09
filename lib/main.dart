
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shishra/firebase_options.dart';
import 'package:shishra/globals/app_state.dart';
import 'package:shishra/pages/splash_screen.dart';
import 'package:shishra/pages/advanced_search_page.dart';
import 'package:shishra/firestore_service.dart';
import 'package:shishra/services/admin_service.dart';

late SharedPreferences sharedPrefs;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  sharedPrefs = await SharedPreferences.getInstance();

  // Seed the database if it's empty.
  // This is a one-time operation.
  await FirestoreService().seedInitialDatabase();

  // Initialize admin settings
  await AdminService().initializeAdminSettings();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AppState>(
      create: (context) => AppState(),
      builder: (context, child) => MaterialApp(
        title: 'SHISHRA - Premium Jewelry',
        theme: AppState.of(context).theme,
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
        routes: {
          '/advanced-search': (context) => const AdvancedSearchPage(),
          '/profile': (context) => Scaffold(
            appBar: AppBar(title: const Text('Profile')),
            body: const Center(child: Text('Profile Page - Coming Soon')),
          ),
          '/help': (context) => Scaffold(
            appBar: AppBar(title: const Text('Help & Support')),
            body: const Center(child: Text('Help & Support - Coming Soon')),
          ),
          '/about': (context) => Scaffold(
            appBar: AppBar(title: const Text('About Us')),
            body: const Center(child: Text('About Us - Coming Soon')),
          ),
          '/contact': (context) => Scaffold(
            appBar: AppBar(title: const Text('Contact Us')),
            body: const Center(child: Text('Contact Us - Coming Soon')),
          ),
          '/cart': (context) => Scaffold(
            appBar: AppBar(title: const Text('Cart')),
            body: const Center(child: Text('Cart Page - Coming Soon')),
          ),
        },
      ),
    );
  }
}
