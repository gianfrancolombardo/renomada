import 'package:flutter/material.dart';
import 'app_header.dart';
import 'bottom_navigation.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? leading;
  final VoidCallback? onSubtitleTap;

  const MainLayout({
    super.key,
    required this.title,
    this.subtitle,
    required this.child,
    required this.currentIndex,
    this.actions,
    this.leading,
    this.onSubtitleTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppHeader(
        title: title,
        subtitle: subtitle,
        actions: actions,
        leading: leading,
        onSubtitleTap: onSubtitleTap,
      ),
      body: child,
      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
      ),
    );
  }
}
