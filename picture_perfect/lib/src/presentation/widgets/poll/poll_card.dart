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
  String? _editedTitle;
  String? _editedDescription;
  String? _editedCaptionOne;
  String? _editedCaptionTwo;

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
          _buildHeader(context, pollCreator, theme, isSaved),
          _buildTitleSection(theme),
          _buildImagesSection(hasVoted),
          if (selectedImageURL != null && !hasVoted && widget.poll.isActive())
            _buildActionButtons(context, isSaved),
          _buildFooter(theme),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, Future<UserModel?> pollCreator,
      ThemeData theme, bool isSaved) {
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
                IconButton(
                  icon: Icon(
                    isSaved ? Icons.bookmark : Icons.bookmark_border,
                    color: isSaved ? Theme.of(context).primaryColor : null,
                  ),
                  onPressed: _isSaving ? null : () => _handleSave(context),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    if (widget.poll.creatorId ==
                        context.read<AuthViewModel>().currentUser?.id) ...[
                      PopupMenuItem(
                        child: const Text('Edit'),
                        onTap: () => _handleEdit(context),
                      ),
                      PopupMenuItem(
                        child: const Text('Delete'),
                        onTap: () => _handleDelete(context),
                      ),
                    ],
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: PollImageSection(
                imageUrl: widget.poll.imageOne,
                caption: widget.poll.captionOne,
                label: 'A',
                hasVoted: hasVoted,
                votePercentage:
                    widget.poll.getVotePercentages()['imageOne'] ?? 0.0,
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
                votePercentage:
                    widget.poll.getVotePercentages()['imageTwo'] ?? 0.0,
                voteCount: _getVoteCount(widget.poll.imageTwo),
                isPollEnded: !widget.poll.isActive(),
                isSelected: selectedImageURL == widget.poll.imageTwo,
                onSelect: setSelectedImage,
              ),
            ),
          ],
        ),
        if (hasVoted || !widget.poll.isActive())
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton(
              onPressed: () => context.go('/poll/${widget.poll.id}/results'),
              child: const Text('View Results'),
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
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Poll'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please select a reason for reporting:'),
              const SizedBox(height: 16),
              ...[
                'Inappropriate content',
                'Misleading/Harmful',
                'Copyright/Ownership',
                'Technical Issues'
              ].map((reason) => RadioListTile<String>(
                    title: Text(reason),
                    value: reason,
                    groupValue: selectedReason,
                    onChanged: (value) {
                      setState(() => selectedReason = value);
                    },
                  )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: selectedReason == null
                ? null
                : () {
                    // TODO: Add report to backend with selectedReason
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Poll reported for: $selectedReason')),
                    );
                    context.pop();
                  },
            child: const Text('Report', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleEdit(BuildContext context) async {
    // Wait for the popup menu to close
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Poll'),
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  initialValue: widget.poll.title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  onChanged: (value) => setState(() => _editedTitle = value),
                ),
                TextFormField(
                  initialValue: widget.poll.description,
                  decoration: const InputDecoration(labelText: 'Description'),
                  onChanged: (value) =>
                      setState(() => _editedDescription = value),
                ),
                TextFormField(
                  initialValue: widget.poll.captionOne,
                  decoration: const InputDecoration(labelText: 'Caption A'),
                  onChanged: (value) =>
                      setState(() => _editedCaptionOne = value),
                ),
                TextFormField(
                  initialValue: widget.poll.captionTwo,
                  decoration: const InputDecoration(labelText: 'Caption B'),
                  onChanged: (value) =>
                      setState(() => _editedCaptionTwo = value),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop({
              'title': _editedTitle ?? widget.poll.title,
              'description': _editedDescription ?? widget.poll.description,
              'captionOne': _editedCaptionOne ?? widget.poll.captionOne,
              'captionTwo': _editedCaptionTwo ?? widget.poll.captionTwo,
            }),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (result != null) {
      final pollViewModel = context.read<PollViewModel>();
      final success = await pollViewModel.updatePoll(
        pollId: widget.poll.id,
        title: result['title'],
        description: result['description'],
        captionOne: result['captionOne'],
        captionTwo: result['captionTwo'],
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Poll updated successfully'
                : 'Failed to update poll'),
          ),
        );
      }
    }
  }

  Future<void> _handleDelete(BuildContext context) async {
    // Wait for the popup menu to close
    await Future.delayed(const Duration(milliseconds: 50));

    if (!mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Poll'),
        content: const Text(
            'Are you sure you want to delete this poll? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => context.pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => context.pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final pollViewModel = context.read<PollViewModel>();
      final success = await pollViewModel.deletePoll(
        widget.poll.id,
        context.read<AuthViewModel>().currentUser!.id,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success
                ? 'Poll deleted successfully'
                : 'Failed to delete poll'),
          ),
        );
      }
    }
  }
}
