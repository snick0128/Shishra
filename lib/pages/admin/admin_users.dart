import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/utils/responsive_layout.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'All';
  final List<String> _filterOptions = ['All', 'Active', 'Blocked', 'Recent'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'User Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              ElevatedButton.icon(
                onPressed: _exportUsers,
                icon: const Icon(Icons.download, color: Colors.white, size: 18),
                label: const Text('Export CSV', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage customer accounts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by name, phone, or email...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              DropdownButton<String>(
                value: _selectedFilter,
                items: _filterOptions.map((filter) {
                  return DropdownMenuItem(
                    value: filter,
                    child: Text(filter),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFilter = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Users table header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Phone', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Total Orders', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 2, child: Text('Total Spent', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold))),
                          Expanded(flex: 1, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: ${snapshot.error}'));
                          }
                          final docs = snapshot.data?.docs ?? [];
                          
                          // Apply filters
                          var filteredDocs = docs.where((doc) {
                            final data = doc.data();
                            final name = (data['name'] ?? '').toString().toLowerCase();
                            final phone = (data['phone'] ?? '').toString().toLowerCase();
                            final email = (data['email'] ?? '').toString().toLowerCase();
                            final isBlocked = data['isBlocked'] == true;
                            
                            // Search filter
                            if (_searchQuery.isNotEmpty) {
                              if (!name.contains(_searchQuery) && 
                                  !phone.contains(_searchQuery) && 
                                  !email.contains(_searchQuery)) {
                                return false;
                              }
                            }
                            
                            // Status filter
                            if (_selectedFilter == 'Active' && isBlocked) return false;
                            if (_selectedFilter == 'Blocked' && !isBlocked) return false;
                            
                            return true;
                          }).toList();
                          
                          // Sort by recent if selected
                          if (_selectedFilter == 'Recent') {
                            filteredDocs.sort((a, b) {
                              final aTime = a.data()['createdAt'] as Timestamp?;
                              final bTime = b.data()['createdAt'] as Timestamp?;
                              if (aTime == null || bTime == null) return 0;
                              return bTime.compareTo(aTime);
                            });
                          }
                          
                          if (filteredDocs.isEmpty) {
                            return const Center(child: Text('No users found'));
                          }
                          
                          return ListView.builder(
                            itemCount: filteredDocs.length,
                            itemBuilder: (context, index) {
                              final doc = filteredDocs[index];
                              final data = doc.data();
                              final userId = doc.id;
                              final name = (data['name'] ?? '').toString();
                              final phone = (data['phone'] ?? '').toString();
                              final email = (data['email'] ?? '').toString();
                              final isActive = (data['isBlocked'] == true) ? false : true;
                              final totalOrders = (data['orders'] is List)
                                  ? (data['orders'] as List).length
                                  : (data['totalOrders'] ?? 0);
                              final totalSpent = (data['totalSpent'] is num)
                                  ? (data['totalSpent'] as num).toInt()
                                  : 0;

                              return _buildUserRow(
                                userId: userId,
                                name: name.isNotEmpty ? name : '—',
                                phone: phone.isNotEmpty ? phone : '—',
                                email: email.isNotEmpty ? email : '—',
                                totalOrders: totalOrders is int ? totalOrders : 0,
                                totalSpent: totalSpent,
                                isActive: isActive,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRow({
    required String userId,
    required String name,
    required String phone,
    required String email,
    required int totalOrders,
    required int totalSpent,
    required bool isActive,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(
              name,
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              phone,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              email,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '$totalOrders',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹$totalSpent',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                ),
              ),
              child: Text(
                isActive ? 'Active' : 'Blocked',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          Expanded(
            flex: 1,
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'view',
                  child: Row(
                    children: [
                      Icon(Icons.visibility, size: 18),
                      SizedBox(width: 8),
                      Text('View Details'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: isActive ? 'block' : 'unblock',
                  child: Row(
                    children: [
                      Icon(isActive ? Icons.block : Icons.check_circle, size: 18),
                      const SizedBox(width: 8),
                      Text(isActive ? 'Block User' : 'Unblock User'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete User', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) => _handleUserAction(value.toString(), userId, name, isActive),
            ),
          ),
        ],
      ),
    );
  }

  void _handleUserAction(String action, String userId, String userName, bool isActive) {
    switch (action) {
      case 'view':
        _showUserDetails(userId);
        break;
      case 'block':
        _toggleUserBlock(userId, userName, true);
        break;
      case 'unblock':
        _toggleUserBlock(userId, userName, false);
        break;
      case 'delete':
        _deleteUser(userId, userName);
        break;
    }
  }

  void _showUserDetails(String userId) async {
    final userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userDoc.exists) return;
    
    final data = userDoc.data()!;
    if (!mounted) return;
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('User Details - ${data['name'] ?? 'Unknown'}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildDetailRow('Name', data['name'] ?? '—'),
              _buildDetailRow('Phone', data['phone'] ?? '—'),
              _buildDetailRow('Email', data['email'] ?? '—'),
              _buildDetailRow('User ID', userId),
              _buildDetailRow('Status', data['isBlocked'] == true ? 'Blocked' : 'Active'),
              _buildDetailRow('Total Orders', '${data['totalOrders'] ?? 0}'),
              _buildDetailRow('Total Spent', '₹${data['totalSpent'] ?? 0}'),
              _buildDetailRow('Joined', data['createdAt'] != null 
                  ? (data['createdAt'] as Timestamp).toDate().toString().substring(0, 10)
                  : '—'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }

  void _toggleUserBlock(String userId, String userName, bool block) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${block ? 'Block' : 'Unblock'} User'),
        content: Text('Are you sure you want to ${block ? 'block' : 'unblock'} $userName?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).update({
                  'isBlocked': block,
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('User ${block ? 'blocked' : 'unblocked'} successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: block ? Colors.red : Colors.green,
            ),
            child: Text(block ? 'Block' : 'Unblock', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteUser(String userId, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete User'),
        content: Text('Are you sure you want to delete $userName? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseFirestore.instance.collection('users').doc(userId).delete();
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('User deleted successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _exportUsers() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export functionality will download user data as CSV'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}