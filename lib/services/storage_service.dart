import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _imagePicker = ImagePicker();

  /// Upload product image
  Future<String?> uploadProductImage(File imageFile) async {
    try {
      final String fileName = 'product_${const Uuid().v4()}.jpg';
      final Reference ref = _storage.ref().child('products/$fileName');
      
      final UploadTask uploadTask = ref.putFile(imageFile);
      final TaskSnapshot snapshot = await uploadTask;
      
      final String downloadUrl = await snapshot.ref.getDownloadURL();
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
      final List<XFile> pickedFiles = await _imagePicker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      final List<File> imageFiles = [];
      for (int i = 0; i < pickedFiles.length && i < maxImages; i++) {
        imageFiles.add(File(pickedFiles[i].path));
      }
      
      return imageFiles;
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  /// Upload multiple product images
  Future<List<String>> uploadMultipleProductImages(List<File> imageFiles) async {
    final List<String> downloadUrls = [];
    
    for (final File imageFile in imageFiles) {
      final String? url = await uploadProductImage(imageFile);
      if (url != null) {
        downloadUrls.add(url);
      }
    }
    
    return downloadUrls;
  }

  /// Delete image from storage
  Future<bool> deleteImage(String imageUrl) async {
    try {
      final Reference ref = _storage.refFromURL(imageUrl);
      await ref.delete();
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
}