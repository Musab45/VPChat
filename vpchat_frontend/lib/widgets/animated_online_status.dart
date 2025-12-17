import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Animated online status indicator with pulse effect
class AnimatedOnlineStatus extends StatefulWidget {
  final bool isOnline;
  final double size;
  final bool showPulse;
  final Color? onlineColor;
  final Color? offlineColor;

  const AnimatedOnlineStatus({
    super.key,
    required this.isOnline,
    this.size = 12,
    this.showPulse = true,
    this.onlineColor,
    this.offlineColor,
  });

  @override
  State<AnimatedOnlineStatus> createState() => _AnimatedOnlineStatusState();
}

class _AnimatedOnlineStatusState extends State<AnimatedOnlineStatus>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.8,
    ).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeOut));

    if (widget.isOnline && widget.showPulse) {
      _pulseController.repeat();
    }
  }

  @override
  void didUpdateWidget(AnimatedOnlineStatus oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline && widget.showPulse && !_pulseController.isAnimating) {
      _pulseController.repeat();
    } else if (!widget.isOnline || !widget.showPulse) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isOnline
        ? (widget.onlineColor ?? AppColors.online)
        : (widget.offlineColor ?? AppColors.offline);

    return SizedBox(
      width: widget.size * 2,
      height: widget.size * 2,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Pulse effect
          if (widget.isOnline && widget.showPulse)
            AnimatedBuilder(
              animation: _pulseAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnimation.value,
                  child: Opacity(
                    opacity: 1.0 - (_pulseAnimation.value - 1.0) / 0.8,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                );
              },
            ),
          // Main dot
          AnimatedContainer(
            duration: AppAnimations.normal,
            width: widget.size,
            height: widget.size,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: widget.isOnline
                  ? [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}

/// Status badge with text
class StatusBadge extends StatelessWidget {
  final UserStatus status;
  final bool showLabel;
  final double dotSize;

  const StatusBadge({
    super.key,
    required this.status,
    this.showLabel = true,
    this.dotSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedOnlineStatus(
          isOnline: status == UserStatus.online,
          size: dotSize,
          showPulse: status == UserStatus.online,
          onlineColor: _getStatusColor(),
          offlineColor: _getStatusColor(),
        ),
        if (showLabel) ...[
          const SizedBox(width: 6),
          Text(
            _getStatusLabel(),
            style: AppTypography.labelSmall.copyWith(
              color: _getStatusColor(),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case UserStatus.online:
        return AppColors.online;
      case UserStatus.idle:
        return AppColors.idle;
      case UserStatus.dnd:
        return AppColors.dnd;
      case UserStatus.offline:
        return AppColors.offline;
    }
  }

  String _getStatusLabel() {
    switch (status) {
      case UserStatus.online:
        return 'Online';
      case UserStatus.idle:
        return 'Idle';
      case UserStatus.dnd:
        return 'Do Not Disturb';
      case UserStatus.offline:
        return 'Offline';
    }
  }
}

enum UserStatus { online, idle, dnd, offline }

/// Connection status indicator with animation
class ConnectionStatusIndicator extends StatefulWidget {
  final bool isConnected;
  final bool isReconnecting;
  final VoidCallback? onRetry;

  const ConnectionStatusIndicator({
    super.key,
    required this.isConnected,
    this.isReconnecting = false,
    this.onRetry,
  });

  @override
  State<ConnectionStatusIndicator> createState() =>
      _ConnectionStatusIndicatorState();
}

class _ConnectionStatusIndicatorState extends State<ConnectionStatusIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _rotationController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    if (widget.isReconnecting) {
      _rotationController.repeat();
    }
  }

  @override
  void didUpdateWidget(ConnectionStatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isReconnecting && !_rotationController.isAnimating) {
      _rotationController.repeat();
    } else if (!widget.isReconnecting) {
      _rotationController.stop();
      _rotationController.reset();
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _getBorderColor(), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.isReconnecting)
            RotationTransition(
              turns: _rotationController,
              child: Icon(Icons.sync, size: 16, color: AppColors.warning),
            )
          else
            AnimatedOnlineStatus(
              isOnline: widget.isConnected,
              size: 8,
              showPulse: widget.isConnected,
            ),
          const SizedBox(width: 8),
          Text(
            _getStatusText(),
            style: AppTypography.labelSmall.copyWith(
              color: _getTextColor(),
              fontWeight: FontWeight.w600,
            ),
          ),
          if (!widget.isConnected &&
              !widget.isReconnecting &&
              widget.onRetry != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: widget.onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.blurple,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getBackgroundColor() {
    if (widget.isReconnecting) {
      return AppColors.warning.withValues(alpha: 0.1);
    }
    return widget.isConnected
        ? AppColors.online.withValues(alpha: 0.1)
        : AppColors.error.withValues(alpha: 0.1);
  }

  Color _getBorderColor() {
    if (widget.isReconnecting) {
      return AppColors.warning.withValues(alpha: 0.3);
    }
    return widget.isConnected
        ? AppColors.online.withValues(alpha: 0.3)
        : AppColors.error.withValues(alpha: 0.3);
  }

  Color _getTextColor() {
    if (widget.isReconnecting) return AppColors.warning;
    return widget.isConnected ? AppColors.online : AppColors.error;
  }

  String _getStatusText() {
    if (widget.isReconnecting) return 'Reconnecting...';
    return widget.isConnected ? 'Connected' : 'Disconnected';
  }
}
