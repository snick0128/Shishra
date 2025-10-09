import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Ensure user is authenticated
  Future<bool> _ensureAuthenticated() async {
    try {
      if (_auth.currentUser == null) {
        await _auth.signInAnonymously();
      }
      return true;
    } catch (e) {
      print('Authentication failed: $e');
      return false;
    }
  }

  /// Upload product image
  Future<String?> uploadProductImage(File imageFile) async {
    try {
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication failed');
      }

      // Verify file exists
      if (!await imageFile.exists()) {
        print('Error: Image file does not exist at path: ${imageFile.path}');
        return null;
      }
      
      final String fileName = 'product_${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('products/$fileName');
      
      // Set metadata
      final SettableMetadata metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'uploadedBy': _auth.currentUser?.uid ?? 'anonymous',
          'uploadedAt': DateTime.now().toIso8601String(),
          'folder': 'products',
        },
      );
      
      print('Uploading image: $fileName');
      final UploadTask uploadTask = ref.putFile(imageFile, metadata);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      print('Image uploaded successfully: $downloadUrl');
      return downloadUrl;
    } catch (e) {
      print('Error uploading product image: $e');
      return null;
    }
  }

  /// Upload user profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final String fileName = 'profile_$userId.jpg';
      final Reference ref = _storage.ref().child('profiles/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  /// Pick image from gallery
  Future<File?> pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick image from camera
  Future<File?> pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick multiple images for product gallery
  Future<List<File>> pickMultipleImages({int maxImages = 5}) async {
    try {
      print('Starting image picker for multiple images (max: $maxImages)');
      
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      print('Image picker returned ${pickedFiles.length} files');
      
      // If user canceled, return empty list
      if (pickedFiles.isEmpty) {
        print('User canceled image selection or no images were selected');
        return [];
      }
      
      final List<File> imageFiles = [];
      for (int i = 0; i < pickedFiles.length && i < maxImages; i++) {
        try {
          final xFile = pickedFiles[i];
          print('Processing file ${i + 1}: ${xFile.path}');
          
          final file = File(xFile.path);
          
          // Verify file exists and is readable
          if (await file.exists()) {
            final fileSize = await file.length();
            print('✓ Image ${i + 1}: ${file.path} (${_formatFileSize(fileSize)})');
            imageFiles.add(file);
          } else {
            print('✗ Warning: Image file does not exist: ${file.path}');
          }
        } catch (fileError) {
          print('✗ Error processing file ${i + 1}: $fileError');
          continue; // Skip this file and continue with others
        }
      }
      
      print('Successfully processed ${imageFiles.length}/${pickedFiles.length} valid image files');
      return imageFiles;
    } catch (e) {
      print('Error picking multiple images: $e');
      print('Attempting fallback to single image picker...');
      
      // Fallback to single image picker
      try {
        final XFile? singleFile = await _imagePicker.pickImage(
          source: ImageSource.gallery,
          maxWidth: 1920,
          maxHeight: 1080,
          imageQuality: 85,
        );
        
        if (singleFile != null) {
          try {
            final file = File(singleFile.path);
            if (await file.exists()) {
              print('✓ Fallback: Single image selected: ${file.path}');
              return [file];
            }
          } catch (fileError) {
            print('✗ Fallback: Error processing selected file: $fileError');
          }
        }
        print('Fallback: No image selected');
        return [];
      } catch (fallbackError) {
        print('Fallback image picker also failed: $fallbackError');
        return [];
      }
    }
  }
  
  /// Format file size for logging
  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  /// Upload multiple product images
  Future<List<String>> uploadMultipleProductImages(List<File> imageFiles) async {
    print('Starting upload of ${imageFiles.length} images');
    final List<String> downloadUrls = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final File imageFile = imageFiles[i];
      print('Uploading image ${i + 1}/${imageFiles.length}');
      final String? url = await uploadProductImage(imageFile);
      if (url != null) {
        downloadUrls.add(url);
        print('Successfully uploaded image ${i + 1}: $url');
      } else {
        print('Failed to upload image ${i + 1}');
      }
    }
    
    print('Upload complete. ${downloadUrls.length}/${imageFiles.length} images uploaded successfully');
    return downloadUrls;
  }

  /// Delete image from storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      // Ensure user is authenticated
      if (!await _ensureAuthenticated()) {
        throw Exception('Authentication failed');
      }

      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
      print('Image deleted successfully: $imageUrl');
      return true;
    } catch (e) {
      print('Error deleting image: $e');
      return false;
    }
  }

  /// Upload banner image
  Future<String?> uploadBannerImage(File imageFile) async {
    try {
      final String fileName = 'banner_${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('banners/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading banner image: $e');
      return null;
    }
  }

  /// Upload category icon
  Future<String?> uploadCategoryIcon(File imageFile) async {
    try {
      final String fileName = 'category_${const Uuid().v4()}.png';
      final Reference ref = _storage.ref().child('categories/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      print('Error uploading category icon: $e');
      return null;
    }
  }

  /// Show image picker dialog
  Future<File?> showImagePickerDialog() async {
    // This would typically show a dialog to choose between camera and gallery
    // For now, we'll default to gallery
    return await pickImageFromGallery();
  }

  /// Test image picker functionality
  Future<bool> testImagePicker() async {
    try {
      print('Testing image picker functionality...');
      final XFile? testFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 100,
        maxHeight: 100,
        imageQuality: 50,
      );
      
      if (testFile != null) {
        print('✓ Image picker test successful: ${testFile.path}');
        return true;
      } else {
        print('✗ Image picker test failed: No file selected');
        return false;
      }
    } catch (e) {
      print('✗ Image picker test failed with error: $e');
      return false;
    }
  }
}