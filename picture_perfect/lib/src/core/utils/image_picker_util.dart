import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart' as picker;
import 'package:picture_perfect/src/core/utils/logger.dart';

class ImagePickerUtil {
  static final _picker = picker.ImagePicker();

  // Pick an image from the specified source
  // Returns a file if successful, null otherwise
  static Future<File?> pickImage({
    required picker.ImageSource source,
    double? maxWidth = 1000,
    double? maxHeight = 1000,
    int? imageQuality = 85,
  }) async {
    try {
      final pickedFile = await _picker.pickImage(
          source: source,
          maxWidth: maxWidth,
          maxHeight: maxHeight,
          imageQuality: imageQuality);

      if (pickedFile != null) {
        AppLogger.info('Image picked successfully from $source');
        return File(pickedFile.path);
      }

      AppLogger.info('No image selected');
      return null;
    } catch (e) {
      AppLogger.error('Error picking image: $e');
      return null;
    }
  }

  /// Shows a bottom sheet with options to pick image from gallery or camera
  /// Returns a [File] if successful, null otherwise
  static Future<File?> showImagePickerOptions(BuildContext context) async {
    final source = await showModalBottomSheet<picker.ImageSource>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Choose from gallery'),
                onTap: () => Navigator.pop(context, picker.ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.camera),
                title: const Text('Take a photo'),
                onTap: () => Navigator.pop(context, picker.ImageSource.camera),
              )
            ],
          ),
        );
      },
    );

    if (source == null) return null;

    return await pickImage(source: source);
  }
}
