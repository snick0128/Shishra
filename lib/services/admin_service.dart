import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AdminService {
  static const String _adminPasswordDoc = 'admin_config';
  static const String _defaultAdminPassword = 'admin123'; // Change this in production
  
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Verify admin password and authenticate as admin
  Future<bool> authenticateAdmin(String password) async {
    try {
      // Get hashed password from Firestore
      final adminDoc = await _firestore
          .collection('settings')
          .doc(_adminPasswordDoc)
          .get();

      String hashedStoredPassword;
      if (adminDoc.exists && adminDoc.data()?['admin_password_hash'] != null) {
        hashedStoredPassword = adminDoc.data()!['admin_password_hash'];
      } else {
        // First time setup - use default password and store its hash
        hashedStoredPassword = _hashPassword(_defaultAdminPassword);
        await _storeAdminPasswordHash(hashedStoredPassword);
      }

      // Hash the provided password and compare
      final hashedProvidedPassword = _hashPassword(password);
      
      if (hashedProvidedPassword == hashedStoredPassword) {
        // Set custom claims for admin user
        await _setAdminClaims();
        return true;
      }
      
      return false;
    } catch (e) {
      print('Error authenticating admin: $e');
      return false;
    }
  }

  /// Hash password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Store admin password hash in Firestore
  Future<void> _storeAdminPasswordHash(String hash) async {
    await _firestore.collection('settings').doc(_adminPasswordDoc).set({
      'admin_password_hash': hash,
      'updated_at': FieldValue.serverTimestamp(),
    });
  }

  /// Set admin custom claims (in real app, this would be done via Cloud Functions)
  Future<void> _setAdminClaims() async {
    final user = _auth.currentUser;
    if (user != null) {
      // Update user document with admin flag
      await _firestore.collection('users').doc(user.uid).update({
        'is_admin': true,
        'admin_authenticated_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Check if current user is admin
  Future<bool> isCurrentUserAdmin() async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      return userDoc.data()?['is_admin'] == true;
    } catch (e) {
      return false;
    }
  }

  /// Remove admin privileges
  Future<void> removeAdminAccess() async {
    final user = _auth.currentUser;
    if (user != null) {
      await _firestore.collection('users').doc(user.uid).update({
        'is_admin': false,
        'admin_removed_at': FieldValue.serverTimestamp(),
      });
    }
  }

  /// Change admin password
  Future<bool> changeAdminPassword(String oldPassword, String newPassword) async {
    try {
      // Verify old password first
      if (await authenticateAdmin(oldPassword)) {
        final newHashedPassword = _hashPassword(newPassword);
        await _storeAdminPasswordHash(newHashedPassword);
        return true;
      }
      return false;
    } catch (e) {
      print('Error changing admin password: $e');
      return false;
    }
  }

  /// Initialize admin settings (call this once during app setup)
  Future<void> initializeAdminSettings() async {
    try {
      final adminDoc = await _firestore
          .collection('settings')
          .doc(_adminPasswordDoc)
          .get();

      if (!adminDoc.exists) {
        await _storeAdminPasswordHash(_hashPassword(_defaultAdminPassword));
      }
    } catch (e) {
      print('Error initializing admin settings: $e');
    }
  }
}