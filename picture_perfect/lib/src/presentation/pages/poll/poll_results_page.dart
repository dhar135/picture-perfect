import 'package:cached_network_image/cached_network_image.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:picture_perfect/src/core/utils/date_util.dart';
import 'package:picture_perfect/src/data/models/poll_model.dart';
import 'package:picture_perfect/src/data/models/user_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/poll_view_model.dart';
import 'package:picture_perfect/src/presentation/viewmodels/user_view_model.dart';
import 'package:provider/provider.dart';

class PollResultsPage extends StatelessWidget {
  final String pollId;

  const PollResultsPage({super.key, required this.pollId});

  @override
  Widget build(BuildContext context) {
    final pollViewModel = context.watch<PollViewModel>();
    final userViewModel = context.watch<UserViewModel>();

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => context.go('/home'),
          icon: const Icon(Icons.arrow_back),
        ),
        title: const Text('Poll Results'),
      ),
      body: FutureBuilder<PollModel?>(
        future: pollViewModel.getPollById(pollId),
        builder: (context, pollSnapshot) {
          if (pollSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!pollSnapshot.hasData || pollSnapshot.data == null) {
            return const Center(child: Text('Poll not found'));
          }

          final poll = pollSnapshot.data!;
          final percentages = poll.getVotePercentages();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPollHeader(poll, userViewModel),
                  const SizedBox(height: 24),
                  _buildPollStats(poll, percentages),
                  const SizedBox(height: 24),
                  _buildImagesComparison(poll, percentages),
                  const SizedBox(height: 24),
                  _buildPieChart(percentages),
                  const SizedBox(height: 24),
                  _buildVotersList(poll, userViewModel),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPollHeader(PollModel poll, UserViewModel userViewModel) {
    return FutureBuilder<UserModel?>(
      future: userViewModel.getUserById(poll.creatorId),
      builder: (context, snapshot) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              poll.title,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            if (poll.description != null) ...[
              const SizedBox(height: 8),
              Text(
                poll.description!,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                CircleAvatar(
                  backgroundImage: snapshot.data?.profilePicture != null
                      ? CachedNetworkImageProvider(
                          snapshot.data!.profilePicture!)
                      : null,
                  child: snapshot.data?.profilePicture == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Created by ${snapshot.data?.name ?? 'Unknown'}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      CustomDateUtils.formatTimeAgo(poll.createdAt),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildPollStats(PollModel poll, Map<String, double> percentages) {
    final winner = percentages['imageOne']! > percentages['imageTwo']!
        ? 'Image A'
        : percentages['imageOne']! < percentages['imageTwo']!
            ? 'Image B'
            : 'Tie';

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Poll Statistics',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            _buildStatRow('Total Votes', '${poll.totalVotes}'),
            _buildStatRow('Winner', winner),
            _buildStatRow('Winning Margin',
                '${(percentages['imageOne']! - percentages['imageTwo']!).abs().toStringAsFixed(1)}%'),
            _buildStatRow('Status', poll.isActive() ? 'Active' : 'Ended',
                poll.isActive()),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, [bool? isActive]) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive != null
                  ? (isActive ? Colors.green : Colors.red)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagesComparison(
      PollModel poll, Map<String, double> percentages) {
    return Row(
      children: [
        Expanded(
          child: _buildImageResult(
            'Image A',
            poll.imageOne,
            poll.captionOne,
            percentages['imageOne']!,
            _getVoteCount(poll, poll.imageOne),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildImageResult(
            'Image B',
            poll.imageTwo,
            poll.captionTwo,
            percentages['imageTwo']!,
            _getVoteCount(poll, poll.imageTwo),
          ),
        ),
      ],
    );
  }

  Widget _buildImageResult(String label, String imageUrl, String? caption,
      double percentage, int voteCount) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          AspectRatio(
            aspectRatio: 1,
            child: CachedNetworkImage(
              imageUrl: imageUrl,
              fit: BoxFit.cover,
            ),
          ),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(caption),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  '${percentage.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('$voteCount votes'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> percentages) {
    return SizedBox(
      height: 200,
      child: PieChart(
        PieChartData(
          sections: [
            PieChartSectionData(
              color: Colors.blue,
              value: percentages['imageOne']!,
              title: 'A\n${percentages['imageOne']!.toStringAsFixed(1)}%',
              radius: 80,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            PieChartSectionData(
              color: Colors.red,
              value: percentages['imageTwo']!,
              title: 'B\n${percentages['imageTwo']!.toStringAsFixed(1)}%',
              radius: 80,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
          sectionsSpace: 2,
          centerSpaceRadius: 0,
        ),
      ),
    );
  }

  Widget _buildVotersList(PollModel poll, UserViewModel userViewModel) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Voters',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: poll.votes.length,
              itemBuilder: (context, index) {
                final entry = poll.votes.entries.elementAt(index);
                return FutureBuilder<UserModel?>(
                  future: userViewModel.getUserById(entry.key),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const SizedBox.shrink();
                    }
                    return GestureDetector(
                      onTap: () => context.go('/profile/${snapshot.data?.id}'),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: snapshot.data?.profilePicture != null
                              ? CachedNetworkImageProvider(
                                  snapshot.data!.profilePicture!)
                              : null,
                          child: snapshot.data?.profilePicture == null
                              ? const Icon(Icons.person)
                              : null,
                        ),
                        title: Text(snapshot.data?.name ?? 'Unknown User'),
                        trailing: Text(
                          'Voted ${entry.value.selectedImageId == poll.imageOne ? 'A' : 'B'}',
                          style: TextStyle(
                            color: entry.value.selectedImageId == poll.imageOne
                                ? Colors.blue
                                : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  int _getVoteCount(PollModel poll, String imageUrl) {
    return poll.votes.values
        .where((voteRecord) => voteRecord.selectedImageId == imageUrl)
        .length;
  }
}
