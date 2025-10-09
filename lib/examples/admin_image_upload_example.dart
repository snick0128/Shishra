import 'package:flutter/material.dart';
import '../components/admin_image_upload_widget.dart';
import '../services/firebase_storage_service.dart';

/// Example page demonstrating how to use AdminImageUploadWidget
class AdminImageUploadExample extends StatefulWidget {
  const AdminImageUploadExample({super.key});

  @override
  State<AdminImageUploadExample> createState() => _AdminImageUploadExampleState();
}

class _AdminImageUploadExampleState extends State<AdminImageUploadExample> {
  String? _productImageUrl;
  String? _bannerImageUrl;
  List<String> _galleryImages = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Image Upload Examples'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Example 1: Single Product Image Upload
            _buildSection(
              title: '1. Product Image Upload',
              description: 'Upload a single product image with custom size',
              child: AdminImageUploadWidget(
                folder: StorageFolders.products,
                label: 'Product Image',
                required: true,
                width: 200,
                height: 200,
                onImageUploaded: (imageUrl) {
                  setState(() {
                    _productImageUrl = imageUrl;
                  });
                  _showSnackBar(
                    imageUrl != null 
                        ? 'Product image uploaded!' 
                        : 'Product image removed!',
                    imageUrl != null ? Colors.green : Colors.orange,
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Example 2: Banner Image Upload
            _buildSection(
              title: '2. Banner Image Upload',
              description: 'Upload a banner image with different dimensions',
              child: AdminImageUploadWidget(
                folder: StorageFolders.banners,
                label: 'Banner Image',
                width: 300,
                height: 150,
                fileName: 'custom_banner.jpg',
                onImageUploaded: (imageUrl) {
                  setState(() {
                    _bannerImageUrl = imageUrl;
                  });
                  _showSnackBar(
                    imageUrl != null 
                        ? 'Banner uploaded!' 
                        : 'Banner removed!',
                    imageUrl != null ? Colors.green : Colors.orange,
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Example 3: Multiple Images Upload
            _buildSection(
              title: '3. Multiple Images Gallery',
              description: 'Upload multiple images for a product gallery',
              child: MultiImageUploadWidget(
                folder: StorageFolders.products,
                maxImages: 5,
                imageSize: 120,
                initialImageUrls: _galleryImages,
                onImagesChanged: (imageUrls) {
                  setState(() {
                    _galleryImages = imageUrls;
                  });
                  _showSnackBar(
                    'Gallery updated: ${imageUrls.length} images',
                    Colors.blue,
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // Display current state
            _buildSection(
              title: '4. Current State',
              description: 'Current uploaded image URLs',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildUrlDisplay('Product Image:', _productImageUrl),
                    const SizedBox(height: 8),
                    _buildUrlDisplay('Banner Image:', _bannerImageUrl),
                    const SizedBox(height: 8),
                    _buildUrlDisplay('Gallery Images:', _galleryImages.join('\n')),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Usage Instructions
            _buildSection(
              title: '5. Usage Instructions',
              description: 'How to implement in your own code',
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Basic Usage:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text(
                      '''AdminImageUploadWidget(
  folder: StorageFolders.products,
  label: 'Product Image',
  required: true,
  width: 200,
  height: 200,
  onImageUploaded: (imageUrl) {
    // Handle the uploaded image URL
    print('Image uploaded: \$imageUrl');
  },
)''',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Features:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Drag & drop or click to upload'),
                    Text('• Camera and gallery support'),
                    Text('• Image compression and validation'),
                    Text('• Progress indicators'),
                    Text('• Edit and delete functionality'),
                    Text('• Multiple image support'),
                    Text('• Custom sizing and labeling'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String description,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildUrlDisplay(String label, String? url) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            url?.isNotEmpty == true ? url! : 'No image uploaded',
            style: TextStyle(
              color: url?.isNotEmpty == true ? Colors.blue : Colors.grey,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
