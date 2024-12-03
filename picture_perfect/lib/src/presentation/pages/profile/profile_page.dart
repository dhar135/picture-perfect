import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:picture_perfect/src/data/models/poll_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/auth_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
    final authViewModel = context.read<AuthViewModel>();
    final isCurrentUser =
        widget.userId == null || widget.userId == authViewModel.currentUser!.id;

    _tabController = TabController(
      length: isCurrentUser ? 3 : 1, // Only show 1 tab for other users
      vsync: this,
    );

    // Load initial user data
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (mounted) {
        final targetUserId = widget.userId ?? authViewModel.currentUser!.id;
        final userViewModel = context.read<UserViewModel>();
        final user = await userViewModel.getUserById(targetUserId);

        // Update auth view model if it's the current user
        if (user != null && isCurrentUser && mounted) {
          authViewModel.setCurrentUser(user);
        }
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
    final authViewModel = context.watch<AuthViewModel>();

    // Check authentication
    if (!authViewModel.isAuthenticated) {
      return const DynamicScaffold(
        child: Center(
          child: Text('Please login to view profile'),
        ),
      );
    }

    final currentUserId = authViewModel.currentUser!.id;
    final targetUserId = widget.userId ?? currentUserId;
    final isCurrentUser = targetUserId == currentUserId;

    return DynamicScaffold(
      child: FutureBuilder(
        future: context.read<UserViewModel>().getUserById(targetUserId),
        builder: (context, AsyncSnapshot<UserModel?> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting ||
              _isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error loading profile: ${snapshot.error}'),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final user = snapshot.data!;

          return NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) {
              return [
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
                      tabs: [
                        const Tab(text: 'Created'),
                        if (isCurrentUser) const Tab(text: 'Saved'),
                        if (isCurrentUser) const Tab(text: 'Voted'),
                      ],
                    ),
                  ),
                  pinned: true,
                ),
              ];
            },
            body: TabBarView(
              controller: _tabController,
              children: [
                _CreatedPollsTab(polls: user.createdPolls),
                if (isCurrentUser) _SavedPollsTab(polls: user.savedPosts),
                if (isCurrentUser) _VotedPollsTab(polls: user.votedPolls),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _handleFollowTap(BuildContext context, String userId) async {
    if (!mounted) return;

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final userViewModel = context.read<UserViewModel>();
    final authViewModel = context.read<AuthViewModel>();
    final currentUserId = authViewModel.currentUser!.id;

    setState(() => _isLoading = true);

    try {
      final success = await userViewModel.toggleFollow(
        followerId: currentUserId,
        followingId: userId,
      );

      if (success) {
        // Refresh both users' data
        await Future.wait([
          userViewModel.getUserById(userId, forceRefresh: true),
          authViewModel.refreshCurrentUser(),
        ]);

        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Successfully updated follow status'),
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        if (!mounted) return;
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to update follow status'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error updating follow status: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
    final currentUser = context.watch<AuthViewModel>().currentUser!;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
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
            StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.id)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const ElevatedButton(
                    onPressed: null,
                    child: Text('Loading...'),
                  );
                }

                final userData = snapshot.data!.data() as Map<String, dynamic>?;
                final followers =
                    List<String>.from(userData?['followers'] ?? []);
                final isFollowing = followers.contains(currentUser.id);

                return ElevatedButton(
                  onPressed: onFollowTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowing ? Colors.grey : null,
                  ),
                  child: Text(isFollowing ? 'Following' : 'Follow'),
                );
              },
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
        _buildStatColumn(context, 'Posts', user.createdPolls.length.toString()),
        _buildStatColumn(
            context, 'Followers', user.followers.length.toString()),
        _buildStatColumn(
            context, 'Following', user.following.length.toString()),
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
        return RefreshIndicator(
          onRefresh: () async {
            // Refresh user data
            await context.read<AuthViewModel>().refreshCurrentUser();
          },
          child: FutureBuilder(
            future: Future.wait(
              polls.map((pollId) => pollViewModel.getPollById(pollId)).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading polls: ${snapshot.error}'));
              }

              final loadedPolls = snapshot.data!.whereType<PollModel>().toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: loadedPolls.length,
                itemBuilder: (context, index) {
                  return PollCard(poll: loadedPolls[index]);
                },
              );
            },
          ),
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

    return Consumer<PollViewModel>(
      builder:
          (BuildContext context, PollViewModel pollViewModel, Widget? child) {
        return RefreshIndicator(
          onRefresh: () async {
            await context.read<AuthViewModel>().refreshCurrentUser();
          },
          child: FutureBuilder(
            future: Future.wait(
              polls.map((pollId) => pollViewModel.getPollById(pollId)).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading polls: ${snapshot.error}'));
              }

              final loadedPolls = snapshot.data!.whereType<PollModel>().toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: loadedPolls.length,
                itemBuilder: (context, index) {
                  return PollCard(poll: loadedPolls[index]);
                },
              );
            },
          ),
        );
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

    return Consumer<PollViewModel>(
      builder:
          (BuildContext context, PollViewModel pollViewModel, Widget? child) {
        return RefreshIndicator(
          onRefresh: () async {
            await context.read<AuthViewModel>().refreshCurrentUser();
          },
          child: FutureBuilder(
            future: Future.wait(
              polls.map((pollId) => pollViewModel.getPollById(pollId)).toList(),
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                    child: Text('Error loading polls: ${snapshot.error}'));
              }

              final loadedPolls = snapshot.data!.whereType<PollModel>().toList()
                ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: loadedPolls.length,
                itemBuilder: (context, index) {
                  return PollCard(poll: loadedPolls[index]);
                },
              );
            },
          ),
        );
      },
    );
  }
}
