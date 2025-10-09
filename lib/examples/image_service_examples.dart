import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';
import '../components/cached_image_widget.dart';
import '../components/admin_image_upload_widget.dart';

/// Example page showing how to use the Firebase Storage Service
class ImageServiceExamplesPage extends StatefulWidget {
  const ImageServiceExamplesPage({super.key});

  @override
  State<ImageServiceExamplesPage> createState() => _ImageServiceExamplesPageState();
}

class _ImageServiceExamplesPageState extends State<ImageServiceExamplesPage> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String? _uploadedImageUrl;
  List<String> _productImages = [];
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Image Service Examples'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionTitle('1. Admin Image Upload Widget'),
            _buildAdminUploadExample(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('2. Multiple Images Upload'),
            _buildMultiImageExample(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('3. Manual Upload Example'),
            _buildManualUploadExample(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('4. Image Display Examples'),
            _buildImageDisplayExamples(),
            
            const SizedBox(height: 32),
            _buildSectionTitle('5. Storage Management'),
            _buildStorageManagementExample(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildAdminUploadExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This widget handles the complete upload process:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            AdminImageUploadWidget(
              folder: StorageFolders.products,
              label: 'Product Image',
              required: true,
              onImageUploaded: (url) {
                setState(() {
                  _uploadedImageUrl = url;
                });
                print('Image uploaded: $url');
              },
            ),
            if (_uploadedImageUrl != null) ...[
              const SizedBox(height: 16),
              Text(
                'Uploaded URL: $_uploadedImageUrl',
                style: const TextStyle(fontSize: 12, color: Colors.green),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMultiImageExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: MultiImageUploadWidget(
          folder: StorageFolders.products,
          maxImages: 5,
          onImagesChanged: (urls) {
            setState(() {
              _productImages = urls;
            });
            print('Product images updated: $urls');
          },
        ),
      ),
    );
  }

  Widget _buildManualUploadExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Manual upload with step-by-step control:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _manualUpload(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _manualUpload(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            if (_isLoading) ...[
              const SizedBox(height: 16),
              const Center(
                child: Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 8),
                    Text('Processing image...'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _manualUpload(ImageSource source) async {
    setState(() => _isLoading = true);

    try {
      // Step 1: Pick image
      final imageFile = await _storageService.pickImage(source: source);
      if (imageFile == null) {
        setState(() => _isLoading = false);
        return;
      }

      // Step 2: Read image bytes
      final imageBytes = await _storageService.readImageBytes(imageFile);
      if (imageBytes == null) {
        _showSnackBar('Failed to read image', Colors.red);
        setState(() => _isLoading = false);
        return;
      }

      // Show file info
      final originalSize = await imageFile.length();
      final imageSize = imageBytes.length;
      print('Original size: ${FirebaseStorageService.formatBytes(originalSize)}');
      print('Image size: ${FirebaseStorageService.formatBytes(imageSize)}');

      // Step 3: Upload image
      final downloadUrl = await _storageService.uploadImage(
        imageBytes: imageBytes,
        folder: StorageFolders.temp,
      );

      if (downloadUrl != null) {
        setState(() {
          _uploadedImageUrl = downloadUrl;
        });
        _showSnackBar('Image uploaded successfully!', Colors.green);
      } else {
        _showSnackBar('Failed to upload image', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildImageDisplayExamples() {
    // Sample image URLs for demonstration
    const sampleImageUrl = 'https://via.placeholder.com/300x300.jpg?text=Sample+Image';
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Different image display widgets:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            // Product Image Widget
            const Text('Product Image:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            ProductImageWidget(
              imageUrl: _uploadedImageUrl ?? sampleImageUrl,
              size: 120,
              onTap: () => print('Product image tapped'),
            ),
            
            const SizedBox(height: 16),
            
            // Category Icon Widget
            const Text('Category Icon:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CategoryIconWidget(
              imageUrl: _uploadedImageUrl ?? sampleImageUrl,
              size: 80,
              onTap: () => print('Category icon tapped'),
            ),
            
            const SizedBox(height: 16),
            
            // Profile Avatar Widget
            const Text('Profile Avatar:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Row(
              children: [
                ProfileAvatarWidget(
                  imageUrl: _uploadedImageUrl,
                  size: 60,
                  initials: 'JD',
                  onTap: () => print('Profile avatar tapped'),
                ),
                const SizedBox(width: 16),
                const ProfileAvatarWidget(
                  imageUrl: null,
                  size: 60,
                  initials: 'AB',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Basic Cached Image Widget
            const Text('Basic Cached Image:', style: TextStyle(fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            CachedImageWidget(
              imageUrl: _uploadedImageUrl ?? sampleImageUrl,
              width: 200,
              height: 100,
              borderRadius: BorderRadius.circular(12),
              fit: BoxFit.cover,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStorageManagementExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Storage management functions:',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            
            ElevatedButton.icon(
              onPressed: _checkStorageUsage,
              icon: const Icon(Icons.storage),
              label: const Text('Check Storage Usage'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            ElevatedButton.icon(
              onPressed: _listImagesInFolder,
              icon: const Icon(Icons.list),
              label: const Text('List Images in Products Folder'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
            
            const SizedBox(height: 8),
            
            if (_uploadedImageUrl != null)
              ElevatedButton.icon(
                onPressed: _deleteUploadedImage,
                icon: const Icon(Icons.delete),
                label: const Text('Delete Uploaded Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkStorageUsage() async {
    try {
      final int folderSize = await _storageService.getFolderSize(StorageFolders.products);
      final String formattedSize = FirebaseStorageService.formatBytes(folderSize);
      
      _showSnackBar('Products folder size: $formattedSize', Colors.blue);
    } catch (e) {
      _showSnackBar('Error checking storage: $e', Colors.red);
    }
  }

  Future<void> _listImagesInFolder() async {
    try {
      final List<String> imageUrls = await _storageService.getImagesInFolder(StorageFolders.products);
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Images in Products Folder'),
          content: SizedBox(
            width: double.maxFinite,
            height: 300,
            child: imageUrls.isEmpty
                ? const Center(child: Text('No images found'))
                : ListView.builder(
                    itemCount: imageUrls.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: CachedImageWidget(
                          imageUrl: imageUrls[index],
                          width: 50,
                          height: 50,
                        ),
                        title: Text('Image ${index + 1}'),
                        subtitle: Text(
                          imageUrls[index],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    },
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
    } catch (e) {
      _showSnackBar('Error listing images: $e', Colors.red);
    }
  }

  Future<void> _deleteUploadedImage() async {
    if (_uploadedImageUrl == null) return;

    final bool success = await _storageService.deleteImage(_uploadedImageUrl!);
    
    if (success) {
      setState(() {
        _uploadedImageUrl = null;
      });
      _showSnackBar('Image deleted successfully', Colors.green);
    } else {
      _showSnackBar('Failed to delete image', Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Example of how to use the service in a product creation form
class ProductCreationExample extends StatefulWidget {
  const ProductCreationExample({super.key});

  @override
  State<ProductCreationExample> createState() => _ProductCreationExampleState();
}

class _ProductCreationExampleState extends State<ProductCreationExample> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _mainImageUrl;
  List<String> _galleryImages = [];

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Product'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          TextButton(
            onPressed: _saveProduct,
            child: const Text('Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Name
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Product Name *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter product name';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Price
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Price *',
                  prefixText: '₹ ',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter price';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Description
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Main Product Image
              AdminImageUploadWidget(
                folder: StorageFolders.products,
                label: 'Main Product Image',
                required: true,
                width: double.infinity,
                height: 200,
                onImageUploaded: (url) {
                  setState(() {
                    _mainImageUrl = url;
                  });
                },
              ),
              
              const SizedBox(height: 24),
              
              // Gallery Images
              MultiImageUploadWidget(
                folder: StorageFolders.products,
                maxImages: 5,
                onImagesChanged: (urls) {
                  setState(() {
                    _galleryImages = urls;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Save Product',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _saveProduct() {
    if (_formKey.currentState!.validate()) {
      if (_mainImageUrl == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please upload a main product image'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      // Here you would save the product to Firestore
      final productData = {
        'name': _nameController.text,
        'price': double.parse(_priceController.text),
        'description': _descriptionController.text,
        'mainImage': _mainImageUrl,
        'galleryImages': _galleryImages,
        'createdAt': DateTime.now().toIso8601String(),
      };

      print('Product data to save: $productData');
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Product saved successfully!'),
          backgroundColor: Colors.green,
        ),
      );
      
      Navigator.pop(context);
    }
  }
}
