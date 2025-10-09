import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shishra/order.dart' as app_order;

class AdminOrdersPage extends StatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  State<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends State<AdminOrdersPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _selectedStatus = 'All';
  final List<String> _orderStatuses = [
    'All',
    'Pending',
    'Confirmed',
    'Shipped',
    'Delivered',
    'Cancelled'
  ];
  Stream<List<app_order.Order>>? _ordersStream;

  @override
  void initState() {
    super.initState();
    _ordersStream = _getAllOrdersStream();
  }

  Stream<List<app_order.Order>> _getAllOrdersStream() {
    return _firestore.collectionGroup('orders').snapshots().map(
      (snapshot) => snapshot.docs.map((doc) => app_order.Order.fromSnapshot(doc)).toList(),
    );
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
                'Order Management',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              DropdownButton<String>(
                value: _selectedStatus,
                items: _orderStatuses.map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedStatus = value!;
                  });
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'View and manage customer orders',
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
                    // Orders table header
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Order ID')),
                          Expanded(flex: 2, child: Text('Customer')),
                          Expanded(flex: 2, child: Text('Date')),
                          Expanded(flex: 2, child: Text('Total')),
                          Expanded(flex: 2, child: Text('Status')),
                          Expanded(flex: 1, child: Text('Actions')),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: StreamBuilder<List<app_order.Order>>(
                        stream: _ordersStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          
                          if (snapshot.hasError) {
                            return Center(
                              child: Text('Error: ${snapshot.error}'),
                            );
                          }
                          
                          final orders = snapshot.data ?? [];
                          final filteredOrders = _selectedStatus == 'All'
                              ? orders
                              : orders.where((order) => order.status == _selectedStatus).toList();
                          
                          if (filteredOrders.isEmpty) {
                            return const Center(
                              child: Text(
                                'No orders found. Orders placed by customers will appear here.',
                                style: TextStyle(fontSize: 16, color: Colors.grey),
                              ),
                            );
                          }
                          
                          return ListView.builder(
                            itemCount: filteredOrders.length,
                            itemBuilder: (context, index) {
                              final order = filteredOrders[index];
                              return _buildOrderRow(order: order);
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

  Widget _buildOrderRow({
    required app_order.Order order,
  }) {
    Color statusColor = _getStatusColor(order.status);
    
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
              order.id.isEmpty ? 'N/A' : (order.id.length > 8 ? order.id.substring(0, 8) : order.id),
              style: const TextStyle(fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              order.shippingAddress.fullName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}',
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(
              '₹${order.total.toStringAsFixed(0)}',
              style: const TextStyle(fontWeight: FontWeight.w600),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            flex: 2,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                order.status,
                style: TextStyle(
                  color: statusColor,
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
                  child: Text('View Details'),
                ),
                const PopupMenuItem(
                  value: 'update',
                  child: Text('Update Status'),
                ),
                if (order.status != 'Cancelled')
                  const PopupMenuItem(
                    value: 'cancel',
                    child: Text('Cancel Order'),
                  ),
              ],
              onSelected: (value) {
                _handleOrderAction(value.toString(), order);
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.orange;
      case 'Confirmed':
        return Colors.blue;
      case 'Shipped':
        return Colors.purple;
      case 'Delivered':
        return Colors.green;
      case 'Cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleOrderAction(String action, app_order.Order order) {
    switch (action) {
      case 'view':
        _showOrderDetails(order);
        break;
      case 'update':
        _showUpdateStatusDialog(order);
        break;
      case 'cancel':
        _cancelOrder(order);
        break;
    }
  }

  void _showOrderDetails(app_order.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Order Details - ${order.id}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Customer: ${order.shippingAddress.fullName}'),
              Text('Phone: ${order.shippingAddress.phoneNumber}'),
              Text('Address: ${order.shippingAddress.displayAddress}'),
              const SizedBox(height: 16),
              const Text('Items:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...order.items.map((item) => Padding(
                padding: const EdgeInsets.only(left: 8, top: 4),
                child: Text('• ${item.product.name} x${item.quantity} - ₹${item.totalPrice}'),
              )),
              const SizedBox(height: 16),
              Text('Total: ₹${order.total.toStringAsFixed(2)}', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Status: ${order.status}'),
              Text('Order Date: ${order.createdAt.day}/${order.createdAt.month}/${order.createdAt.year}'),
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

  void _showUpdateStatusDialog(app_order.Order order) {
    String selectedStatus = order.status;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Update Order Status - ${order.id}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Current Status: ${order.status}'),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: const InputDecoration(labelText: 'New Status'),
                items: _orderStatuses.skip(1).map((status) {
                  return DropdownMenuItem(
                    value: status,
                    child: Text(status),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedStatus = value!;
                  });
                },
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
                try {
                  // Update order in user's subcollection
                  await _firestore
                      .collection('users')
                      .doc(order.userId)
                      .collection('orders')
                      .doc(order.id)
                      .update({
                    'status': selectedStatus,
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                  
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Order status updated to $selectedStatus')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error updating status: $e')),
                    );
                  }
                }
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  void _cancelOrder(app_order.Order order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancel Order'),
        content: Text('Are you sure you want to cancel order ${order.id}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                // Cancel order in user's subcollection
                await _firestore
                    .collection('users')
                    .doc(order.userId)
                    .collection('orders')
                    .doc(order.id)
                    .update({
                  'status': 'Cancelled',
                  'updatedAt': FieldValue.serverTimestamp(),
                });
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Order cancelled successfully')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error cancelling order: $e')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Order', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}