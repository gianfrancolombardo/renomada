import 'package:flutter/material.dart';
import 'feed_card_skeleton.dart';

/// Loading state for feed - uses skeleton loader for better UX
class FeedLoadingState extends StatelessWidget {
  const FeedLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return const FeedCardSkeleton();
      },
    );
  }
}