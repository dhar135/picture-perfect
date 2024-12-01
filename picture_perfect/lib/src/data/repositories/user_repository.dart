// lib/data/repositories/user_repository.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';

import '../../core/utils/image_picker_util.dart';
import '../../core/utils/result.dart';
import '../models/user_model.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String collection = 'users';

  UserRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Create new user document
  Future<Result<UserModel>> createUser(auth.User firebaseUser) async {
    try {
      final user = UserModel.fromFirebaseUser(firebaseUser);
      await _firestore.collection(collection).doc(user.id).set(user.toJson());
      return Success(user);
    } catch (e) {
      return Failure(
        message: 'Failed to create user profile',
        error: e,
      );
    }
  }

  // Get user by ID
  Future<Result<UserModel>> getUserById(String userId) async {
    try {
      final doc = await _firestore.collection(collection).doc(userId).get();

      if (!doc.exists) {
        return const Failure(message: 'User not found');
      }

      return Success(UserModel.fromDocument(doc));
    } catch (e) {
      return Failure(
        message: 'Failed to fetch user profile',
        error: e,
      );
    }
  }

  // Update user profile
  Future<Result<UserModel>> updateProfile({
    required String userId,
    String? name,
    String? bio,
  }) async {
    try {
      final userRef = _firestore.collection(collection).doc(userId);

      final updates = <String, dynamic>{
        if (name != null) 'name': name,
        if (bio != null) 'bio': bio,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      };

      await userRef.update(updates);

      final updatedDoc = await userRef.get();
      return Success(UserModel.fromDocument(updatedDoc));
    } catch (e) {
      return Failure(
        message: 'Failed to update profile',
        error: e,
      );
    }
  }

  // Update profile picture
  Future<Result<String>> updateProfilePicture({
    required String userId,
    required ImageData imageData,
  }) async {
    try {
      if (!imageData.isWeb && !await imageData.data.exists()) {
        return const Failure(message: 'Image file does not exist');
      }

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '$timestamp.jpg';
      final storageRef = _storage
          .ref()
          .child('profile_pictures')
          .child(userId)
          .child(fileName);

      final metadata = SettableMetadata(
        contentType: 'image/jpeg',
        customMetadata: {
          'userId': userId,
          'uploadTime': DateTime.now().toIso8601String(),
        },
      );

      if (imageData.isWeb) {
        await storageRef.putData(imageData.data, metadata);
      } else {
        await storageRef.putFile(imageData.data, metadata);
      }

      final imageUrl = await storageRef.getDownloadURL();
      await _firestore.collection(collection).doc(userId).update({
        'profilePicture': imageUrl,
        'lastUpdatedAt': FieldValue.serverTimestamp(),
      });

      return Success(imageUrl);
    } catch (e) {
      AppLogger.error('Profile picture upload error: $e');
      return Failure(message: 'Failed to update profile picture', error: e);
    }
  }

  // Update user statistics
  Future<Result<void>> updateStats({
    required String userId,
    int? followersDelta,
    int? followingDelta,
    int? postsDelta,
  }) async {
    try {
      final updates = <String, dynamic>{
        if (followersDelta != null)
          'followers': FieldValue.increment(followersDelta),
        if (followingDelta != null)
          'following': FieldValue.increment(followingDelta),
        if (postsDelta != null) 'posts': FieldValue.increment(postsDelta),
      };

      if (updates.isNotEmpty) {
        await _firestore.collection(collection).doc(userId).update(updates);
      }

      return const Success(null);
    } catch (e) {
      return Failure(
        message: 'Failed to update user statistics',
        error: e,
      );
    }
  }

  // Save/unsave a poll
  Future<Result<void>> toggleSavedPoll({
    required String userId,
    required String pollId,
    required bool save,
  }) async {
    try {
      final userRef = _firestore.collection(collection).doc(userId);

      if (save) {
        await userRef.update({
          'savedPosts': FieldValue.arrayUnion([pollId]),
        });
      } else {
        await userRef.update({
          'savedPosts': FieldValue.arrayRemove([pollId]),
        });
      }

      return const Success(null);
    } catch (e) {
      return Failure(
        message: 'Failed to update saved polls',
        error: e,
      );
    }
  }

  // Stream user data changes
  Stream<UserModel?> streamUser(String userId) {
    return _firestore
        .collection(collection)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.exists ? UserModel.fromDocument(doc) : null);
  }

  // Get user's saved polls
  Future<Result<List<String>>> getSavedPolls(String userId) async {
    try {
      final doc = await _firestore.collection(collection).doc(userId).get();

      if (!doc.exists) {
        return const Failure(message: 'User not found');
      }

      final userData = UserModel.fromDocument(doc);
      return Success(userData.savedPosts);
    } catch (e) {
      return Failure(
        message: 'Failed to fetch saved polls',
        error: e,
      );
    }
  }

  // Delete user account and all associated data
  Future<Result<void>> deleteUser(String userId) async {
    try {
      // Start a batch write
      final batch = _firestore.batch();

      // Delete user document
      final userRef = _firestore.collection(collection).doc(userId);
      batch.delete(userRef);

      // Delete profile picture from storage
      try {
        await _storage.ref().child('profile_pictures/$userId.jpg').delete();
      } catch (_) {
        // Ignore if profile picture doesn't exist
      }

      // Commit the batch
      await batch.commit();

      return const Success(null);
    } catch (e) {
      return Failure(
        message: 'Failed to delete user account',
        error: e,
      );
    }
  }
}
