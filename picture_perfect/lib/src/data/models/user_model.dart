import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final String? bio;
  final List<String> followers;
  final List<String> following;
  final int posts;
  final List<String> savedPosts;
  final List<String> createdPolls;
  final List<String> votedPolls;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    this.bio,
    this.followers = const [],
    this.following = const [],
    this.posts = 0,
    this.savedPosts = const [],
    this.createdPolls = const [],
    this.votedPolls = const [],
    required this.createdAt,
    this.lastLoginAt,
  });

  // Create from Firebase User
  factory UserModel.fromFirebaseUser(auth.User user) {
    return UserModel(
      id: user.uid,
      email: user.email!,
      name: user.displayName,
      profilePicture: user.photoURL,
      createdAt: DateTime.now(),
    );
  }

  // Create from Firestore document
  factory UserModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return UserModel(
      id: doc.id,
      email: data['email'] as String,
      name: data['name'] as String?,
      profilePicture: data['profilePicture'] as String?,
      bio: data['bio'] as String?,
      followers: List<String>.from(data['followers'] ?? []),
      following: List<String>.from(data['following'] ?? []),
      posts: (data['posts'] as num?)?.toInt() ?? 0,
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
      createdPolls: List<String>.from(data['createdPolls'] ?? []),
      votedPolls: List<String>.from(data['votedPolls'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: (data['lastLoginAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'name': name,
      'profilePicture': profilePicture,
      'bio': bio,
      'followers': followers,
      'following': following,
      'posts': posts,
      'savedPosts': savedPosts,
      'createdPolls': createdPolls,
      'votedPolls': votedPolls,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt':
          lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
    };
  }

  // Copy with method for immutable updates
  UserModel copyWith({
    String? name,
    String? profilePicture,
    String? bio,
    List<String>? followers,
    List<String>? following,
    int? posts,
    List<String>? savedPosts,
    List<String>? createdPolls,
    List<String>? votedPolls,
    DateTime? lastLoginAt,
  }) {
    return UserModel(
      id: id,
      email: email,
      name: name ?? this.name,
      profilePicture: profilePicture ?? this.profilePicture,
      bio: bio ?? this.bio,
      followers: followers ?? this.followers,
      following: following ?? this.following,
      posts: posts ?? this.posts,
      savedPosts: savedPosts ?? this.savedPosts,
      createdPolls: createdPolls ?? this.createdPolls,
      votedPolls: votedPolls ?? this.votedPolls,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          email == other.email &&
          name == other.name &&
          profilePicture == other.profilePicture &&
          bio == other.bio &&
          followers == other.followers &&
          following == other.following &&
          posts == other.posts &&
          savedPosts == other.savedPosts &&
          createdPolls == other.createdPolls &&
          votedPolls == other.votedPolls;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      profilePicture.hashCode ^
      bio.hashCode ^
      followers.hashCode ^
      following.hashCode ^
      posts.hashCode ^
      savedPosts.hashCode ^
      createdPolls.hashCode ^
      votedPolls.hashCode;

  @override
  String toString() {
    return 'UserModel{id: $id, email: $email, name: $name, profilePicture: $profilePicture, bio: $bio, followers: $followers, following: $following, posts: $posts, savedPosts: $savedPosts, createdPolls: $createdPolls, votedPolls: $votedPolls, createdAt: $createdAt, lastLoginAt: $lastLoginAt}';
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] ?? '',
      email: map['email'] ?? '',
      name: map['name'],
      bio: map['bio'],
      profilePicture: map['profilePicture'],
      createdPolls: List<String>.from(map['createdPolls'] ?? []),
      savedPosts: List<String>.from(map['savedPosts'] ?? []),
      votedPolls: List<String>.from(map['votedPolls'] ?? []),
      followers: List<String>.from(map['followers'] ?? []),
      following: List<String>.from(map['following'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
