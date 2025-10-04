import 'package:flutter/material.dart';
import 'package:shishra/services/admin_service.dart';
import 'package:shishra/pages/admin/admin_orders.dart';
import 'package:shishra/pages/admin/admin_products.dart';
import 'package:shishra/pages/admin/admin_users.dart';
import 'package:shishra/pages/admin/admin_settings.dart';
import 'package:shishra/pages/login_page.dart';
import 'package:another_flushbar/flushbar.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final AdminService _adminService = AdminService();
  final PageController _pageController = PageController();
  int _selectedIndex = 0;

  final List<AdminDashboardTab> _tabs = [
    AdminDashboardTab(
      title: 'Dashboard',
      icon: Icons.dashboard,
      color: Colors.blue,
    ),
    AdminDashboardTab(
      title: 'Orders',
      icon: Icons.shopping_bag,
      color: Colors.green,
    ),
    AdminDashboardTab(
      title: 'Products',
      icon: Icons.inventory,
      color: Colors.orange,
    ),
    AdminDashboardTab(
      title: 'Users',
      icon: Icons.people,
      color: Colors.purple,
    ),
    AdminDashboardTab(
      title: 'Settings',
      icon: Icons.settings,
      color: Colors.red,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _exitAdminMode() async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit Admin Mode'),
        content: const Text('Are you sure you want to exit admin mode?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Exit', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      await _adminService.removeAdminAccess();
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
        );
      }
    }
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.TOP,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    ).show(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Admin Panel'),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: const Text(
                'ADMIN MODE',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            onPressed: _exitAdminMode,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Exit Admin Mode',
          ),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 250,
            color: Colors.grey.shade50,
            child: Column(
              children: [
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: _tabs.length,
                    itemBuilder: (context, index) {
                      final tab = _tabs[index];
                      final isSelected = _selectedIndex == index;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: isSelected ? tab.color.withOpacity(0.1) : null,
                          borderRadius: BorderRadius.circular(8),
                          border: isSelected ? Border.all(color: tab.color.withOpacity(0.3)) : null,
                        ),
                        child: ListTile(
                          leading: Icon(
                            tab.icon,
                            color: isSelected ? tab.color : Colors.grey.shade600,
                          ),
                          title: Text(
                            tab.title,
                            style: TextStyle(
                              color: isSelected ? tab.color : Colors.grey.shade700,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                          onTap: () => _onTabTapped(index),
                        ),
                      );
                    },
                  ),
                ),
                const Divider(),
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Admin Tools',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Manage your jewellery store',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _selectedIndex = index;
                });
              },
              children: [
                AdminOverview(onShowMessage: _showSuccessMessage),
                const AdminOrdersPage(),
                const AdminProductsPage(),
                const AdminUsersPage(),
                const AdminSettingsPage(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AdminDashboardTab {
  final String title;
  final IconData icon;
  final Color color;

  AdminDashboardTab({
    required this.title,
    required this.icon,
    required this.color,
  });
}

class AdminOverview extends StatelessWidget {
  final Function(String) onShowMessage;

  const AdminOverview({super.key, required this.onShowMessage});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Dashboard Overview',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage your SHISHRA jewellery store',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.5,
              children: [
                _buildOverviewCard(
                  'Total Orders',
                  '124',
                  Icons.shopping_bag,
                  Colors.green,
                  '+12%',
                ),
                _buildOverviewCard(
                  'Products',
                  '45',
                  Icons.inventory,
                  Colors.orange,
                  '+5%',
                ),
                _buildOverviewCard(
                  'Customers',
                  '89',
                  Icons.people,
                  Colors.purple,
                  '+8%',
                ),
                _buildOverviewCard(
                  'Revenue',
                  '₹2,34,567',
                  Icons.currency_rupee,
                  Colors.blue,
                  '+15%',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewCard(
    String title,
    String value,
    IconData icon,
    Color color,
    String growth,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    growth,
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}