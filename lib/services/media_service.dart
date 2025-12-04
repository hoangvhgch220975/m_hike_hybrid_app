// lib/services/media_service.dart

import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Service for handling all operations related to media (images, videos)
class MediaService {
  final ImagePicker _picker = ImagePicker();

  // ============= IMAGE OPERATIONS =============

  /// Capture an image with the camera (Feature 8)
  Future<String?> pickImageFromCamera() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking image from camera: $e');
      return null;
    }
  }

  /// Pick a single image from the gallery
  Future<String?> pickImageFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Pick multiple images from the gallery (Feature 9: Multi Images)
  Future<List<String>> pickMultiImage({int? maxImages}) async {
    try {
      final List<XFile> xFiles = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      // Limit number of images if needed
      List<XFile> selectedFiles = maxImages != null && xFiles.length > maxImages
          ? xFiles.sublist(0, maxImages)
          : xFiles;

      return selectedFiles.map((x) => x.path).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }

  // ============= VIDEO OPERATIONS =============

  /// Pick a video from the gallery
  Future<String?> pickVideoFromGallery() async {
    try {
      final XFile? xFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Limit 5 minutes
      );
      return xFile?.path;
    } catch (e) {
      print('Error picking video from gallery: $e');
      return null;
    }
  }

  /// Record a video using the camera
  Future<String?> recordVideoFromCamera() async{
    try {
      final XFile? xFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );
      return xFile?.path;
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  /// Pick multiple videos from the gallery
  Future<List<String>> pickMultiVideo({int? maxVideos}) async {
    try {
      // Note: pickMultiVideo is not available in ImagePicker
      // Need to call pickVideo multiple times or use the file_picker package
      // This is a simple workaround
      List<String> videoPaths = [];

      int limit = maxVideos ?? 5;
      for (int i = 0; i < limit; i++) {
        final path = await pickVideoFromGallery();
        if (path != null) {
          videoPaths.add(path);
        } else {
          break; // User canceled selection
        }
      }

      return videoPaths;
    } catch (e) {
      print('Error picking multiple videos: $e');
      return [];
    }
  }

  // ============= FILE VALIDATION =============

  /// Check whether the file exists
  bool isFileExists(String path) {
    return File(path).existsSync();
  }

  /// Get file size (bytes)
  int getFileSize(String path) {
    try {
      return File(path).lengthSync();
    } catch (e) {
      print('Error getting file size: $e');
      return 0;
    }
  }

  /// Get file size (MB)
  double getFileSizeMB(String path) {
    int bytes = getFileSize(path);
    return bytes / (1024 * 1024);
  }

  /// Validate image (size and extension)
  bool validateImage(String path, {double maxSizeMB = 10}) {
    if (!isFileExists(path)) return false;

    double sizeMB = getFileSizeMB(path);
    if (sizeMB > maxSizeMB) return false;

    String ext = path.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(ext);
  }

  /// Validate video (size and extension)
  bool validateVideo(String path, {double maxSizeMB = 50}) {
    if (!isFileExists(path)) return false;

    double sizeMB = getFileSizeMB(path);
    if (sizeMB > maxSizeMB) return false;

    String ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'avi', 'mkv', '3gp'].contains(ext);
  }

  // ============= FILE OPERATIONS =============

  /// Delete a file
  Future<bool> deleteFile(String path) async {
    try {
      File file = File(path);
      if (file.existsSync()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      print('Error deleting file: $e');
      return false;
    }
  }

  /// Delete multiple files
  Future<void> deleteMultipleFiles(List<String> paths) async {
    for (String path in paths) {
      await deleteFile(path);
    }
  }

  /// Determine media type from extension
  String getMediaType(String path) {
    String ext = path.split('.').last.toLowerCase();
    if (['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'].contains(ext)) {
      return 'image';
    } else if (['mp4', 'mov', 'avi', 'mkv', '3gp', 'webm'].contains(ext)) {
      return 'video';
    }
    return 'unknown';
  }

  /// Check if the path points to an image
  bool isImage(String path) {
    return getMediaType(path) == 'image';
  }

  /// Check if the path points to a video
  bool isVideo(String path) {
    return getMediaType(path) == 'video';
  }

  // ============= COMPRESSION (Optional - requires packages) =============

  /// Note: To compress images/videos, add packages:
  /// - flutter_image_compress
  /// - video_compress
  /// Can be implemented later if needed
}

