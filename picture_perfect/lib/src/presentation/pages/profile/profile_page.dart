import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../viewmodels/user_view_model.dart';
import '../../widgets/poll/poll_card.dart';

class ProfilePage extends StatefulWidget {
  final String? userId;
  const ProfilePage({super.key, this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authViewModel = context.watch<AuthViewModel>();
    final currentUserId = authViewModel.currentUser!.id;
    final targetUserId = widget.userId ?? currentUserId;
    final isCurrentUser = targetUserId == currentUserId;

    return FutureBuilder(
        future: context.read<UserViewModel>().getUserById(targetUserId),
        builder: (context, AsyncSnapshot<UserModel?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return const DynamicScaffold(
              child: Center(child: CircularProgressIndicator()),
            );
          }

          if (snapshot.hasError) {
            return DynamicScaffold(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Error loading profile: ${snapshot.error}'),
                    ElevatedButton(
                      onPressed: () => setState(() {}),
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }

          final user = snapshot.data!;

          return DynamicScaffold(
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _ProfileHeader(
                        user: user,
                        isCurrentUser: isCurrentUser,
                        onFollowTap: isCurrentUser
                            ? null
                            : () => _handleFollowTap(context, user.id),
                      ),
                      const SizedBox(height: 20),
                      _StatsRow(user: user),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
                SliverPersistentHeader(
                  delegate: _SliverAppBarDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Created'),
                        Tab(text: 'Saved'),
                        Tab(text: 'Voted'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ],
              body: TabBarView(
                controller: _tabController,
                children: [
                  _CreatedPollsTab(polls: user.createdPolls),
                  _SavedPollsTab(polls: user.savedPosts),
                  _VotedPollsTab(polls: user.votedPolls),
                ],
              ),
            ),
          );
        });
  }

  Future<void> _handleFollowTap(BuildContext context, String userId) async {
    setState(() => _isLoading = true);

    try {
      final userViewModel = context.read<UserViewModel>();
      final currentUserId = context.read<AuthViewModel>().currentUser!.id;

      // await userViewModel.toggleFollow(
      //   followerId: currentUserId,
      //   followingId: userId,
      // );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Successfully updated follow status')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update follow status: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;
  final bool isCurrentUser;
  final VoidCallback? onFollowTap;

  const _ProfileHeader({
    required this.user,
    required this.isCurrentUser,
    this.onFollowTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 50,
                backgroundImage: user.profilePicture != null
                    ? CachedNetworkImageProvider(user.profilePicture!)
                    : null,
                child: user.profilePicture == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              if (isCurrentUser)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showEditProfile(context),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user.name ?? 'No Name Set',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          if (user.bio != null) ...[
            const SizedBox(height: 8),
            Text(
              user.bio!,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
          if (!isCurrentUser) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onFollowTap,
              child: Text(
                  'Follow'), // TODO: You'll need to change this based on follow status
            ),
          ],
        ],
      ),
    );
  }

  void _showEditProfile(BuildContext context) {
    // TODO: Implement your edit profile logic here
  }
}

class _StatsRow extends StatelessWidget {
  final UserModel user;

  const _StatsRow({required this.user});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      mainAxisSize: MainAxisSize.max,
      children: [
        _buildStatColumn(context, 'Posts', user.createdPolls.length.toString()),
        _buildStatColumn(context, 'Followers', user.followers.toString()),
        _buildStatColumn(context, 'Following', user.following.toString()),
      ],
    );
  }

  Widget _buildStatColumn(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

class _CreatedPollsTab extends StatelessWidget {
  final List<String> polls;

  const _CreatedPollsTab({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(child: Text('No created polls yet'));
    }

    return Consumer<PollViewModel>(
      builder:
          (BuildContext context, PollViewModel pollViewModel, Widget? child) {
        return ListView.builder(
          itemCount: polls.length,
          itemBuilder: (context, index) {
            final poll = pollViewModel.polls[index];
            return PollCard(poll: poll);
          },
        );
      },
    );
  }
}

class _SavedPollsTab extends StatelessWidget {
  final List<String> polls;

  const _SavedPollsTab({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(child: Text('No saved polls yet'));
    }

    return ListView.builder(
      itemCount: polls.length,
      itemBuilder: (context, index) {
        return _PollCard(pollId: polls[index]);
      },
    );
  }
}

class _VotedPollsTab extends StatelessWidget {
  final List<String> polls;

  const _VotedPollsTab({required this.polls});

  @override
  Widget build(BuildContext context) {
    if (polls.isEmpty) {
      return const Center(child: Text('No voted polls yet'));
    }

    return ListView.builder(
      itemCount: polls.length,
      itemBuilder: (context, index) {
        return _PollCard(pollId: polls[index]);
      },
    );
  }
}

class _PollCard extends StatelessWidget {
  final String pollId;

  const _PollCard({required this.pollId});

  @override
  Widget build(BuildContext context) {
    // You'll need to implement this based on your poll model and data
    return Card(
      margin: const EdgeInsets.all(8.0),
      child: ListTile(
        title: Text('Poll $pollId'),
        // Add more poll details here
      ),
    );
  }
}
