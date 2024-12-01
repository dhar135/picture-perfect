import 'package:intl/intl.dart';

class CustomDateUtils {
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s ago';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 28) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return DateFormat('MMM d, y').format(dateTime);
    }
  }

  static String formatDeadline(DateTime? deadline) {
    if (deadline == null) return 'No deadline';

    final now = DateTime.now();
    final difference = deadline.difference(now);

    if (difference.isNegative) {
      return 'Ended';
    } else if (difference.inSeconds < 60) {
      return '${difference.inSeconds}s left';
    } else if (difference.inMinutes < 60) {
      final minutes = difference.inMinutes;
      final seconds = difference.inSeconds % 60;
      return '$minutes:${seconds.toString().padLeft(2, '0')} left';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h left';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d left';
    } else if (difference.inDays < 28) {
      return '${(difference.inDays / 7).floor()}w left';
    } else {
      return 'Ends ${DateFormat('MMM d, y').format(deadline)}';
    }
  }

  static bool isPollEnded(DateTime? deadline) {
    if (deadline == null) return false;
    return DateTime.now().isAfter(deadline);
  }
}
