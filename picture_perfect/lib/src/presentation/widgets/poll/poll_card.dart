import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/utils/date_util.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/data/models/poll_model.dart';
import 'package:picture_perfect/src/data/models/user_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/poll/poll_image_section.dart';
import 'package:provider/provider.dart';

class PollCard extends StatefulWidget {
  final PollModel poll;
  const PollCard({super.key, required this.poll});

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String? selectedImageURL;
  bool _isVoting = false;
  bool _isSaving = false;

  void setSelectedImage(String url) {
    setState(() {
      selectedImageURL = selectedImageURL == url ? null : url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final currentUser = userViewModel.user;
    final hasVoted = widget.poll.votes.containsKey(currentUser?.id);
    final isSaved = currentUser?.savedPosts.contains(widget.poll.id) ?? false;
    final theme = Theme.of(context);
    final pollCreator = userViewModel.getUserById(widget.poll.creatorId);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, pollCreator, theme),
          _buildTitleSection(theme),
          _buildImagesSection(hasVoted),
          if (selectedImageURL != null && !hasVoted && widget.poll.isActive())
            _buildActionButtons(context, isSaved),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, Future<UserModel?> pollCreator, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: FutureBuilder<UserModel?>(
        future: pollCreator,
        builder: (context, snapshot) {
          return GestureDetector(
            onTap: () => context.go('/profile/${snapshot.data?.id}'),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 15,
                  backgroundImage:
                      snapshot.hasData && snapshot.data?.profilePicture != null
                          ? CachedNetworkImageProvider(
                              snapshot.data!.profilePicture!)
                          : null,
                  child: (!snapshot.hasData ||
                          snapshot.data?.profilePicture == null)
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  snapshot.data?.name ?? 'Unknown User',
                  style: theme.textTheme.titleSmall,
                ),
                const Spacer(),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Report'),
                      onTap: () => _handleReport(context),
                    ),
                  ],
                )
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTitleSection(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.poll.title,
              style: theme.textTheme.titleMedium,
            ),
            if (widget.poll.description != null) Text(widget.poll.description!)
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(bool hasVoted) {
    return Row(
      children: [
        Expanded(
          child: PollImageSection(
            imageUrl: widget.poll.imageOne,
            caption: widget.poll.captionOne,
            label: 'A',
            hasVoted: hasVoted,
            votePercentage: widget.poll.getVotePercentages()['imageOne'] ?? 0.0,
            voteCount: _getVoteCount(widget.poll.imageOne),
            isPollEnded: !widget.poll.isActive(),
            isSelected: selectedImageURL == widget.poll.imageOne,
            onSelect: setSelectedImage,
          ),
        ),
        Expanded(
          child: PollImageSection(
            imageUrl: widget.poll.imageTwo,
            caption: widget.poll.captionTwo,
            label: 'B',
            hasVoted: hasVoted,
            votePercentage: widget.poll.getVotePercentages()['imageTwo'] ?? 0.0,
            voteCount: _getVoteCount(widget.poll.imageTwo),
            isPollEnded: !widget.poll.isActive(),
            isSelected: selectedImageURL == widget.poll.imageTwo,
            onSelect: setSelectedImage,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context, bool isSaved) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(
            child: ElevatedButton(
              onPressed: _isVoting
                  ? null
                  : () => _handleVote(context, selectedImageURL!),
              child: _isVoting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Vote'),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: Icon(
              isSaved ? Icons.bookmark : Icons.bookmark_border,
              color: isSaved ? Theme.of(context).primaryColor : null,
            ),
            onPressed: _isSaving ? null : () => _handleSave(context),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('${widget.poll.totalVotes} votes'),
          Row(
            children: [
              Text(
                  'Created: ${CustomDateUtils.formatTimeAgo(widget.poll.createdAt)}'),
              const SizedBox(width: 8),
              if (widget.poll.deadline != null)
                Text(
                  'Deadline: ${CustomDateUtils.formatDeadline(widget.poll.deadline)}',
                  style: TextStyle(
                    color: CustomDateUtils.isPollEnded(widget.poll.deadline)
                        ? Colors.red
                        : theme.textTheme.bodyMedium?.color,
                  ),
                )
            ],
          ),
        ],
      ),
    );
  }

  int _getVoteCount(String imageUrl) {
    return widget.poll.votes.values.where((vote) => vote == imageUrl).length;
  }

  Future<void> _handleVote(BuildContext context, String selectedImage) async {
    final currentUser = context.read<AuthViewModel>().currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to vote')),
      );
      return;
    }

    setState(() => _isVoting = true);

    try {
      final pollViewModel = context.read<PollViewModel>();
      await pollViewModel.votePoll(
        pollId: widget.poll.id,
        userId: currentUser.id,
        selectedImage: selectedImage,
      );
    } finally {
      if (mounted) {
        setState(() => _isVoting = false);
      }
    }
  }

  Future<void> _handleSave(BuildContext context) async {
  final currentUser = context.read<AuthViewModel>().currentUser;
  final userViewModel = context.read<UserViewModel>();
  final user = userViewModel.user;

  if (currentUser == null || user == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please login to save polls')),
    );
    return;
  }

  setState(() => _isSaving = true);

  try {
    final isSaved = user.savedPosts.contains(widget.poll.id);
    AppLogger.info('Current save state: $isSaved');
    
    await userViewModel.toggleSavedPoll(
      userId: currentUser.id,
      pollId: widget.poll.id,
      save: !isSaved,
    );
  } finally {
    if (mounted) setState(() => _isSaving = false);
  }
}

  void _handleReport(BuildContext context) {
    // TODO: Implement report functionality
  }
}
