import 'package:flutter/material.dart';

class AvatarWidget extends StatefulWidget {
  const AvatarWidget({
    super.key,
    this.avatarUrl,
    this.name,
    this.radius = 20,
    this.isOnline = false,
  });

  final String? avatarUrl;
  final String? name;
  final double radius;
  final bool isOnline;

  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );
    if (widget.isOnline) {
      _pulseController.repeat(reverse: true);
    }
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline) {
      if (widget.isOnline) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initials = _getInitials(widget.name);

    Widget avatar;
    if (widget.avatarUrl != null && widget.avatarUrl!.isNotEmpty) {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundImage: NetworkImage(widget.avatarUrl!),
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
      );
    } else {
      avatar = CircleAvatar(
        radius: widget.radius,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.2),
        child: Text(
          initials,
          style: TextStyle(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.w700,
            fontSize: widget.radius * 0.7,
          ),
        ),
      );
    }

    if (!widget.isOnline) return avatar;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        avatar,
        Positioned(
          bottom: 0,
          right: 0,
          child: ScaleTransition(
            scale: _pulseAnimation,
            child: Container(
              width: widget.radius * 0.6,
              height: widget.radius * 0.6,
              decoration: BoxDecoration(
                color: Colors.greenAccent.shade400,
                shape: BoxShape.circle,
                border: Border.all(color: theme.scaffoldBackgroundColor, width: 2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getInitials(String? name) {
    if (name == null || name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }
}
