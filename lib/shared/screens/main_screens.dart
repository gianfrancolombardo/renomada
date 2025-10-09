import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/main_layout.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/items/screens/my_items_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class FeedMainScreen extends StatefulWidget {
  const FeedMainScreen({super.key});

  @override
  State<FeedMainScreen> createState() => _FeedMainScreenState();
}

class _FeedMainScreenState extends State<FeedMainScreen> {
  bool _isRadiusSelectorVisible = false;

  void _toggleRadiusSelector() {
    setState(() {
      _isRadiusSelectorVisible = !_isRadiusSelectorVisible;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Explorar',
      currentIndex: 0,
      actions: [
        // Radius selector toggle button
        IconButton(
          onPressed: _toggleRadiusSelector,
          icon: Icon(
            LucideIcons.settings,
            color: Theme.of(context).colorScheme.onSurface,
            size: 22.sp,
          ),
        ),
      ],
      child: FeedScreen(
        isRadiusSelectorVisible: _isRadiusSelectorVisible,
        onToggleRadiusSelector: _toggleRadiusSelector,
      ),
    );
  }
}

class MyItemsMainScreen extends StatelessWidget {
  const MyItemsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Mis Artículos',
      currentIndex: 1,
      child: const MyItemsScreen(),
    );
  }
}

class ChatsMainScreen extends StatelessWidget {
  const ChatsMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Conversaciones',
      currentIndex: 2,
      child: const ChatListScreen(),
    );
  }
}

class ProfileMainScreen extends StatelessWidget {
  const ProfileMainScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MainLayout(
      title: 'Mi Perfil',
      currentIndex: 3,
      child: const ProfileScreen(),
    );
  }
}
