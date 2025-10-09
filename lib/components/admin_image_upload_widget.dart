import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/firebase_storage_service.dart';
import 'cached_image_widget.dart';

class AdminImageUploadWidget extends StatefulWidget {
  final String folder;
  final String? initialImageUrl;
  final Function(String?) onImageUploaded;
  final double width;
  final double height;
  final String? label;
  final bool required;
  final String? fileName;

  const AdminImageUploadWidget({
    super.key,
    required this.folder,
    required this.onImageUploaded,
    this.initialImageUrl,
    this.width = 200,
    this.height = 200,
    this.label,
    this.required = false,
    this.fileName,
  });

  @override
  State<AdminImageUploadWidget> createState() => _AdminImageUploadWidgetState();
}

class _AdminImageUploadWidgetState extends State<AdminImageUploadWidget> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  String? _currentImageUrl;
  bool _isUploading = false;
  double _uploadProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentImageUrl = widget.initialImageUrl;
  }

  Future<void> _showImageSourceDialog() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Select Image Source',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSourceOption(
                  icon: Icons.camera_alt,
                  label: 'Camera',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.camera);
                  },
                ),
                _buildSourceOption(
                  icon: Icons.photo_library,
                  label: 'Gallery',
                  onTap: () {
                    Navigator.pop(context);
                    _pickAndUploadImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSourceOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          children: [
            Icon(icon, size: 40, color: Colors.black),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(ImageSource source) async {
    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
    });

    try {
      // Pick image
      final XFile? imageFile = await _storageService.pickImage(source: source);
      if (imageFile == null) {
        setState(() => _isUploading = false);
        return;
      }

      setState(() => _uploadProgress = 0.3);

      // Read image bytes
      final Uint8List? imageBytes = await _storageService.readImageBytes(imageFile);
      if (imageBytes == null) {
        _showErrorSnackBar('Failed to read image');
        setState(() => _isUploading = false);
        return;
      }

      setState(() => _uploadProgress = 0.6);

      // Upload image
      final String? downloadUrl = await _storageService.uploadImage(
        imageBytes: imageBytes,
        folder: widget.folder,
        fileName: widget.fileName,
      );

      setState(() => _uploadProgress = 1.0);

      if (downloadUrl != null) {
        // Delete old image if exists
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          await _storageService.deleteImage(_currentImageUrl!);
        }

        setState(() {
          _currentImageUrl = downloadUrl;
          _isUploading = false;
        });

        widget.onImageUploaded(downloadUrl);
        _showSuccessSnackBar('Image uploaded successfully');
      } else {
        _showErrorSnackBar('Failed to upload image');
        setState(() => _isUploading = false);
      }
    } catch (e) {
      _showErrorSnackBar('Error: $e');
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteImage() async {
    if (_currentImageUrl == null) return;

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: const Text('Are you sure you want to delete this image?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isUploading = true);

      final bool success = await _storageService.deleteImage(_currentImageUrl!);
      
      if (success) {
        setState(() {
          _currentImageUrl = null;
          _isUploading = false;
        });
        widget.onImageUploaded(null);
        _showSuccessSnackBar('Image deleted successfully');
      } else {
        _showErrorSnackBar('Failed to delete image');
        setState(() => _isUploading = false);
      }
    }
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Row(
            children: [
              Text(
                widget.label!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.required)
                const Text(
                  ' *',
                  style: TextStyle(
                    color: Colors.red,
                    fontSize: 16,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
        Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey[300]!,
              width: 2,
              style: BorderStyle.solid,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _isUploading
              ? _buildUploadingWidget()
              : _currentImageUrl != null && _currentImageUrl!.isNotEmpty
                  ? _buildImageWidget()
                  : _buildPlaceholderWidget(),
        ),
      ],
    );
  }

  Widget _buildUploadingWidget() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            value: _uploadProgress,
            strokeWidth: 3,
            backgroundColor: Colors.grey[300],
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.black),
          ),
          const SizedBox(height: 12),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Uploading...',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageWidget() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: CachedImageWidget(
            imageUrl: _currentImageUrl!,
            width: widget.width,
            height: widget.height,
            fit: BoxFit.cover,
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: Row(
            children: [
              _buildActionButton(
                icon: Icons.edit,
                onPressed: _showImageSourceDialog,
                color: Colors.blue,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: Icons.delete,
                onPressed: _deleteImage,
                color: Colors.red,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 16,
        ),
      ),
    );
  }

  Widget _buildPlaceholderWidget() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Add Image',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap to upload',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Multiple images upload widget for product galleries
class MultiImageUploadWidget extends StatefulWidget {
  final String folder;
  final List<String> initialImageUrls;
  final Function(List<String>) onImagesChanged;
  final int maxImages;
  final double imageSize;

  const MultiImageUploadWidget({
    super.key,
    required this.folder,
    required this.onImagesChanged,
    this.initialImageUrls = const [],
    this.maxImages = 5,
    this.imageSize = 100,
  });

  @override
  State<MultiImageUploadWidget> createState() => _MultiImageUploadWidgetState();
}

class _MultiImageUploadWidgetState extends State<MultiImageUploadWidget> {
  final FirebaseStorageService _storageService = FirebaseStorageService();
  List<String> _imageUrls = [];
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _imageUrls = List.from(widget.initialImageUrls);
  }

  Future<void> _addImage() async {
    if (_imageUrls.length >= widget.maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Maximum ${widget.maxImages} images allowed'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isUploading = true);

    final String? downloadUrl = await _storageService.pickAndUpload(
      source: ImageSource.gallery,
      folder: widget.folder,
    );

    if (downloadUrl != null) {
      setState(() {
        _imageUrls.add(downloadUrl);
        _isUploading = false;
      });
      widget.onImagesChanged(_imageUrls);
    } else {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _removeImage(int index) async {
    final String imageUrl = _imageUrls[index];
    await _storageService.deleteImage(imageUrl);
    
    setState(() {
      _imageUrls.removeAt(index);
    });
    widget.onImagesChanged(_imageUrls);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Product Images',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: widget.imageSize + 20,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _imageUrls.length + (_imageUrls.length < widget.maxImages ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _imageUrls.length) {
                return _buildAddImageButton();
              }
              return _buildImageItem(index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAddImageButton() {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      margin: const EdgeInsets.only(right: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: _isUploading
          ? const Center(child: CircularProgressIndicator())
          : GestureDetector(
              onTap: _addImage,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: Colors.grey[400], size: 32),
                  const SizedBox(height: 4),
                  Text(
                    'Add',
                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildImageItem(int index) {
    return Container(
      width: widget.imageSize,
      height: widget.imageSize,
      margin: const EdgeInsets.only(right: 8),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedImageWidget(
              imageUrl: _imageUrls[index],
              width: widget.imageSize,
              height: widget.imageSize,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: GestureDetector(
              onTap: () => _removeImage(index),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.close,
                  color: Colors.white,
                  size: 12,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
