import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/utils/image_picker_util.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/user_view_model.dart';

class EditProfileSheet extends StatefulWidget {
  final UserModel user;

  const EditProfileSheet({super.key, required this.user});

  @override
  State<EditProfileSheet> createState() => _EditProfileSheetState();
}

class _EditProfileSheetState extends State<EditProfileSheet> {
  late TextEditingController _nameController;
  late TextEditingController _bioController;
  File? _imageFile;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _bioController = TextEditingController(text: widget.user.bio);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _handleImagePick() async {
    final File? pickedImage =
        await ImagePickerUtil.showImagePickerOptions(context);

    if (pickedImage != null) {
      setState(() {
        _imageFile = pickedImage;
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('No image selected'),
          backgroundColor: Colors.red,
        ));
      }
    }
  }

  Future<void> _saveProfile(BuildContext context) async {
    setState(() => _isUploading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);

    try {
      final userViewModel = context.read<UserViewModel>();
      final authViewModel = context.read<AuthViewModel>();
      final userId = authViewModel.currentUser!.id;

      if (_imageFile != null) {
        final pictureSuccess = await userViewModel.updateProfilePicture(
          userId: userId,
          imageFile: _imageFile!,
        );

        if (!pictureSuccess) {
          if (!mounted) return;
          router.pop();
          scaffoldMessenger.showSnackBar(
            const SnackBar(content: Text('Failed to update profile picture')),
          );
          return;
        }
      }

      final success = await userViewModel.updateProfile(
        userId: userId,
        name: _nameController.text,
        bio: _bioController.text,
      );

      if (!mounted) return;
      router.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(success
              ? 'Profile updated successfully'
              : 'Failed to update profile'),
          backgroundColor: success ? Colors.green : Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      router.pop();
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Edit Profile',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _handleImagePick,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!) as ImageProvider
                        : widget.user.profilePicture != null
                            ? CachedNetworkImageProvider(
                                widget.user.profilePicture!)
                            : null,
                    child: (_imageFile == null &&
                            widget.user.profilePicture == null)
                        ? const Icon(Icons.person, size: 50)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _bioController,
              decoration: const InputDecoration(
                labelText: 'Bio',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _saveProfile(context),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
