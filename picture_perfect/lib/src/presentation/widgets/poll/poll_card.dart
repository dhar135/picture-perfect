import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:provider/provider.dart';

import '../../../data/models/poll_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/poll_view_model.dart';

class PollCard extends StatelessWidget {
  final PollModel poll;

  const PollCard({
    super.key,
    required this.poll,
  });

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final currentUser = userViewModel.user;
    final hasVoted = poll.votes.containsKey(currentUser?.id);
    final theme = Theme.of(context);

    return Card(
      color: theme.cardColor,
      margin: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Poll Header
          ListTile(
              title: Text(
                poll.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              subtitle: poll.description != null
                  ? Text(
                      poll.description ?? '',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  : null,
              leading: currentUser?.profilePicture != null
                  ? CircleAvatar(
                      radius: 20,
                      backgroundImage: CachedNetworkImageProvider(
                          currentUser!.profilePicture!),
                    )
                  : const CircleAvatar(
                      child: Icon(Icons.person),
                    )),

          // Poll Description if available
          if (poll.description != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(poll.description!),
            ),

          // Images Section
          Row(
            children: [
              Expanded(
                child: _buildImageSection(
                  context,
                  poll.imageOne,
                  poll.captionOne,
                  'A',
                  hasVoted,
                  poll.getVotePercentages()['imageOne'] ?? 0,
                  () => _handleVote(context, poll.imageOne),
                ),
              ),
              Expanded(
                child: _buildImageSection(
                  context,
                  poll.imageTwo,
                  poll.captionTwo,
                  'B',
                  hasVoted,
                  poll.getVotePercentages()['imageTwo'] ?? 0,
                  () => _handleVote(context, poll.imageTwo),
                ),
              ),
            ],
          ),

          // Poll Footer
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${poll.totalVotes} votes'),
                if (poll.deadline != null)
                  Text('Ends ${_formatDate(poll.deadline!)}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(
    BuildContext context,
    String imageUrl,
    String? caption,
    String label,
    bool hasVoted,
    double votePercentage,
    VoidCallback onVote,
  ) {
    return Stack(
      children: [
        // Image
        AspectRatio(
          aspectRatio: 1,
          child: GestureDetector(
            onTap: hasVoted ? null : onVote,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(),
              ),
              errorWidget: (context, url, error) => const Icon(Icons.error),
            ),
          ),
        ),

        // Vote Percentage Overlay (if voted)
        if (hasVoted)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: Text(
                  '${votePercentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),

        // Caption
        if (caption != null)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              color: Colors.black54,
              child: Text(
                caption,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _handleVote(BuildContext context, String selectedImage) async {
    final currentUser = context.read<AuthViewModel>().currentUser;
    if (currentUser == null) return;

    // Check if poll is still active
    if (!poll.isActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This poll has ended')),
      );
      return;
    }

    // Submit vote
    final pollViewModel = context.read<PollViewModel>();
    await pollViewModel.votePoll(
      pollId: poll.id,
      userId: currentUser.id,
      selectedImage: selectedImage,
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute}';
  }
}
