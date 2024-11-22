import 'package:cloud_firestore/cloud_firestore.dart';

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
    final data = doc.data() as Map<String, dynamic>;

    return PollModel(
      id: doc.id,
      creatorId: data['creatorId'] as String,
      title: data['title'] as String,
      description: data['description'] as String,
      imageOne: data['imageOne'] as String,
      imageTwo: data['imageTwo'] as String,
      captionOne: data['captionOne'] as String?,
      captionTwo: data['captionTwo'] as String?,
      category: PollCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => PollCategory.other,
      ),
      votingType: PollVotingType.values.firstWhere(
        (e) => e.toString() == data['votingType'],
        orElse: () => PollVotingType.nonAnonymous,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      deadline: (data['deadline'] as Timestamp?)?.toDate(),
      votes: Map<String, String>.from(data['votes'] ?? {}),
      totalVotes: (data['totalVotes'] as num?)?.toInt() ?? 0,
      status: PollStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => PollStatus.active, // default value
      ),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'creatorId': creatorId,
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
      'status': status
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
