import 'package:flutter/material.dart';
import 'app_header.dart';
import 'bottom_navigation.dart';

class MainLayout extends StatelessWidget {
  final String title;
  final Widget child;
  final int currentIndex;
  final List<Widget>? actions;
  final Widget? leading;

  const MainLayout({
    super.key,
    required this.title,
    required this.child,
    required this.currentIndex,
    this.actions,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: AppHeader(
        title: title,
        actions: actions,
        leading: leading,
      ),
      body: child,
      bottomNavigationBar: BottomNavigation(
        currentIndex: currentIndex,
      ),
    );
  }
}
