import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'dart:io';

/// Simple test page to debug image picker issues
class ImagePickerTestPage extends StatefulWidget {
  const ImagePickerTestPage({super.key});

  @override
  State<ImagePickerTestPage> createState() => _ImagePickerTestPageState();
}

class _ImagePickerTestPageState extends State<ImagePickerTestPage> {
  final StorageService _storageService = StorageService();
  List<File> _selectedImages = [];
  bool _isLoading = false;
  String _statusMessage = 'Ready to test image picker';

  Future<void> _testImagePicker() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing image picker...';
      _selectedImages.clear();
    });

    try {
      print('=== IMAGE PICKER TEST START ===');
      final images = await _storageService.pickMultipleImages(maxImages: 3);
      
      setState(() {
        _selectedImages = images;
        _isLoading = false;
        if (images.isNotEmpty) {
          _statusMessage = 'Success! Selected ${images.length} image(s)';
        } else {
          _statusMessage = 'No images selected (user canceled or error)';
        }
      });
      
      print('=== IMAGE PICKER TEST END ===');
      print('Result: ${images.length} images selected');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      print('=== IMAGE PICKER TEST FAILED ===');
      print('Error: $e');
    }
  }

  Future<void> _testSingleImagePicker() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Testing single image picker...';
      _selectedImages.clear();
    });

    try {
      print('=== SINGLE IMAGE PICKER TEST START ===');
      final image = await _storageService.pickImageFromGallery();
      
      setState(() {
        _selectedImages = image != null ? [image] : [];
        _isLoading = false;
        if (image != null) {
          _statusMessage = 'Success! Selected 1 image';
        } else {
          _statusMessage = 'No image selected (user canceled or error)';
        }
      });
      
      print('=== SINGLE IMAGE PICKER TEST END ===');
      print('Result: ${image != null ? '1' : '0'} image selected');
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error: $e';
      });
      print('=== SINGLE IMAGE PICKER TEST FAILED ===');
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Picker Test'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Status Card
            Card(
              color: _selectedImages.isNotEmpty ? Colors.green[50] : Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Status',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _selectedImages.isNotEmpty ? Colors.green[700] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _statusMessage,
                      style: const TextStyle(fontSize: 16),
                    ),
                    if (_isLoading) ...[
                      const SizedBox(height: 12),
                      const LinearProgressIndicator(),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Test Buttons
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testImagePicker,
              icon: const Icon(Icons.photo_library),
              label: const Text('Test Multiple Image Picker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _isLoading ? null : _testSingleImagePicker,
              icon: const Icon(Icons.photo),
              label: const Text('Test Single Image Picker'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const SizedBox(height: 24),

            // Selected Images Display
            if (_selectedImages.isNotEmpty) ...[
              Text(
                'Selected Images (${_selectedImages.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: _selectedImages.length,
                  itemBuilder: (context, index) {
                    final image = _selectedImages[index];
                    return Card(
                      child: Column(
                        children: [
                          Expanded(
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(8),
                                ),
                                image: DecorationImage(
                                  image: FileImage(image),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              'Image ${index + 1}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ] else ...[
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No images selected yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Tap a button above to test image selection',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            // Instructions
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Instructions:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('1. Check the console logs for detailed debugging info'),
                  Text('2. Try both single and multiple image pickers'),
                  Text('3. If images don\'t appear, check file permissions'),
                  Text('4. Look for any error messages in the status card'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
