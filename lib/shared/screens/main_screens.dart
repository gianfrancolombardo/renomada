import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../widgets/main_layout.dart';
import '../providers/location_name_provider.dart';
import '../../features/feed/screens/feed_screen.dart';
import '../../features/items/screens/my_items_screen.dart';
import '../../features/chat/screens/chat_list_screen.dart';
import '../../features/profile/screens/profile_screen.dart';

class FeedMainScreen extends ConsumerStatefulWidget {
  const FeedMainScreen({super.key});

  @override
  ConsumerState<FeedMainScreen> createState() => _FeedMainScreenState();
}

class _FeedMainScreenState extends ConsumerState<FeedMainScreen> {
  bool _isRadiusSelectorVisible = false;

  void _toggleRadiusSelector() {
    setState(() {
      _isRadiusSelectorVisible = !_isRadiusSelectorVisible;
    });
  }

  @override
  void initState() {
    super.initState();
    // Refresh location name when screen is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(locationNameProvider.notifier).refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locationNameState = ref.watch(locationNameProvider);
    final locationName = locationNameState.locationName;

    print('📍 [FeedMainScreen] Location name state:');
    print('   - locationName: $locationName');
    print('   - isLoading: ${locationNameState.isLoading}');
    print('   - error: ${locationNameState.error}');

    return MainLayout(
      title: 'Explorar',
      subtitle: locationName,
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
      title: 'Objetos',
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
      title: 'Chats',
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
      title: 'Perfil',
      currentIndex: 3,
      child: const ProfileScreen(),
    );
  }
}
