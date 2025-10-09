# Firebase Storage Service for Jewelry E-commerce App

A comprehensive Flutter service for handling image uploads, compression, caching, and management using Firebase Storage while staying within the free tier limits.

## Features

✅ **Image Picking** - Camera and gallery support  
✅ **Image Compression** - Automatic compression to 100-200KB  
✅ **Firebase Upload** - Secure upload to Firebase Storage  
✅ **Image Caching** - Efficient caching with cached_network_image  
✅ **Image Management** - Delete, list, and manage images  
✅ **Anonymous Auth** - Automatic anonymous authentication  
✅ **Free Tier Optimized** - Designed for Firebase Spark plan  
✅ **Admin & Customer UI** - Ready-to-use widgets  
✅ **Error Handling** - Comprehensive error management  

## Quick Start

### 1. Add Dependencies

Add these to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^2.24.2
  firebase_auth: ^4.15.3
  firebase_storage: ^11.6.0
  image_picker: ^1.0.4
  flutter_image_compress: ^2.1.0
  cached_network_image: ^3.3.0
  uuid: ^4.2.1
  path: ^1.8.3
  shimmer: ^3.0.0
```

### 2. Platform Setup

**iOS (ios/Runner/Info.plist):**
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs access to camera to take photos</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs access to photo library to select images</string>
```

**Android (android/app/src/main/AndroidManifest.xml):**
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### 3. Firebase Storage Rules

Set these rules in Firebase Console:

```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

## Usage Examples

### Admin Image Upload Widget

```dart
AdminImageUploadWidget(
  folder: StorageFolders.products,
  label: 'Product Image',
  required: true,
  onImageUploaded: (url) {
    // Handle uploaded image URL
    print('Image uploaded: $url');
  },
)
```

### Multiple Images Upload

```dart
MultiImageUploadWidget(
  folder: StorageFolders.products,
  maxImages: 5,
  onImagesChanged: (urls) {
    // Handle list of image URLs
    print('Images: $urls');
  },
)
```

### Manual Upload Process

```dart
final FirebaseStorageService _storageService = FirebaseStorageService();

// Pick and upload in one step
String? downloadUrl = await _storageService.pickCompressAndUpload(
  source: ImageSource.gallery,
  folder: StorageFolders.products,
);

// Or step by step
final imageFile = await _storageService.pickImage(source: ImageSource.camera);
final compressedBytes = await _storageService.compressImage(imageFile!);
final downloadUrl = await _storageService.uploadImage(
  imageBytes: compressedBytes!,
  folder: StorageFolders.products,
);
```

### Display Images

```dart
// Product image
ProductImageWidget(
  imageUrl: 'https://your-image-url.com',
  size: 120,
  onTap: () => print('Image tapped'),
)

// Category icon
CategoryIconWidget(
  imageUrl: 'https://your-image-url.com',
  size: 80,
)

// Profile avatar
ProfileAvatarWidget(
  imageUrl: 'https://your-image-url.com',
  size: 60,
  initials: 'JD',
)

// Basic cached image
CachedImageWidget(
  imageUrl: 'https://your-image-url.com',
  width: 200,
  height: 200,
  borderRadius: BorderRadius.circular(12),
)
```

### Storage Management

```dart
// Delete image
await _storageService.deleteImage(imageUrl);

// Get folder size
int folderSize = await _storageService.getFolderSize(StorageFolders.products);
String formattedSize = FirebaseStorageService.formatBytes(folderSize);

// List images in folder
List<String> imageUrls = await _storageService.getImagesInFolder(StorageFolders.products);

// Check if image exists
bool exists = await _storageService.imageExists(imageUrl);
```

## Storage Folders

Predefined folder structure:

```dart
class StorageFolders {
  static const String products = 'products';
  static const String categories = 'categories';
  static const String banners = 'banners';
  static const String profiles = 'profiles';
  static const String reviews = 'reviews';
  static const String temp = 'temp';
}
```

## Free Tier Optimization

### Limits (Firebase Spark Plan)
- **Storage**: 5GB total
- **Downloads**: 1GB/day
- **Uploads**: 20,000/day
- **Operations**: 50,000/day

### Optimizations Applied
- ✅ Image compression to 150KB target
- ✅ Maximum 2MB file size limit
- ✅ Efficient caching to reduce downloads
- ✅ JPEG format for smaller file sizes
- ✅ Automatic quality adjustment based on file size
- ✅ Anonymous authentication (no user management overhead)

## File Structure

```
lib/
├── services/
│   └── firebase_storage_service.dart      # Main service
├── components/
│   ├── cached_image_widget.dart           # Image display widgets
│   └── admin_image_upload_widget.dart     # Upload widgets
└── examples/
    └── image_service_examples.dart        # Usage examples
```

## Error Handling

The service includes comprehensive error handling:

```dart
// All methods return null on error and log to console
String? downloadUrl = await _storageService.uploadImage(...);
if (downloadUrl == null) {
  // Handle upload failure
  print('Upload failed');
}

// Check authentication status
bool isAuthenticated = await _storageService._ensureAuthenticated();

// Validate file sizes
if (fileSize > FirebaseStorageService.maxFileSizeBytes) {
  // File too large
}
```

## Best Practices

### For Admins (Upload)
1. Use `AdminImageUploadWidget` for single images
2. Use `MultiImageUploadWidget` for product galleries
3. Always set appropriate folder names
4. Monitor storage usage with `getFolderSize()`

### For Customers (Display)
1. Use appropriate display widgets for different contexts
2. Set proper dimensions to optimize memory usage
3. Use placeholder and error widgets for better UX
4. Enable shimmer loading for smooth experience

### Performance Tips
1. **Compress before upload** - Always use the compression service
2. **Cache images** - Use CachedNetworkImage for better performance
3. **Optimize dimensions** - Set memCacheWidth/Height for large images
4. **Monitor usage** - Regularly check storage usage to stay within limits
5. **Clean up** - Delete unused images to save storage space

## Troubleshooting

### Common Issues

**Upload fails:**
- Check internet connection
- Verify Firebase configuration
- Ensure user is authenticated
- Check file size limits

**Images not displaying:**
- Verify image URL is valid
- Check Firebase Storage rules
- Ensure proper error handling

**Storage quota exceeded:**
- Monitor usage with `getFolderSize()`
- Delete unused images
- Consider upgrading to paid plan

### Debug Mode

Enable debug prints by setting:
```dart
debugPrint('Your debug message');
```

All service methods include debug logging for troubleshooting.

## Example Integration

See `examples/image_service_examples.dart` for complete working examples including:
- Product creation form
- Image gallery management
- Storage usage monitoring
- Error handling demonstrations

## Support

For issues related to:
- **Firebase**: Check Firebase Console and documentation
- **Image Picker**: Verify platform permissions
- **Compression**: Check device storage and memory
- **Caching**: Clear app cache and restart

## License

This service is part of the SHISHRA jewelry e-commerce app and follows the same licensing terms.
