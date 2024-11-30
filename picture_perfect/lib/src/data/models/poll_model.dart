import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';

enum PollCategory { fashion, food, lifestyle, other }

enum PollVotingType { anonymous, nonAnonymous }

enum PollStatus { draft, active, closed }

class PollModel {
  final String id;
  final String creatorId;
  final String title;
  final String? description;
  final String imageOne;
  final String imageTwo;
  final String? captionOne;
  final String? captionTwo;
  final PollCategory category;
  final PollVotingType votingType;
  final DateTime createdAt;
  final DateTime? deadline;
  final Map<String, String> votes;
  final int totalVotes;
  final PollStatus status;

  PollModel(
      {required this.id,
      required this.creatorId,
      required this.title,
      this.description,
      required this.imageOne,
      required this.imageTwo,
      this.captionOne,
      this.captionTwo,
      this.category = PollCategory.other,
      this.votingType = PollVotingType.nonAnonymous,
      required this.createdAt,
      this.deadline,
      this.votes = const {},
      this.totalVotes = 0,
      required this.status});

  bool isActive() {
    if (status == PollStatus.closed) return false;
    if (deadline == null) return true;
    return DateTime.now().isBefore(deadline!);
  }

  // Create from Firestore document
  factory PollModel.fromDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Check required fields
      if (data['creatorId'] == null ||
          data['title'] == null ||
          data['imageOne'] == null ||
          data['imageTwo'] == null) {
        throw FormatException(
            'Document ${doc.id} is missing required fields: ${[
          if (data['creatorId'] == null) 'creatorId',
          if (data['title'] == null) 'title',
          if (data['imageOne'] == null) 'imageOne',
          if (data['imageTwo'] == null) 'imageTwo',
        ].join(', ')}');
      }

      return PollModel(
        id: doc.id,
        creatorId: data['creatorId'].toString(),
        title: data['title'].toString(),
        description: data['description']?.toString(),
        imageOne: data['imageOne'].toString(),
        imageTwo: data['imageTwo'].toString(),
        captionOne: data['captionOne']?.toString(),
        captionTwo: data['captionTwo']?.toString(),
        category: _categoryFromString(data['category']?.toString()),
        votingType: _votingTypeFromString(data['votingType']?.toString()),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        deadline: (data['deadline'] as Timestamp?)?.toDate(),
        votes: (data['votes'] as Map<String, dynamic>?)
                ?.map((key, value) => MapEntry(key, value.toString())) ??
            {},
        totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
        status: _statusFromString(data['status']?.toString()),
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error creating PollModel from document ${doc.id}: $e', e,
          stackTrace);
      rethrow;
    }
  }

  // Helper methods for safer enum conversion
  static PollCategory _categoryFromString(String? value) {
    try {
      return PollCategory.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == value?.toLowerCase(),
        orElse: () => PollCategory.other,
      );
    } catch (_) {
      return PollCategory.other;
    }
  }

  static PollVotingType _votingTypeFromString(String? value) {
    try {
      return PollVotingType.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == value?.toLowerCase(),
        orElse: () => PollVotingType.nonAnonymous,
      );
    } catch (_) {
      return PollVotingType.nonAnonymous;
    }
  }

  static PollStatus _statusFromString(String? value) {
    try {
      return PollStatus.values.firstWhere(
        (e) =>
            e.toString().split('.').last.toLowerCase() == value?.toLowerCase(),
        orElse: () => PollStatus.active,
      );
    } catch (_) {
      return PollStatus.active;
    }
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'imageOne': imageOne,
      'imageTwo': imageTwo,
      'captionOne': captionOne,
      'captionTwo': captionTwo,
      'category': category.toString(),
      'votingType': votingType.toString(),
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'votes': votes,
      'totalVotes': totalVotes,
      'status': status.toString()
    };
  }

  // vote calculation
  Map<String, double> getVotePercentages() {
    if (totalVotes == 0) return {'imageOne': 0.0, 'imageTwo': 0.0};

    int imageOneCount = 0;
    for (var vote in votes.values) {
      if (vote == imageOne) imageOneCount++;
    }

    final imageOnePercentage = (imageOneCount / totalVotes) * 100;
    return {
      'imageOne': imageOnePercentage,
      'imageTwo': 100 - imageOnePercentage,
    };
  }

  // Copywrite method for immutable updates
  PollModel copyWith({
    String? id,
    String? title,
    String? description,
    String? creatorId,
    String? imageOne,
    String? imageTwo,
    String? captionOne,
    String? captionTwo,
    PollCategory? category,
    PollVotingType? votingType,
    DateTime? deadline,
    Map<String, String>? votes,
    int? totalVotes,
    PollStatus? status,
  }) {
    return PollModel(
        id: id ?? this.id,
        title: title ?? this.title,
        description: description ?? this.description,
        creatorId: creatorId ?? this.creatorId,
        imageOne: imageOne ?? this.imageOne,
        imageTwo: imageTwo ?? this.imageTwo,
        captionOne: captionOne ?? this.captionOne,
        captionTwo: captionTwo ?? this.captionTwo,
        category: category ?? this.category,
        votingType: votingType ?? this.votingType,
        createdAt: createdAt,
        deadline: deadline ?? this.deadline,
        votes: votes ?? this.votes,
        totalVotes: totalVotes ?? this.totalVotes,
        status: status ?? this.status);
  }
}
