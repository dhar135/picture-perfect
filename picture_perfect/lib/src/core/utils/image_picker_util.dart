import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class ImageData {
  final dynamic data; // File for mobile, Uint8List for web
  final bool isWeb;
  ImageData(this.data, this.isWeb);
}

class ImagePickerUtil {
  static final _picker = ImagePicker();

  static Future<ImageData?> showImagePickerOptions(BuildContext context) async {
    if (kIsWeb) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return null;

      final bytes = await image.readAsBytes();
      return ImageData(bytes, true);
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null) return null;

    final XFile? pickedFile = await _picker.pickImage(source: source);
    return pickedFile != null ? ImageData(File(pickedFile.path), false) : null;
  }
}
