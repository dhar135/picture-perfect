import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:picture_perfect/src/core/utils/image_picker_util.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';

import '../../core/utils/result.dart';
import '../models/poll_model.dart';

class PollRepository {
  final FirebaseFirestore _firestore;
  final FirebaseStorage _storage;
  final String pollCollection = 'polls';
  final String userCollection = 'users';
  final _cache = <String, PollModel>{};
  static const int _cacheMaxSize = 100;

  PollRepository({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _storage = storage ?? FirebaseStorage.instance;

  // Create a new poll
  Future<Result<PollModel>> createPoll(
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
      final imageOneUrl = await uploadImageData(imageOne, creatorId);
      final imageTwoUrl = await uploadImageData(imageTwo, creatorId);
      final pollRef = _firestore.collection(pollCollection).doc();

      final pollData = PollModel(
        id: pollRef.id,
        title: title,
        description: description,
        creatorId: creatorId,
        imageOne: imageOneUrl,
        imageTwo: imageTwoUrl,
        captionOne: captionOne,
        captionTwo: captionTwo,
        category: category,
        votingType: votingType,
        createdAt: DateTime.now(),
        deadline: deadline,
        status: status,
        votes: {},
        totalVotes: 0,
      );

      await pollRef.set(pollData.toJson());

      await _firestore.collection(userCollection).doc(creatorId).update({
        'createdPolls': FieldValue.arrayUnion([pollRef.id])
      });

      return Success(pollData);
    } catch (e) {
      return Failure(message: 'Failed to create poll: $e');
    }
  }

  // Upload image to Firebase Storage
  Future<String> uploadImageData(ImageData imageData, String userId) async {
    final String fileName =
        '${DateTime.now().millisecondsSinceEpoch}_$userId.jpg';
    final storageRef = _storage.ref().child('poll_images/$fileName');

    UploadTask uploadTask;
    if (imageData.isWeb) {
      uploadTask = storageRef.putData(imageData.data);
    } else {
      uploadTask = storageRef.putFile(imageData.data);
    }

    await uploadTask;
    return await storageRef.getDownloadURL();
  }

  // Vote on a poll
  Future<Result<PollModel>> votePoll({
    required String pollId,
    required String userId,
    required String selectedImage,
    required VoteRecord voteRecord,
  }) async {
    try {
      final pollRef = _firestore.collection(pollCollection).doc(pollId);
      final userRef = _firestore.collection(userCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final pollSnapshot = await transaction.get(pollRef);
        if (!pollSnapshot.exists) {
          throw Exception('Poll does not exist');
        }

        final pollData = PollModel.fromDocument(pollSnapshot);

        if (pollData.votes.containsKey(userId)) {
          throw Exception('User has already voted');
        }

        if (pollData.deadline != null &&
            DateTime.now().isAfter(pollData.deadline!)) {
          throw Exception('Voting deadline has passed');
        }

        // Update with VoteRecord instead of just the selected image
        transaction.update(pollRef, {
          'votes.$userId': voteRecord.toJson(),
          'totalVotes': FieldValue.increment(1),
        });

        transaction.update(userRef, {
          'votedPolls': FieldValue.arrayUnion([pollId])
        });
      });

      // Fetch and return updated poll
      final updatedPollDoc = await pollRef.get();
      final updatedPoll = PollModel.fromDocument(updatedPollDoc);
      return Success(updatedPoll);
    } catch (e) {
      return Failure(message: 'Failed to vote on poll: $e');
    }
  }

  Future<Result<List<PollModel>>> fetchPolls({
    PollCategory? category,
    String? followedUserId,
    int limit = 20,
    DocumentSnapshot? lastDocument,
  }) async {
    try {
      AppLogger.debug(
          'Fetching polls with params: category: $category, followedUserId: $followedUserId, limit: $limit');

      Query query = _firestore.collection(pollCollection);

      if (category != null) {
        query = query.where('category',
            isEqualTo: category.toString().split('.').last);
      }

      query = query.orderBy('createdAt', descending: true).limit(limit);

      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      final snapshot = await query.get();
      final polls = <PollModel>[];

      for (var doc in snapshot.docs) {
        try {
          final poll = PollModel.fromDocument(doc);
          polls.add(poll);
        } catch (e, stackTrace) {
          AppLogger.error(
              'Failed to parse poll document ${doc.id}', e, stackTrace);
          // Log error but continue processing other documents
          continue;
        }
      }

      return Success(
        polls,
        lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : null,
      );
    } catch (e, stackTrace) {
      AppLogger.error('Failed to fetch polls', e, stackTrace);
      return Failure(message: 'Failed to fetch polls: $e');
    }
  }

  // Get trending polls
  Future<Result<List<PollModel>>> getTrendingPolls({
    int limit = 10,
  }) async {
    try {
      final query = _firestore
          .collection(pollCollection)
          .orderBy('totalVotes', descending: true)
          .limit(limit);

      final snapshot = await query.get();
      final polls =
          snapshot.docs.map((doc) => PollModel.fromDocument(doc)).toList();

      return Success(polls);
    } catch (e) {
      return Failure(message: 'Failed to fetch trending polls', error: e);
    }
  }

  // Delete a poll
  Future<Result<void>> deletePoll({
    required String pollId,
    required String userId,
  }) async {
    try {
      final pollRef = _firestore.collection(pollCollection).doc(pollId);
      final userRef = _firestore.collection(userCollection).doc(userId);

      await _firestore.runTransaction((transaction) async {
        final pollSnapshot = await transaction.get(pollRef);
        if (!pollSnapshot.exists) {
          throw Exception('Poll does not exist');
        }

        final pollData = PollModel.fromDocument(pollSnapshot);

        // Ensure only the creator can delete the poll
        if (pollData.creatorId != userId) {
          throw Exception('Only the creator can delete this poll');
        }

        // Delete poll from Firestore
        transaction.delete(pollRef);

        // Remove poll ID from user's created polls
        transaction.update(userRef, {
          'createdPolls': FieldValue.arrayRemove([pollId])
        });

        // Optional: Delete associated images from storage
        await _deleteAssociatedImages(pollData);
      });

      return const Success(null);
    } catch (e) {
      return Failure(message: 'Failed to delete poll', error: e);
    }
  }

  // Delete associated poll images from storage
  Future<void> _deleteAssociatedImages(PollModel poll) async {
    try {
      final imageOneRef = _storage.refFromURL(poll.imageOne);
      final imageTwoRef = _storage.refFromURL(poll.imageTwo);

      await Future.wait([
        imageOneRef.delete(),
        imageTwoRef.delete(),
      ]);
    } catch (_) {
      // Ignore errors if images are already deleted
    }
  }

  // Cached poll fetch
  Future<Result<PollModel>> getPoll(String pollId) async {
    try {
      // Check cache first
      if (_cache.containsKey(pollId)) {
        return Success(_cache[pollId]!);
      }

      final doc = await _firestore.collection(pollCollection).doc(pollId).get();
      if (!doc.exists) {
        return const Failure(message: 'Poll not found');
      }

      final poll = PollModel.fromDocument(doc);

      // Add to cache
      if (_cache.length >= _cacheMaxSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[pollId] = poll;

      return Success(poll);
    } catch (e) {
      return Failure(message: 'Failed to fetch poll', error: e);
    }
  }

  Future<PollModel?> getPollById(String pollId) async {
    try {
      final doc = await _firestore.collection('polls').doc(pollId).get();
      if (doc.exists) {
        return PollModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      AppLogger.error('Error in getPollById: $e');
      return null;
    }
  }

  Future<Result<PollModel>> updatePoll({
    required String pollId,
    required String title,
    String? description,
    String? captionOne,
    String? captionTwo,
    PollCategory? category,
    DateTime? deadline,
  }) async {
    try {
      final pollRef = _firestore.collection('polls').doc(pollId);
      await pollRef.update({
        'title': title,
        'description': description,
        'captionOne': captionOne,
        'captionTwo': captionTwo,
        if (category != null) 'category': category.name,
        if (deadline != null) 'deadline': deadline.toIso8601String(),
      });

      final updatedPoll = await getPollById(pollId);
      return Success(updatedPoll!);
    } catch (e) {
      return Failure(message: 'Failed to update poll: $e');
    }
  }
}
