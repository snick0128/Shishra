import 'package:flutter/material.dart';
import 'package:shishra/services/admin_service.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final AdminService _adminService = AdminService();
  bool _maintenanceMode = false;
  bool _allowNewRegistrations = true;
  bool _enableNotifications = true;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Admin Settings',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage app settings and configuration',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView(
              children: [
                _buildSettingsSection(
                  'App Settings',
                  [
                    _buildSwitchTile(
                      'Maintenance Mode',
                      'Temporarily disable customer access',
                      _maintenanceMode,
                      Icons.build,
                      (value) {
                        setState(() {
                          _maintenanceMode = value;
                        });
                        _showMaintenanceModeDialog(value);
                      },
                    ),
                    _buildSwitchTile(
                      'Allow New Registrations',
                      'Allow new customers to create accounts',
                      _allowNewRegistrations,
                      Icons.person_add,
                      (value) {
                        setState(() {
                          _allowNewRegistrations = value;
                        });
                      },
                    ),
                    _buildSwitchTile(
                      'Push Notifications',
                      'Send notifications to customers',
                      _enableNotifications,
                      Icons.notifications,
                      (value) {
                        setState(() {
                          _enableNotifications = value;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'Security',
                  [
                    _buildActionTile(
                      'Change Admin Password',
                      'Update admin access credentials',
                      Icons.lock_reset,
                      _changeAdminPassword,
                    ),
                    _buildActionTile(
                      'View Login Logs',
                      'Check admin access history',
                      Icons.history,
                      () => _showSnackBar('Login logs (Demo)'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'Store Information',
                  [
                    _buildActionTile(
                      'Store Details',
                      'Edit store name, address, contact info',
                      Icons.store,
                      () => _showStoreDetailsDialog(),
                    ),
                    _buildActionTile(
                      'Payment Settings',
                      'Configure payment methods',
                      Icons.payment,
                      () => _showSnackBar('Payment settings (Demo)'),
                    ),
                    _buildActionTile(
                      'Shipping Settings',
                      'Configure delivery options',
                      Icons.local_shipping,
                      () => _showSnackBar('Shipping settings (Demo)'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSettingsSection(
                  'Data & Analytics',
                  [
                    _buildActionTile(
                      'Export Data',
                      'Download orders, products, customers data',
                      Icons.download,
                      () => _showSnackBar('Data export started (Demo)'),
                    ),
                    _buildActionTile(
                      'Analytics Dashboard',
                      'View detailed sales analytics',
                      Icons.analytics,
                      () => _showSnackBar('Analytics (Demo)'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsSection(String title, List<Widget> children) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(
    String title,
    String subtitle,
    bool value,
    IconData icon,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.green,
      ),
    );
  }

  Widget _buildActionTile(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.arrow_forward_ios),
      onTap: onTap,
    );
  }

  void _showMaintenanceModeDialog(bool isEnabled) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isEnabled ? 'Enable Maintenance Mode' : 'Disable Maintenance Mode'),
        content: Text(
          isEnabled
              ? 'This will prevent customers from accessing the app. Only admin can access during maintenance.'
              : 'This will restore normal customer access to the app.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _maintenanceMode = !isEnabled;
              });
              Navigator.pop(context);
            },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar(
                isEnabled ? 'Maintenance mode enabled' : 'Maintenance mode disabled',
              );
            },
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _changeAdminPassword() {
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Admin Password'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: oldPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (newPasswordController.text != confirmPasswordController.text) {
                _showSnackBar('Passwords do not match');
                return;
              }
              
              final success = await _adminService.changeAdminPassword(
                oldPasswordController.text,
                newPasswordController.text,
              );
              
              Navigator.pop(context);
              _showSnackBar(
                success ? 'Password updated successfully' : 'Failed to update password',
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  void _showStoreDetailsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Store Details'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(labelText: 'Store Name'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Contact Email'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Phone Number'),
            ),
            SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Address'),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showSnackBar('Store details updated (Demo)');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}