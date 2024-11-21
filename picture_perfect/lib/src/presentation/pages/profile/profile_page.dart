import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/core/utils/logger.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';
import 'package:provider/provider.dart';

import '../../../data/models/user_model.dart';
import '../../viewmodels/user_view_model.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    // Load current user's profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authViewModel = context.read<AuthViewModel>();
      final userViewModel = context.read<UserViewModel>();
      if (authViewModel.currentUser != null) {
        userViewModel.loadUserProfile(authViewModel.currentUser!.id);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userViewModel = context.watch<UserViewModel>();
    final authViewModel = context.watch<AuthViewModel>();
    final currentUserId = authViewModel.currentUser!.id;

    AppLogger.info('Current User ID: $currentUserId');
    AppLogger.info('Loaded user data: ${userViewModel.user?.toString()}');

    // If user is null or loading, show loading or error state
    if (userViewModel.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (userViewModel.error != null) {
      return Center(child: Text('Error: ${userViewModel.error}'));
    }

    // Use the user from the ViewModel instead of a stream
    final user = userViewModel.user;

    if (user == null) {
      return const Center(child: Text('No user data available'));
    }

    // Verify the loaded user matches current user
    if (user.id != currentUserId) {
      AppLogger.info('User ID mismatch: ${user.id} != $currentUserId');
      return const Center(child: Text('User data mismatch'));
    }

    return DynamicScaffold(
      child: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverToBoxAdapter(
            child: Column(
              children: [
                _ProfileHeader(user: user),
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
  }
}

class _ProfileHeader extends StatelessWidget {
  final UserModel user;

  const _ProfileHeader({required this.user});

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
        ],
      ),
    );
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
        _buildStatColumn(context, 'Posts', user.posts.toString()),
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

    return ListView.builder(
      itemCount: polls.length,
      itemBuilder: (context, index) {
        return _PollCard(pollId: polls[index]);
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
