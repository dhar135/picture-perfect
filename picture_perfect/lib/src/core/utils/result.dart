import 'package:cloud_firestore/cloud_firestore.dart';

sealed class Result<T> {
  const Result();
}

final class Success<T> extends Result<T> {
  final T data;
  final DocumentSnapshot? lastDocument; // Added for pagination

  const Success(this.data, {this.lastDocument}); // Updated constructor
}

final class Failure<T> extends Result<T> {
  final String message;
  final Object? error;

  const Failure({
    required this.message,
    this.error,
  });
}