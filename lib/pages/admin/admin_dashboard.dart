import 'package:flutter/material.dart';
import 'package:shishra/services/admin_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/pages/admin/admin_orders.dart';
import 'package:shishra/pages/admin/admin_products.dart';
import 'package:shishra/pages/admin/admin_users.dart';
import 'package:shishra/pages/admin/admin_settings.dart';
import 'package:shishra/pages/login_page.dart';
import 'package:shishra/utils/responsive_layout.dart';
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

  Widget _buildSidebar(BuildContext context) {
    return Container(
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
                  margin:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSelected ? tab.color.withOpacity(0.1) : null,
                    borderRadius: BorderRadius.circular(8),
                    border: isSelected
                        ? Border.all(color: tab.color.withOpacity(0.3))
                        : null,
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
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () => _onTabTapped(index),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
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
        leading: ResponsiveLayout.isDesktop(context)
            ? null
            : Builder(
                builder: (context) => IconButton(
                    icon: const Icon(Icons.menu),
                    onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(
            onPressed: _exitAdminMode,
            icon: const Icon(Icons.exit_to_app, color: Colors.red),
            tooltip: 'Exit Admin Mode',
          ),
        ],
      ),
      drawer: ResponsiveLayout.isDesktop(context)
          ? null
          : Drawer(child: _buildSidebar(context)),
      body: SafeArea(
        child: ResponsiveLayout.isDesktop(context)
            ? Row(
                children: [
                  _buildSidebar(context),
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
              )
            : PageView(
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
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: ResponsiveLayout.getResponsiveGridCount(context),
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.5,
              ),
              itemCount: 4,
              itemBuilder: (context, index) {
                final List<Widget> children = [
                  _buildStreamedOverviewCard(
                    title: 'Total Orders',
                    icon: Icons.shopping_bag,
                    color: Colors.green,
                    stream: FirebaseFirestore.instance.collectionGroup('orders').snapshots(),
                    builder: (snapshot) => snapshot.data != null
                        ? snapshot.data!.docs.length.toString()
                        : '0',
                  ),
                  _buildStreamedOverviewCard(
                    title: 'Products',
                    icon: Icons.inventory,
                    color: Colors.orange,
                    stream: FirebaseFirestore.instance.collection('products').snapshots(),
                    builder: (snapshot) => snapshot.data != null
                        ? snapshot.data!.docs.length.toString()
                        : '0',
                  ),
                  _buildStreamedOverviewCard(
                    title: 'Customers',
                    icon: Icons.people,
                    color: Colors.purple,
                    stream: FirebaseFirestore.instance.collection('users').snapshots(),
                    builder: (snapshot) => snapshot.data != null
                        ? snapshot.data!.docs.length.toString()
                        : '0',
                  ),
                  _buildStreamedOverviewCard(
                    title: 'Revenue',
                    icon: Icons.currency_rupee,
                    color: Colors.blue,
                    stream: FirebaseFirestore.instance
                        .collectionGroup('orders')
                        .where('status', whereIn: ['Confirmed', 'Shipped', 'Delivered'])
                        .snapshots(),
                    builder: (snapshot) {
                      if (!snapshot.hasData) return '0';
                      double totalRevenue = 0;
                      for (var doc in snapshot.data!.docs) {
                        final data = doc.data() as Map<String, dynamic>;
                        if (data.containsKey('total')) {
                          totalRevenue += (data['total'] as num).toDouble();
                        }
                      }
                      return '₹${totalRevenue.toStringAsFixed(0)}';
                    },
                  ),
                ];
                return children[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreamedOverviewCard({
    required String title,
    required IconData icon,
    required Color color,
    required Stream<QuerySnapshot<Map<String, dynamic>>> stream,
    required String Function(AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) builder,
  }) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        String value = '...';
        if (snapshot.connectionState == ConnectionState.active && snapshot.hasData) {
          value = builder(snapshot);
        } else if (snapshot.hasError) {
          value = 'Error';
        }

        return _buildOverviewCard(
          title: title,
          value: value,
          icon: icon,
          color: color,
          isLoading: snapshot.connectionState == ConnectionState.waiting,
        );
      },
    );
  }

  Widget _buildOverviewCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    bool isLoading = false,
    String? growth,
  }) {
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
                if (growth != null) ...[
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
              ],
            ),
            const SizedBox(height: 12),
            isLoading
                ? const SizedBox(
                    height: 28,
                    width: 28,
                    child: CircularProgressIndicator(strokeWidth: 3))
                : Text(
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
