import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class PollImageSection extends StatefulWidget {
  final String imageUrl;
  final String? caption;
  final String label;
  final bool hasVoted;
  final double votePercentage;
  final int voteCount;
  final bool isPollEnded;

  final bool isSelected;
  final Function(String) onSelect;

  const PollImageSection(
      {super.key,
      required this.imageUrl,
      this.caption,
      required this.label,
      required this.hasVoted,
      required this.votePercentage,
      required this.voteCount,
      required this.isPollEnded,
      required this.isSelected,
      required this.onSelect});

  @override
  State<PollImageSection> createState() => _PollImageSectionState();
}

class _PollImageSectionState extends State<PollImageSection> {
  void _handleSelection() {
    if (widget.hasVoted || widget.isPollEnded) return;
    widget.onSelect(widget.imageUrl);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final imageSize = maxWidth > 600 ? 400.0 : maxWidth;

        return Container(
          constraints: BoxConstraints(
            maxWidth: imageSize,
            maxHeight: imageSize,
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: _handleSelection,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: widget.isSelected
                          ? Theme.of(context).primaryColor
                          : Colors.transparent,
                      width: 3,
                    ),
                  ),
                  child: CachedNetworkImage(
                    imageUrl: widget.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    errorWidget: (context, url, error) =>
                        const Icon(Icons.error),
                  ),
                ),
              ),

              // Results Overlay
              if (widget.hasVoted || widget.isPollEnded) _buildResultsOverlay(),

              // Caption
              if (widget.caption != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    color: Colors.black54,
                    child: Text(
                      widget.caption!,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResultsOverlay() {
    // Show "You have voted for this poll" if user has voted but poll is still active
    if (widget.hasVoted && !widget.isPollEnded) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black87,
              Colors.black54,
            ],
          ),
        ),
        child: const Center(
          child: Text(
            'You have voted for this poll',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Show "Poll ended" message if poll has ended
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black87,
            Colors.black54,
          ],
        ),
      ),
      child: const Center(
        child: Text(
          'This poll has ended',
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
