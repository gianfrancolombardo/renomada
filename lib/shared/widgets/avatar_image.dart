import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/profile_service.dart';

class AvatarImage extends StatefulWidget {
  final String? avatarUrl;
  final double radius;
  final Color? backgroundColor;
  final Widget? placeholder;

  const AvatarImage({
    super.key,
    this.avatarUrl,
    this.radius = 30.0,
    this.backgroundColor,
    this.placeholder,
  });

  @override
  State<AvatarImage> createState() => _AvatarImageState();
}

class _AvatarImageState extends State<AvatarImage> {
  String? _signedUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getSignedUrl();
  }

  @override
  void didUpdateWidget(AvatarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.avatarUrl != widget.avatarUrl) {
      _getSignedUrl();
    }
  }

  Future<void> _getSignedUrl() async {
    if (widget.avatarUrl == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final signedUrl = await ProfileService().getAvatarSignedUrl(widget.avatarUrl);
      if (mounted) {
        setState(() {
          _signedUrl = signedUrl;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _signedUrl = null;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: widget.radius,
      backgroundColor: widget.backgroundColor ?? Colors.grey.shade300,
      child: _buildAvatarContent(),
    );
  }

  Widget _buildAvatarContent() {
    if (_isLoading) {
      return SizedBox(
        width: widget.radius * 0.6,
        height: widget.radius * 0.6,
        child: const CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (_signedUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: _signedUrl!,
          width: widget.radius * 2,
          height: widget.radius * 2,
          fit: BoxFit.cover,
          placeholder: (context, url) => widget.placeholder ?? 
            Icon(Icons.person, size: widget.radius * 0.8),
          errorWidget: (context, url, error) => widget.placeholder ?? 
            Icon(Icons.person, size: widget.radius * 0.8),
        ),
      );
    }

    return widget.placeholder ?? 
      Icon(Icons.person, size: widget.radius * 0.8);
  }
}
