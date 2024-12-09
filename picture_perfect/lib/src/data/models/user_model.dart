import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

/// A model class representing a user in the application.
///
/// This class manages user data mapping between the application and Firestore,
/// handling user profile information, social connections, and activity tracking.
/// It ensures data consistency through immutability and input validation.
class UserModel {
  /// Unique identifier for the user, matches Firebase Auth UID
  final String id;

  /// User's email address, used for authentication
  final String email;

  /// Optional display name of the user
  final String? name;

  /// URL to user's profile picture
  final String? profilePicture;

  /// User's biographical information
  final String? bio;

  /// List of user IDs who follow this user
  final List<String> followers;

  /// List of user IDs this user follows
  final List<String> following;

  /// Total number of posts created by the user
  final int posts;

  /// List of poll IDs saved by the user
  final List<String> savedPosts;

  /// List of poll IDs created by the user
  final List<String> createdPolls;

  /// List of poll IDs where the user has voted
  final List<String> votedPolls;

  /// Timestamp when the user account was created
  final DateTime createdAt;

  /// Timestamp of user's last login
  final DateTime? lastLoginAt;

  /// Creates a new UserModel instance with validation.
  ///
  /// Throws [AssertionError] if required fields are invalid.
  UserModel({
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
  }) {
    assert(id.isNotEmpty, 'User ID cannot be empty');
    assert(email.isNotEmpty, 'Email cannot be empty');
    assert(email.contains('@'), 'Invalid email format');
  }

  /// Creates a UserModel instance from a Firebase Auth user.
  ///
  /// Used during initial user registration or auth state changes.
  /// Throws [ArgumentError] if the user's email is null.
  factory UserModel.fromFirebaseUser(auth.User user) {
    if (user.email == null) {
      throw ArgumentError('Firebase user must have an email');
    }

    return UserModel(
      id: user.uid,
      email: user.email!,
      name: user.displayName,
      profilePicture: user.photoURL,
      createdAt: DateTime.now(),
    );
  }

  /// Creates a UserModel instance from a Firestore document.
  ///
  /// Throws [FormatException] if required fields are missing.
  factory UserModel.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    if (data == null) {
      throw FormatException('Document ${doc.id} has no data');
    }

    if (data['email'] == null) {
      throw FormatException(
          'Document ${doc.id} is missing required email field');
    }

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
