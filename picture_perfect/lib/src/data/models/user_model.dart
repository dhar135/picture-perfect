// lib/data/models/user_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserModel {
  final String id;
  final String email;
  final String? name;
  final String? profilePicture;
  final String? bio;
  final int followers;
  final int following;
  final int posts;
  final List<String> savedPosts;
  final DateTime createdAt;
  final DateTime? lastLoginAt;

  const UserModel({
    required this.id,
    required this.email,
    this.name,
    this.profilePicture,
    this.bio,
    this.followers = 0,
    this.following = 0,
    this.posts = 0,
    this.savedPosts = const [],
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
      followers: (data['followers'] as num?)?.toInt() ?? 0,
      following: (data['following'] as num?)?.toInt() ?? 0,
      posts: (data['posts'] as num?)?.toInt() ?? 0,
      savedPosts: List<String>.from(data['savedPosts'] ?? []),
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
    String? website,
    int? followers,
    int? following,
    int? posts,
    List<String>? savedPosts,
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
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
    );
  }

  // Equality operator
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
          posts == other.posts;

  @override
  int get hashCode =>
      id.hashCode ^
      email.hashCode ^
      name.hashCode ^
      profilePicture.hashCode ^
      bio.hashCode ^
      followers.hashCode ^
      following.hashCode ^
      posts.hashCode;

  @override
  String toString() =>
      'UserModel(id: $id, email: $email, name: $name, followers: $followers, following: $following, posts: $posts)';
}
