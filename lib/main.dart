
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shishra/firebase_options.dart';
import 'package:shishra/globals/app_state.dart';
import 'package:shishra/pages/splash_screen.dart';
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
      ),
    );
  }
}
