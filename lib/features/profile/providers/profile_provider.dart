import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/models/user_profile.dart';
import '../../../shared/services/profile_service.dart';

// Profile state
class ProfileState {
  final UserProfile? profile;
  final bool isLoading;
  final String? error;

  const ProfileState({
    this.profile,
    this.isLoading = false,
    this.error,
  });

  ProfileState copyWith({
    UserProfile? profile,
    bool? isLoading,
    String? error,
  }) {
    return ProfileState(
      profile: profile ?? this.profile,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Profile notifier
class ProfileNotifier extends StateNotifier<ProfileState> {
  final ProfileService _profileService;

  ProfileNotifier(this._profileService) : super(const ProfileState());

  // Load current profile
  Future<void> loadProfile() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final profile = await _profileService.getCurrentProfile();
      print('Profile loaded: ${profile?.username}');
      state = state.copyWith(
        profile: profile,
        isLoading: false,
        error: null,
      );
    } catch (e) {
      print('Error loading profile: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  // Update username
  Future<bool> updateUsername(String username) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final updatedProfile = await _profileService.updateProfile(
        username: username,
      );
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        error: null,
      );
      
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update avatar from file path
  Future<bool> updateAvatar(String imagePath) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Starting avatar upload from path: $imagePath');
      final updatedProfile = await _profileService.uploadAvatarFromPath(imagePath);
      print('Avatar upload successful: ${updatedProfile.avatarUrl}');
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        error: null,
      );
      
      return true;
    } catch (e) {
      print('Avatar upload failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Update avatar from bytes (for web compatibility)
  Future<bool> updateAvatarFromBytes(Uint8List fileBytes, String fileName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      print('Starting avatar upload from bytes: ${fileBytes.length} bytes, filename: $fileName');
      final updatedProfile = await _profileService.uploadAvatarFromBytes(fileBytes, fileName);
      print('Avatar upload successful: ${updatedProfile.avatarUrl}');
      
      state = state.copyWith(
        profile: updatedProfile,
        isLoading: false,
        error: null,
      );
      
      return true;
    } catch (e) {
      print('Avatar upload failed: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Clear profile (used when logging out)
  void clearProfile() {
    state = const ProfileState();
  }
}

// Providers
final profileServiceProvider = Provider<ProfileService>((ref) {
  return ProfileService();
});

final profileProvider = StateNotifierProvider<ProfileNotifier, ProfileState>((ref) {
  final profileService = ref.watch(profileServiceProvider);
  final notifier = ProfileNotifier(profileService);
  
  // Load profile when provider is created
  notifier.loadProfile();
  
  return notifier;
});

// Convenience providers
final profileDataProvider = Provider<UserProfile?>((ref) {
  return ref.watch(profileProvider).profile;
});

final profileLoadingProvider = Provider<bool>((ref) {
  return ref.watch(profileProvider).isLoading;
});

final profileErrorProvider = Provider<String?>((ref) {
  return ref.watch(profileProvider).error;
});
