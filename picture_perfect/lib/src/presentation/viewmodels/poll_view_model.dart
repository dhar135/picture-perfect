import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/core/utils/image_picker_util.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/core/utils/result.dart';
import 'package:picture_perfect/src/data/models/poll_model.dart';
import 'package:picture_perfect/src/data/repositories/poll_repository.dart';

enum PollViewState { initial, loading, success, error }

class PollViewModel extends ChangeNotifier {
  final PollRepository _pollRepository;

  // State management
  PollViewState _state = PollViewState.initial;
  String? _errorMessage;
  final List<PollModel> _polls = [];
  List<PollModel> _trendingPolls = [];

  // Draft Management
  PollModel? _draftPoll;
  PollModel? get draftPoll => _draftPoll;

  // Getters
  PollViewState get state => _state;
  String? get errorMessage => _errorMessage;
  List<PollModel> get polls => _polls;
  List<PollModel> get trendingPolls => _trendingPolls;

  PollViewModel(this._pollRepository);

  DocumentSnapshot? _lastDocument;
  bool _hasMorePolls = true;

  // Create new poll
  Future<bool> createPoll(
      {required String creatorId,
      required String title,
      String? description,
      required ImageData imageOne,
      required ImageData imageTwo,
      String? captionOne,
      String? captionTwo,
      PollCategory category = PollCategory.other,
      PollVotingType votingType = PollVotingType.nonAnonymous,
      DateTime? deadline,
      required PollStatus status}) async {
    try {
      AppLogger.info('Creating new poll: Title:$title for user:$creatorId');
      _setState(PollViewState.loading);

      final result = await _pollRepository.createPoll(
          creatorId: creatorId,
          title: title,
          description: description,
          imageOne: imageOne,
          imageTwo: imageTwo,
          captionOne: captionOne,
          captionTwo: captionTwo,
          category: category,
          votingType: votingType,
          deadline: deadline,
          status: status);

      if (result is Success<PollModel>) {
        _polls.insert(0, result.data);
        _setState(PollViewState.success);
        AppLogger.info('Successfully created poll, $title');
        notifyListeners();
        return true;
      } else if (result is Failure<PollModel>) {
        _setError(result.message);
        _setState(PollViewState.error);
        AppLogger.error('Failed to create poll: ${result.message}');
        return false;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error creating poll:', e, stackTrace);
      _setError('Unexpected error: $e');
      _setState(PollViewState.error);
      return false;
    }
  }

  // Vote on a poll
  Future<void> votePoll({
    required String pollId,
    required String userId,
    required String selectedImage,
  }) async {
    AppLogger.info("Attempting to vote on poll, $pollId");
    _setState(PollViewState.loading);

    final voteRecord = VoteRecord(
      userId: userId,
      selectedImageId: selectedImage,
      timestamp: DateTime.now(),
    );

    final result = await _pollRepository.votePoll(
      pollId: pollId,
      userId: userId,
      selectedImage: selectedImage,
      voteRecord: voteRecord,
    );

    if (result is Success<PollModel>) {
      _updatePollVotes(pollId, userId, selectedImage);
      _setState(PollViewState.success);
      AppLogger.info('Vote successful');
    } else if (result is Failure<PollModel>) {
      _setError(result.message);
      _setState(PollViewState.error);
      AppLogger.error("Failed to case vote: ${result.message}");
    }
  }

  // Fetch polls with pagination
  Future<void> fetchPolls({
    PollCategory? category,
    String? followedUserId,
    int limit = 20,
    bool refresh = false,
  }) async {
    try {
      if (refresh) {
        _lastDocument = null;
        _polls.clear();
        _hasMorePolls = true;
      }

      if (!_hasMorePolls) return;

      _setState(PollViewState.loading);

      final result = await _pollRepository.fetchPolls(
        category: category,
        followedUserId: followedUserId,
        limit: limit,
        lastDocument: _lastDocument,
      );

      if (result is Success<List<PollModel>>) {
        if (result.data.isEmpty) {
          _hasMorePolls = false;
        } else {
          _polls.addAll(result.data);
          _lastDocument = result.lastDocument;
        }
        _setState(PollViewState.success);
      } else if (result is Failure<List<PollModel>>) {
        _setError(result.message);
      }
    } catch (e) {
      _setError(e.toString());
    }
  }

  // Fetch trending polls
  Future<void> fetchTrendingPolls() async {
    AppLogger.info('Attempting to fetch trending polls');
    final result = await _pollRepository.getTrendingPolls();

    if (result is Success<List<PollModel>>) {
      _trendingPolls = result.data;
      _setState(PollViewState.success);
      AppLogger.info('Successfully fetched trending polls');
    } else if (result is Failure<List<PollModel>>) {
      _setState(PollViewState.error);
      _setError(result.message);
      AppLogger.error("Error fetching trending polls: $_errorMessage");
    }
  }

  // Draft Management
  Future<void> saveDraft(
      {required String creatorId,
      required String title,
      String? description,
      File? imageOne,
      File? imageTwo,
      String? captionOne,
      String? captionTwo,
      PollCategory category = PollCategory.other,
      PollVotingType votingType = PollVotingType.nonAnonymous,
      DateTime? deadline}) async {
    // Save Current Input as draft
    _draftPoll = PollModel(
        id: 'draft_${DateTime.now().millisecondsSinceEpoch}',
        creatorId: creatorId,
        title: title,
        description: description,
        imageOne: imageOne?.path ?? '',
        imageTwo: imageTwo?.path ?? '',
        captionOne: captionOne,
        captionTwo: captionTwo,
        createdAt: DateTime.now(),
        category: category,
        votingType: votingType,
        deadline: deadline,
        status: PollStatus.draft);
    notifyListeners();
  }

  // Validaiton Logic
  String? validatePollCreation(
      {required String title,
      required File? imageOne,
      required File? imageTwo}) {
    if (title.isEmpty) {
      return 'Title is required';
    }
    if (imageOne == null || imageTwo == null) {
      return 'Two images are required';
    }
    if (!imageOne.existsSync() || !imageTwo.existsSync()) {
      return 'Invalid image files';
    }
    return null;
  }

  // Helper methods
  void _setState(PollViewState newState) {
    if (_state != newState) {
      _state = newState;
      _errorMessage = null;
      notifyListeners();
    }
  }

  void _setError(String message) {
    _state = PollViewState.error;
    _errorMessage = message;
    notifyListeners();
  }

  void _updatePollVotes(String pollId, String userId, String selectedImage) {
    final pollIndex = _polls.indexWhere((poll) => poll.id == pollId);
    if (pollIndex != -1) {
      final newVote = VoteRecord(
        userId: userId,
        selectedImageId: selectedImage,
        timestamp: DateTime.now(),
      );

      final updatedVotes = Map<String, VoteRecord>.from(_polls[pollIndex].votes)
        ..[userId] = newVote;

      final updatedPoll = _polls[pollIndex].copyWith(
        votes: updatedVotes,
        totalVotes: _polls[pollIndex].totalVotes + 1,
      );

      _polls[pollIndex] = updatedPoll;
      notifyListeners();
    }
  }

  Future<PollModel?> getPollById(String id, {bool forceRefresh = false}) async {
    if (forceRefresh) {
      _polls.removeWhere((poll) => poll.id == id);
    }

    try {
      return await _pollRepository.getPollById(id);
    } catch (e) {
      AppLogger.error('Error fetching poll by ID: $e');
      return null;
    }
  }

  Future<bool> updatePoll({
    required String pollId,
    required String title,
    String? description,
    String? captionOne,
    String? captionTwo,
    PollCategory? category,
    DateTime? deadline,
  }) async {
    try {
      AppLogger.info('Updating poll: $pollId');
      _setState(PollViewState.loading);

      final result = await _pollRepository.updatePoll(
        pollId: pollId,
        title: title,
        description: description,
        captionOne: captionOne,
        captionTwo: captionTwo,
        category: category,
        deadline: deadline,
      );

      if (result is Success<PollModel>) {
        final index = _polls.indexWhere((poll) => poll.id == pollId);
        if (index != -1) {
          _polls[index] = result.data;
        }
        _setState(PollViewState.success);
        AppLogger.info('Successfully updated poll: $pollId');
        return true;
      } else if (result is Failure<PollModel>) {
        _setError(result.message);
        _setState(PollViewState.error);
        AppLogger.error('Failed to update poll: ${result.message}');
        return false;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error updating poll:', e, stackTrace);
      _setError('Unexpected error: $e');
      _setState(PollViewState.error);
      return false;
    }
  }

  Future<bool> deletePoll(String pollId, String userId) async {
    try {
      AppLogger.info('Deleting poll: $pollId');
      _setState(PollViewState.loading);

      final result = await _pollRepository.deletePoll(
        pollId: pollId,
        userId: userId,
      );

      if (result is Success<void>) {
        _polls.removeWhere((poll) => poll.id == pollId);
        _setState(PollViewState.success);
        AppLogger.info('Successfully deleted poll: $pollId');
        return true;
      } else if (result is Failure<void>) {
        _setError(result.message);
        _setState(PollViewState.error);
        AppLogger.error('Failed to delete poll: ${result.message}');
        return false;
      }
      return false;
    } catch (e, stackTrace) {
      AppLogger.error('Unexpected error deleting poll:', e, stackTrace);
      _setError('Unexpected error: $e');
      _setState(PollViewState.error);
      return false;
    }
  }
}
