import 'package:flutter/material.dart';
import 'package:picture_perfect/src/presentation/widgets/common/dynamic_scaffold.dart';
import 'package:picture_perfect/src/presentation/widgets/poll/poll_card.dart';
import 'package:provider/provider.dart';

import '../../viewmodels/poll_view_model.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _mounted = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_mounted) {
        _loadInitialPolls();
      }
    });

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _mounted = false;
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialPolls() async {
    if (!_mounted) return;
    final pollViewModel = context.read<PollViewModel>();
    if (pollViewModel.polls.isEmpty) {
      await pollViewModel.fetchPolls();
    }
  }

  Future<void> _loadMorePolls() async {
    if (!_mounted || _isLoadingMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    final pollViewModel = context.read<PollViewModel>();
    await pollViewModel.fetchPolls();

    if (_mounted) {
      setState(() {
        _isLoadingMore = false;
      });
    }
  }

  void _onScroll() {
    if (!_mounted) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent * 0.8) {
      _loadMorePolls();
    }
  }

  Future<void> _handleRefresh() async {
    if (!_mounted) return;
    final pollViewModel = context.read<PollViewModel>();
    await pollViewModel.fetchPolls(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return DynamicScaffold(
      child: Consumer<PollViewModel>(
        builder: (context, pollViewModel, child) {
          if (pollViewModel.state == PollViewState.initial) {
            return const Center(child: CircularProgressIndicator());
          }

          if (pollViewModel.state == PollViewState.error &&
              pollViewModel.polls.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(pollViewModel.errorMessage ?? 'An error occurred'),
                  ElevatedButton(
                    onPressed: _loadInitialPolls,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: _handleRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: pollViewModel.polls.length + (_isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == pollViewModel.polls.length) {
                  return const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final poll = pollViewModel.polls[index];
                return PollCard(poll: poll);
              },
            ),
          );
        },
      ),
    );
  }
}
