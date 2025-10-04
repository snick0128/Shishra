import 'package:flutter/material.dart';
import 'package:shishra/pages/home_page.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {

  @override
  Widget build(BuildContext context) {
    // Drawer-only layout: show HomePage, navigation happens via the Drawer
    return const HomePage();
  }
}
