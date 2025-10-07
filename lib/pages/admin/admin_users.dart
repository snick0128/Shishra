import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'User Management',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage customer accounts',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 32),
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
                          Expanded(flex: 2, child: Text('Name')),
                          Expanded(flex: 2, child: Text('Phone')),
                          Expanded(flex: 2, child: Text('Email')),
                          Expanded(flex: 2, child: Text('Total Orders')),
                          Expanded(flex: 2, child: Text('Total Spent')),
                          Expanded(flex: 1, child: Text('Status')),
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
                          if (docs.isEmpty) {
                            return const Center(child: Text('No users found'));
                          }
                          return ListView.builder(
                            itemCount: docs.length,
                            itemBuilder: (context, index) {
                              final data = docs[index].data();
                              final name = (data['name'] ?? '').toString();
                              final phone = (data['phone'] ?? '').toString();
                              final email = (data['email'] ?? '').toString();
                              final isActive = (data['isBlocked'] == true) ? false : true;
                              // Placeholder values; can be replaced with aggregate queries
                              final totalOrders = (data['orders'] is List)
                                  ? (data['orders'] as List).length
                                  : (data['totalOrders'] ?? 0);
                              final totalSpent = (data['totalSpent'] is num)
                                  ? (data['totalSpent'] as num).toInt()
                                  : 0;

                              return _buildUserRow(
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
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(phone),
          ),
          Expanded(
            flex: 2,
            child: Text(email),
          ),
          Expanded(
            flex: 2,
            child: Text('$totalOrders'),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹$totalSpent',
              style: const TextStyle(fontWeight: FontWeight.w600),
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
                isActive ? 'Active' : 'Disabled',
                style: TextStyle(
                  color: isActive ? Colors.green : Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}