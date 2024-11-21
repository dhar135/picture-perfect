import 'dart:io';

import 'package:flutter/material.dart';

import '../../core/utils/logger.dart';
import '../../core/utils/result.dart';
import '../../data/models/user_model.dart';
import '../../data/repositories/user_repository.dart';

enum ProfileUpdateStatus { initial, loading, success, error }

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  UserModel? _user;
  String? _error;
  ProfileUpdateStatus _status = ProfileUpdateStatus.initial;
  bool _isLoading = false;

  UserViewModel(this._userRepository) {
    AppLogger.debug('UserViewModel initialized');
  }

  // Getters
  UserModel? get user => _user;
  String? get error => _error;
  bool get isLoading => _isLoading;
  ProfileUpdateStatus get status => _status;

  // Stream user data
  Stream<UserModel?> streamUserProfile(String userId) {
    AppLogger.debug('Starting user profile stream for userId: $userId');
    return _userRepository.streamUser(userId);
  }

  // Load user profile
  Future<void> loadUserProfile(String userId) async {
    AppLogger.info('Loading user profile for userId: $userId');
    _setLoading(true);
    final result = await _userRepository.getUserById(userId);

    if (result is Success<UserModel>) {
      _user = result.data;
      _clearError();
      AppLogger.info('Successfully loaded user profile for userId: $userId');
    } else if (result is Failure<UserModel>) {
      _setError(result.message);
      AppLogger.error('Failed to load user profile', result.message);
    }
    _setLoading(false);
  }

  // Update profile
  Future<bool> updateProfile({
    required String userId,
    String? name,
    String? bio,
    String? website,
  }) async {
    AppLogger.info('Updating profile for userId: $userId');
    _status = ProfileUpdateStatus.loading;
    notifyListeners();

    final result = await _userRepository.updateProfile(
      userId: userId,
      name: name,
      bio: bio,
      website: website,
    );

    if (result is Success<UserModel>) {
      _user = result.data;
      _status = ProfileUpdateStatus.success;
      _clearError();
      notifyListeners();
      AppLogger.info('Successfully updated profile for userId: $userId');
      return true;
    } else if (result is Failure<UserModel>) {
      _setError(result.message);
      _status = ProfileUpdateStatus.error;
      notifyListeners();
      AppLogger.error('Failed to update profile', result.message);
      return false;
    }
    return false;
  }

  // Update profile picture
  Future<bool> updateProfilePicture({
    required String userId,
    required File imageFile,
  }) async {
    AppLogger.info('Updating profile picture for userId: $userId');
    _setLoading(true);
    final result = await _userRepository.updateProfilePicture(
      userId: userId,
      imageFile: imageFile,
    );

    if (result is Success<String>) {
      await loadUserProfile(userId);
      _clearError();
      _setLoading(false);
      AppLogger.info(
          'Successfully updated profile picture for userId: $userId');
      return true;
    } else if (result is Failure<String>) {
      _setError(result.message);
      _setLoading(false);
      AppLogger.error('Failed to update profile picture', result.message);
      return false;
    }
    return false;
  }

  // Toggle saved poll
  Future<bool> toggleSavedPoll({
    required String userId,
    required String pollId,
    required bool save,
  }) async {
    AppLogger.info(
        'Toggling saved poll (${save ? 'save' : 'unsave'}) for userId: $userId, pollId: $pollId');
    final result = await _userRepository.toggleSavedPoll(
      userId: userId,
      pollId: pollId,
      save: save,
    );

    if (result is Success<void>) {
      await loadUserProfile(userId);
      AppLogger.info(
          'Successfully toggled saved poll for userId: $userId, pollId: $pollId');
      return true;
    } else if (result is Failure<void>) {
      _setError(result.message);
      AppLogger.error('Failed to toggle saved poll', result.message);
      return false;
    }
    return false;
  }

  // Get saved polls
  Future<List<String>> getSavedPolls(String userId) async {
    AppLogger.info('Fetching saved polls for userId: $userId');
    final result = await _userRepository.getSavedPolls(userId);

    if (result is Success<List<String>>) {
      AppLogger.info(
          'Successfully retrieved ${result.data.length} saved polls for userId: $userId');
      return result.data;
    } else if (result is Failure<List<String>>) {
      _setError(result.message);
      AppLogger.error('Failed to get saved polls', result.message);
      return [];
    }
    return [];
  }

  // Update user stats
  Future<void> updateStats({
    required String userId,
    int? followersDelta,
    int? followingDelta,
    int? postsDelta,
  }) async {
    AppLogger.info(
        'Updating stats for userId: $userId - Followers: $followersDelta, Following: $followingDelta, Posts: $postsDelta');
    final result = await _userRepository.updateStats(
      userId: userId,
      followersDelta: followersDelta,
      followingDelta: followingDelta,
      postsDelta: postsDelta,
    );

    if (result is Failure<void>) {
      _setError(result.message);
      AppLogger.error('Failed to update user stats', result.message);
    } else {
      AppLogger.info('Successfully updated stats for userId: $userId');
    }
  }

  // Helper methods
  void _setLoading(bool value) {
    _isLoading = value;
    AppLogger.debug('Loading state changed to: $value');
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    AppLogger.warning('Error set: $error');
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    AppLogger.debug('Error cleared');
    notifyListeners();
  }
}
