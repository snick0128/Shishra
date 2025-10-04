import 'package:firebase_auth/firebase_auth.dart';
import 'package:shishra/pages/login_page.dart';
import 'package:shishra/pages/main_navigation.dart';
import 'package:flutter/material.dart';

class AuthPage extends StatelessWidget {
  const AuthPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const MainNavigation();
          } else {
            return const LoginPage();
          }
        },
      ),
    );
  }
}