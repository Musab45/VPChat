import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Beautiful animated typing indicator with bouncing dots
class AnimatedTypingIndicator extends StatefulWidget {
  final Color color;
  final double dotSize;
  final double spacing;
  final String? username;

  const AnimatedTypingIndicator({
    super.key,
    this.color = AppColors.textMuted,
    this.dotSize = 8,
    this.spacing = 4,
    this.username,
  });

  @override
  State<AnimatedTypingIndicator> createState() =>
      _AnimatedTypingIndicatorState();
}

class _AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _bounceAnimations;
  late List<Animation<double>> _opacityAnimations;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controllers = List.generate(
      3,
      (index) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 600),
      ),
    );

    _bounceAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0,
            end: -8,
          ).chain(CurveTween(curve: Curves.easeOut)),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -8,
            end: 0,
          ).chain(CurveTween(curve: Curves.bounceOut)),
          weight: 50,
        ),
      ]).animate(controller);
    }).toList();

    _opacityAnimations = _controllers.map((controller) {
      return TweenSequence<double>([
        TweenSequenceItem(
          tween: Tween<double>(begin: 0.4, end: 1.0),
          weight: 50,
        ),
        TweenSequenceItem(
          tween: Tween<double>(begin: 1.0, end: 0.4),
          weight: 50,
        ),
      ]).animate(controller);
    }).toList();

    // Start animations with stagger
    for (int i = 0; i < _controllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) {
          _controllers[i].repeat();
        }
      });
    }
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.username != null) ...[
            Text(
              widget.username!,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 8),
          ],
          ...List.generate(3, (index) {
            return AnimatedBuilder(
              animation: _controllers[index],
              builder: (context, child) {
                return Container(
                  margin: EdgeInsets.symmetric(horizontal: widget.spacing / 2),
                  child: Transform.translate(
                    offset: Offset(0, _bounceAnimations[index].value),
                    child: Opacity(
                      opacity: _opacityAnimations[index].value,
                      child: Container(
                        width: widget.dotSize,
                        height: widget.dotSize,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
}

/// Compact typing indicator for inline use
class CompactTypingIndicator extends StatefulWidget {
  final Color color;
  final double size;

  const CompactTypingIndicator({
    super.key,
    this.color = AppColors.blurple,
    this.size = 6,
  });

  @override
  State<CompactTypingIndicator> createState() => _CompactTypingIndicatorState();
}

class _CompactTypingIndicatorState extends State<CompactTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (index) {
            final delay = index * 0.2;
            final progress = (_animation.value + delay) % 1.0;
            final scale = 0.5 + (0.5 * (1 - (progress - 0.5).abs() * 2));
            final opacity = 0.3 + (0.7 * scale);

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    width: widget.size,
                    height: widget.size,
                    decoration: BoxDecoration(
                      color: widget.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

/// Wave-style typing indicator
class WaveTypingIndicator extends StatefulWidget {
  final Color color;
  final double barWidth;
  final double maxHeight;
  final int barCount;

  const WaveTypingIndicator({
    super.key,
    this.color = AppColors.blurple,
    this.barWidth = 3,
    this.maxHeight = 16,
    this.barCount = 4,
  });

  @override
  State<WaveTypingIndicator> createState() => _WaveTypingIndicatorState();
}

class _WaveTypingIndicatorState extends State<WaveTypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(widget.barCount, (index) {
            final delay = index * (1.0 / widget.barCount);
            final progress = (_controller.value + delay) % 1.0;
            final height =
                widget.maxHeight * 0.3 +
                (widget.maxHeight *
                    0.7 *
                    (0.5 + 0.5 * (1 - (progress * 2 - 1).abs())));

            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 1.5),
              width: widget.barWidth,
              height: height,
              decoration: BoxDecoration(
                color: widget.color,
                borderRadius: BorderRadius.circular(widget.barWidth / 2),
              ),
            );
          }),
        );
      },
    );
  }
}
