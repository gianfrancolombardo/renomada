import 'package:flutter/material.dart';
import '../../../shared/widgets/feed_skeleton_card.dart';

class FeedLoadingState extends StatelessWidget {
  const FeedLoadingState({super.key});

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      itemCount: 3, // Show 3 skeleton cards
      itemBuilder: (context, index) {
        return const FeedSkeletonCard();
      },
    );
  }
}