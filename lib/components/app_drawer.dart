
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shishra/pages/auth_page.dart';
import 'package:shishra/pages/cart_page.dart';
import 'package:shishra/pages/contact_us_page.dart';
import 'package:shishra/pages/orders_page.dart';
import 'package:shishra/pages/profile_page.dart';
import 'package:shishra/pages/settings_page.dart';
import 'package:shishra/pages/wishlist_page.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(context, user),
          _buildDrawerItem(context, 'Home', Icons.home_outlined, () {
            Navigator.pop(context); // Close drawer
          }),
          _buildDrawerItem(context, 'Shop by Category', Icons.category_outlined, () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/advanced-search');
          }),
          _buildDrawerItem(context, 'Shop by Occasion', Icons.event_outlined, () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/advanced-search');
          }),
          _buildDrawerItem(context, 'Shop by Price Range', Icons.price_change_outlined, () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/advanced-search');
          }),
          _buildDrawerItem(context, 'Gifting Guide', Icons.card_giftcard_outlined, () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/advanced-search');
          }),
          const Divider(),
          _buildDrawerItem(context, 'Orders', Icons.receipt_long_outlined, () {
            Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const OrdersPage()));
          }),
          _buildDrawerItem(context, 'Wishlist', Icons.favorite_border, () {
             Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const WishlistPage()));
          }),
          _buildDrawerItem(context, 'Cart', Icons.shopping_cart_outlined, () {
             Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const CartPage()));
          }),
          _buildDrawerItem(context, 'Profile', Icons.person_outline, () {
             Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
          }),
          const Divider(),
          _buildDrawerItem(context, 'About Us', Icons.info_outline, () {
            Navigator.pop(context);
            Navigator.pushNamed(context, '/about');
          }),
          _buildDrawerItem(context, 'Contact / Customer Support', Icons.headset_mic_outlined, () {
             Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactUsPage()));
          }),
          const SizedBox(height: 40),
          _buildBottomSection(context, user),
        ],
      ),
    );
  }

  Widget _buildDrawerHeader(BuildContext context, User? user) {
    if (user != null) {
      return UserAccountsDrawerHeader(
        accountName: Text(user.displayName ?? 'Shishra User'),
        accountEmail: Text(user.phoneNumber ?? ''),
        currentAccountPicture: CircleAvatar(
          backgroundColor: Colors.white,
          child: Text(
            user.displayName?.substring(0, 1) ?? 'S',
            style: const TextStyle(fontSize: 40.0, color: Colors.black),
          ),
        ),
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
      );
    } else {
      return DrawerHeader(
        decoration: const BoxDecoration(
          color: Colors.black,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Welcome to Shishira',
              style: TextStyle(color: Colors.white, fontSize: 24),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const AuthPage()),
                );
              },
              child: const Text('Login / Signup'),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDrawerItem(
      BuildContext context, String title, IconData icon, VoidCallback onTap) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  Widget _buildBottomSection(BuildContext context, User? user) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/contact');
            }, icon: const Icon(Icons.camera_alt_outlined)), // Instagram
            IconButton(onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/help');
            }, icon: const Icon(Icons.chat_bubble_outline)), // WhatsApp
          ],
        ),
        if (user != null)
          _buildDrawerItem(context, 'Settings', Icons.settings_outlined, () {
             Navigator.pop(context);
            Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsPage()));
          }),
        if (user != null)
          _buildDrawerItem(context, 'Logout', Icons.logout, () async {
            await FirebaseAuth.instance.signOut();
            if (!context.mounted) return;
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const AuthPage()),
              (route) => false,
            );
          }),
      ],
    );
  }
}
