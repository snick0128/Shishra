import 'package:flutter/material.dart';
import 'package:shishra/services/admin_service.dart';
import 'package:another_flushbar/flushbar.dart';

class SecretAdminDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onAdminAccessGranted;

  const SecretAdminDetector({
    super.key,
    required this.child,
    this.onAdminAccessGranted,
  });

  @override
  State<SecretAdminDetector> createState() => _SecretAdminDetectorState();
}

class _SecretAdminDetectorState extends State<SecretAdminDetector> {
  final AdminService _adminService = AdminService();
  final List<DateTime> _tapTimes = [];
  final int _requiredTaps = 7;
  final Duration _tapTimeWindow = const Duration(seconds: 4);

  void _onTap() {
    final now = DateTime.now();
    
    // Remove taps older than the time window
    _tapTimes.removeWhere(
      (tapTime) => now.difference(tapTime) > _tapTimeWindow,
    );
    
    // Add current tap
    _tapTimes.add(now);
    
    // Check if we have enough taps
    if (_tapTimes.length >= _requiredTaps) {
      _showAdminAccessModal();
      _tapTimes.clear(); // Clear to prevent multiple modals
    }
  }

  void _showAdminAccessModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => AdminAccessModal(
        adminService: _adminService,
        onAdminAuthenticated: () {
          Navigator.of(context).pop();
          widget.onAdminAccessGranted?.call();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.translucent,
      child: widget.child,
    );
  }
}

class AdminAccessModal extends StatefulWidget {
  final AdminService adminService;
  final VoidCallback onAdminAuthenticated;

  const AdminAccessModal({
    super.key,
    required this.adminService,
    required this.onAdminAuthenticated,
  });

  @override
  State<AdminAccessModal> createState() => _AdminAccessModalState();
}

class _AdminAccessModalState extends State<AdminAccessModal> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _authenticateAdmin() async {
    if (_passwordController.text.isEmpty) {
      _showErrorMessage('Please enter admin password');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final isAuthenticated = await widget.adminService
          .authenticateAdmin(_passwordController.text);

      if (isAuthenticated) {
        _showSuccessMessage('Admin access granted');
        await Future.delayed(const Duration(seconds: 1));
        widget.onAdminAuthenticated();
      } else {
        _showErrorMessage('Access Denied');
      }
    } catch (e) {
      _showErrorMessage('Authentication failed');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.error_outline, color: Colors.white),
    ).show(context);
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;
    Flushbar(
      message: message,
      backgroundColor: Colors.green,
      duration: const Duration(seconds: 2),
      margin: const EdgeInsets.all(8),
      borderRadius: BorderRadius.circular(8),
      flushbarPosition: FlushbarPosition.BOTTOM,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
    ).show(context);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.red,
                  size: 28,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Admin Access',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    minimumSize: const Size(32, 32),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'Enter admin password to continue',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              enabled: !_isLoading,
              onSubmitted: (_) => _authenticateAdmin(),
              decoration: InputDecoration(
                labelText: 'Admin Password',
                hintText: 'Enter password',
                prefixIcon: const Icon(Icons.lock),
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                  icon: Icon(
                    _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _authenticateAdmin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Login as Admin',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Wrong password will be denied without hints',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}