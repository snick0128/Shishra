import 'package:flutter/material.dart';
import 'package:shishra/globals/app_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w400,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SettingsTile(
            title: 'Account',
            icon: Icons.person_outline,
            onTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            title: 'Notifications',
            icon: Icons.notifications_none,
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            title: 'Theme',
            icon: Icons.brightness_6_outlined,
            onTap: () => AppState.of(context, listen: false).toggleTheme(),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            title: 'Help & Support',
            icon: Icons.help_outline,
            onTap: () => Navigator.pushNamed(context, '/help'),
          ),
          const SizedBox(height: 8),
          _SettingsTile(
            title: 'About',
            icon: Icons.info_outline,
            onTap: () => Navigator.pushNamed(context, '/about'),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;

  const _SettingsTile({required this.title, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.black),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.black),
        onTap: onTap,
      ),
    );
  }
}
