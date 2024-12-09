import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';

/// Represents different categories a poll can belong to
enum PollCategory {
  fashion,
  food,
  lifestyle,
  beauty,
  travel,
  technology,
  pets,
  fitness,
  home,
  entertainment,
  art,
  sports,
  other
}

/// Defines whether votes in a poll are anonymous or not
enum PollVotingType { anonymous, nonAnonymous }

/// Represents the current status of a poll
enum PollStatus { draft, active, closed }

/// Exception thrown when poll-related operations fail
class PollException implements Exception {
  final String message;
  PollException(this.message);

  @override
  String toString() => 'PollException: $message';
}

/// Represents a single vote in a poll
class VoteRecord {
  final String userId;
  final String selectedImageId;
  final DateTime timestamp;

  const VoteRecord({
    required this.userId,
    required this.selectedImageId,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'selectedImageId': selectedImageId,
        'timestamp': Timestamp.fromDate(timestamp),
      };

  factory VoteRecord.fromJson(Map<String, dynamic> json) {
    return VoteRecord(
      userId: json['userId'] as String,
      selectedImageId: json['selectedImageId'] as String,
      timestamp: (json['timestamp'] as Timestamp).toDate(),
    );
  }
}

/// Represents a poll where users can vote between two images
///
/// A poll has a title, two images to choose from, and various metadata about
/// its status, voting type, and category. It supports both anonymous and
/// non-anonymous voting, and can be set to close at a specific deadline.
class PollModel {
  static const double defaultPercentage = 0.0;

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
  final Map<String, VoteRecord> votes;
  final int totalVotes;
  final PollStatus status;

  /// Creates a new poll with the specified parameters
  ///
  /// Throws [PollException] if required parameters are invalid
  PollModel({
    required this.id,
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
    Map<String, VoteRecord>? votes,
    int? totalVotes,
    required this.status,
  })  : votes = votes ?? {},
        totalVotes = totalVotes ?? 0 {
    _validateConstructorParameters();
  }

  /// Validates that all required parameters are properly set
  void _validateConstructorParameters() {
    if (id.isEmpty) {
      throw PollException('Poll ID cannot be empty');
    }
    if (creatorId.isEmpty) {
      throw PollException('Creator ID cannot be empty');
    }
    if (title.trim().isEmpty) {
      throw PollException('Title cannot be empty');
    }
    if (imageOne.isEmpty || imageTwo.isEmpty) {
      throw PollException('Both images must be specified');
    }
    if (deadline != null && deadline!.isBefore(DateTime.now())) {
      throw PollException('Deadline must be in the future');
    }
    if (votes.length != totalVotes) {
      throw PollException('Total votes must match the number of vote records');
    }
  }

  /// Checks if the poll is currently active and accepting votes
  ///
  /// Returns false if the poll is closed or the deadline has passed
  bool isActive() {
    if (status == PollStatus.closed) return false;
    if (status == PollStatus.draft) return false;
    if (deadline == null) return true;
    return DateTime.now().isBefore(deadline!);
  }

  /// Creates a PollModel instance from a Firestore document
  ///
  /// Expects the document to contain all required fields for a valid poll
  /// Throws [FormatException] if required fields are missing
  factory PollModel.fromDocument(DocumentSnapshot doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;

      // Check required fields
      final requiredFields = ['creatorId', 'title', 'imageOne', 'imageTwo'];
      final missingFields =
          requiredFields.where((field) => data[field] == null).toList();

      if (missingFields.isNotEmpty) {
        throw FormatException(
          'Document ${doc.id} is missing required fields: ${missingFields.join(', ')}',
        );
      }

      // Parse votes
      final votesMap = (data['votes'] as Map<String, dynamic>?)?.map(
            (key, value) => MapEntry(
              key,
              VoteRecord.fromJson(value as Map<String, dynamic>),
            ),
          ) ??
          {};

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
        votes: votesMap,
        totalVotes: votesMap.length,
        status: _statusFromString(data['status']?.toString()),
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error creating PollModel from document ${doc.id}: $e',
        e,
        stackTrace,
      );
      rethrow;
    }
  }

  /// Converts enum values from their string representations
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

  /// Converts the poll to a JSON format suitable for Firestore storage
  Map<String, dynamic> toJson() {
    final json = {
      'creatorId': creatorId,
      'title': title,
      'description': description,
      'imageOne': imageOne,
      'imageTwo': imageTwo,
      'captionOne': captionOne,
      'captionTwo': captionTwo,
      'category': category.toString().split('.').last,
      'votingType': votingType.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
      'votes': votes.map((key, value) => MapEntry(key, value.toJson())),
      'totalVotes': totalVotes,
      'status': status.toString().split('.').last,
    };

    return json;
  }

  /// Calculates the percentage of votes for each image
  ///
  /// Returns a map containing vote percentages for both images
  Map<String, double> getVotePercentages() {
    if (totalVotes == 0) {
      return {
        'imageOne': defaultPercentage,
        'imageTwo': defaultPercentage,
      };
    }

    final imageOneVotes =
        votes.values.where((vote) => vote.selectedImageId == imageOne).length;

    final imageOnePercentage = (imageOneVotes / totalVotes) * 100;

    return {
      'imageOne': imageOnePercentage,
      'imageTwo': 100 - imageOnePercentage,
    };
  }

  /// Creates a new instance of PollModel with updated fields
  ///
  /// Any parameter not provided will retain its original value
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
    Map<String, VoteRecord>? votes,
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
      status: status ?? this.status,
    );
  }
}
