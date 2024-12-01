import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/poll/poll_image_section.dart';
import 'package:provider/provider.dart';

import '../../../core/utils/date_util.dart';
import '../../../data/models/poll_model.dart';
import '../../../data/models/user_model.dart';
import '../../viewmodels/auth_view_model.dart';
import '../../viewmodels/poll_view_model.dart';

class PollCard extends StatefulWidget {
  final PollModel poll;

  const PollCard({
    super.key,
    required this.poll,
  });

  @override
  State<PollCard> createState() => _PollCardState();
}

class _PollCardState extends State<PollCard> {
  String? selectedImageURL;

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
    final theme = Theme.of(context);
    final pollCreator = userViewModel.getUserById(widget.poll.creatorId);

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Padding(
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
                        backgroundImage: snapshot.hasData &&
                                snapshot.data?.profilePicture != null
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
                      Spacer(),
                      PopupMenuButton(
                        itemBuilder: (context) => [
                          PopupMenuItem(
                              child: Text('Settings'),
                              onTap: () => print('implement Popup menu'))
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
          ),

          // Title and Description
          Center(
            child: Padding(
              padding: EdgeInsets.all(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.poll.title,
                    style: theme.textTheme.titleMedium,
                  ),
                  if (widget.poll.description != null)
                    Text(widget.poll.description!)
                ],
              ),
            ),
          ),

          // Images Section
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
                onVoteSubmit: (imageUrl) => _handleVote(context, imageUrl),
                isSelected: selectedImageURL == widget.poll.imageOne,
                onSelect: setSelectedImage,
              )),
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
                onVoteSubmit: (imageUrl) => _handleVote(context, imageUrl),
                isSelected: selectedImageURL == widget.poll.imageTwo,
                onSelect: setSelectedImage,
              )),
            ],
          ),

          // Poll Footer
          Padding(
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
                            color: CustomDateUtils.isPollEnded(
                                    widget.poll.deadline)
                                ? Colors.red
                                : Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.color),
                      )
                  ],
                ),
              ],
            ),
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

    if (!widget.poll.isActive()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This poll has ended')),
      );
      return;
    }

    final pollViewModel = context.read<PollViewModel>();
    await pollViewModel.votePoll(
      pollId: widget.poll.id,
      userId: currentUser.id,
      selectedImage: selectedImage,
    );
  }
}
