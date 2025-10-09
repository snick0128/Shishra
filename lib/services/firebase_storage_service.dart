import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class FirebaseStorageService {
  static final FirebaseStorageService _instance = FirebaseStorageService._internal();
  factory FirebaseStorageService() => _instance;
  FirebaseStorageService._internal();

  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ImagePicker _picker = ImagePicker();
  final Uuid _uuid = const Uuid();

  // Maximum file size for free tier (5MB limit, we'll use 2MB to be safe)
  static const int maxFileSizeBytes = 2 * 1024 * 1024; // 2MB
  static const int targetSizeKB = 150; // Target 150KB for compressed images

  /// Initialize anonymous authentication if user is not signed in
  Future<bool> _ensureAuthenticated() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      return true;
    } catch (e) {
      debugPrint('Authentication failed: $e');
      return false;
    }
  }

  /// Pick image from gallery or camera
  Future<XFile?> pickImage({required ImageSource source}) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      return image;
    } catch (e) {
      debugPrint('Error picking image: $e');
      return null;
    }
  }

  /// Read image file as bytes (simplified without compression)
  Future<Uint8List?> readImageBytes(XFile imageFile) async {
    try {
      final File file = File(imageFile.path);
      final int fileSizeBytes = await file.length();
      
      // Check if file is too large (limit to 5MB for Firebase free tier)
      if (fileSizeBytes > maxFileSizeBytes) {
        debugPrint('Image file too large: ${formatBytes(fileSizeBytes)}. Maximum allowed: ${formatBytes(maxFileSizeBytes)}');
        return null;
      }

      // Read and return file bytes
      return await file.readAsBytes();
    } catch (e) {
      debugPrint('Error reading image: $e');
      return null;
    }
  }

  /// Upload image to Firebase Storage
  Future<String?> uploadImage({
    required Uint8List imageBytes,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication failed');
      }

      // Generate unique filename if not provided
      fileName ??= '${_uuid.v4()}.jpg';
      
      // Ensure filename has .jpg extension
      if (!fileName.toLowerCase().endsWith('.jpg') && 
          !fileName.toLowerCase().endsWith('.jpeg')) {
        fileName = '${path.basenameWithoutExtension(fileName)}.jpg';
      }

      // Create storage reference
      final String fullPath = '$folder/$fileName';
      final Reference ref = _storage.ref().child(fullPath);

      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
          'uploadedAt': DateTime.now().toIso8601String(),
          'folder': folder,
        },
      );

      // Upload the file
      final UploadTask uploadTask = ref.putData(imageBytes, metadata);
      
      // Monitor upload progress (optional)
      uploadTask.snapshotEvents.listen((TaskSnapshot snapshot) {
        final double progress = snapshot.bytesTransferred / snapshot.totalBytes;
        debugPrint('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
      });

      // Wait for upload to complete
      final TaskSnapshot snapshot = await uploadTask;
      
      // Get download URL
      final String downloadURL = await snapshot.ref.getDownloadURL();
      
      debugPrint('Image uploaded successfully: $downloadURL');
      return downloadURL;
      
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  /// Complete upload process: pick, read, and upload
  Future<String?> pickAndUpload({
    required ImageSource source,
    required String folder,
    String? fileName,
  }) async {
    try {
      // Pick image
      final XFile? imageFile = await pickImage(source: source);
      if (imageFile == null) return null;

      // Read image bytes
      final Uint8List? imageBytes = await readImageBytes(imageFile);
      if (imageBytes == null) return null;

      // Upload image
      final String? downloadURL = await uploadImage(
        imageBytes: imageBytes,
        folder: folder,
        fileName: fileName,
      );

      return downloadURL;
    } catch (e) {
      debugPrint('Error in complete upload process: $e');
      return null;
    }
  }

  /// Delete image from Firebase Storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication failed');
      }

      // Extract storage path from URL
      final Reference ref = _storage.refFromURL(imageUrl);
      
      // Delete the file
      await ref.delete();
      
      debugPrint('Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      debugPrint('Error deleting image: $e');
      return false;
    }
  }

  /// Get all images in a folder (for admin management)
  Future<List<String>> getImagesInFolder(String folder) async {
    try {
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication failed');
      }

      final Reference ref = _storage.ref().child(folder);
      final ListResult result = await ref.listAll();
      
      final List<String> imageUrls = [];
      for (final Reference item in result.items) {
        final String downloadUrl = await item.getDownloadURL();
        imageUrls.add(downloadUrl);
      }
      
      return imageUrls;
    } catch (e) {
      debugPrint('Error getting images in folder: $e');
      return [];
    }
  }

  /// Get image metadata
  Future<FullMetadata?> getImageMetadata(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      return await ref.getMetadata();
    } catch (e) {
      debugPrint('Error getting image metadata: $e');
      return null;
    }
  }

  /// Check if image exists
  Future<bool> imageExists(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get storage usage for a folder (helpful for monitoring free tier limits)
  Future<int> getFolderSize(String folder) async {
    try {
      final Reference ref = _storage.ref().child(folder);
      final ListResult result = await ref.listAll();
      
      int totalSize = 0;
      for (final Reference item in result.items) {
        final FullMetadata metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }
      
      return totalSize;
    } catch (e) {
      debugPrint('Error calculating folder size: $e');
      return 0;
    }
  }

  /// Format bytes to human readable string
  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

/// Storage folders for different types of images
class StorageFolders {
  static const String products = 'products';
  static const String categories = 'categories';
  static const String banners = 'banners';
  static const String profiles = 'profiles';
  static const String reviews = 'reviews';
  static const String temp = 'temp'; // For temporary uploads
}

/// Result class for upload operations
class UploadResult {
  final bool success;
  final String? downloadUrl;
  final String? error;
  final int? fileSizeBytes;

  UploadResult({
    required this.success,
    this.downloadUrl,
    this.error,
    this.fileSizeBytes,
  });

  factory UploadResult.success(String downloadUrl, int fileSizeBytes) {
    return UploadResult(
      success: true,
      downloadUrl: downloadUrl,
      fileSizeBytes: fileSizeBytes,
    );
  }

  factory UploadResult.failure(String error) {
    return UploadResult(
      success: false,
      error: error,
    );
  }
}
