import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../config/app_theme.dart';
import 'animations/animated_widgets.dart';

/// Quick reaction picker that appears above messages
class ReactionPicker extends StatefulWidget {
  final Function(String emoji) onReactionSelected;
  final VoidCallback onDismiss;
  final String? selectedEmoji;

  const ReactionPicker({
    super.key,
    required this.onReactionSelected,
    required this.onDismiss,
    this.selectedEmoji,
  });

  @override
  State<ReactionPicker> createState() => _ReactionPickerState();
}

class _ReactionPickerState extends State<ReactionPicker>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  static const List<String> quickReactions = [
    '👍',
    '❤️',
    '😂',
    '😮',
    '😢',
    '🔥',
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.snappyCurve,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      alignment: Alignment.center,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...quickReactions.asMap().entries.map((entry) {
              final index = entry.key;
              final emoji = entry.value;
              final isSelected = widget.selectedEmoji == emoji;

              return FadeSlideIn(
                delay: Duration(milliseconds: index * 30),
                child: _ReactionButton(
                  emoji: emoji,
                  isSelected: isSelected,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    widget.onReactionSelected(emoji);
                  },
                ),
              );
            }),
            Container(
              width: 1,
              height: 24,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              color: AppColors.backgroundLighter,
            ),
            _ReactionButton(
              emoji: '➕',
              isSelected: false,
              onTap: () {
                HapticFeedback.lightImpact();
                _showFullEmojiPicker(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showFullEmojiPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _FullReactionPicker(
        onReactionSelected: (emoji) {
          Navigator.pop(context);
          widget.onReactionSelected(emoji);
        },
      ),
    );
  }
}

class _ReactionButton extends StatefulWidget {
  final String emoji;
  final bool isSelected;
  final VoidCallback onTap;

  const _ReactionButton({
    required this.emoji,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_ReactionButton> createState() => _ReactionButtonState();
}

class _ReactionButtonState extends State<_ReactionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _hoverController;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: AppAnimations.fast,
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _hoverController.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _hoverController.reverse();
      },
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedBuilder(
          animation: _hoverController,
          builder: (context, child) {
            final scale = 1.0 + (_hoverController.value * 0.3);
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: widget.isSelected
                      ? AppColors.blurple.withValues(alpha: 0.2)
                      : _isHovered
                      ? AppColors.backgroundLighter
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.emoji,
                    style: const TextStyle(fontSize: 22),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FullReactionPicker extends StatelessWidget {
  final Function(String emoji) onReactionSelected;

  const _FullReactionPicker({required this.onReactionSelected});

  static const List<List<String>> emojiCategories = [
    // Smileys
    ['😀', '😃', '😄', '😁', '😅', '😂', '🤣', '😊', '😇', '🙂', '😉', '😌'],
    ['😍', '🥰', '😘', '😗', '😙', '😚', '😋', '😛', '😜', '🤪', '😝', '🤑'],
    ['🤗', '🤭', '🤫', '🤔', '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄'],
    ['😬', '😮', '😯', '😲', '😳', '🥺', '😦', '😧', '😨', '😰', '😥', '😢'],
    ['😭', '😱', '😖', '😣', '😞', '😓', '😩', '😫', '🥱', '😤', '😡', '😠'],
    // Gestures
    ['👍', '👎', '👊', '✊', '🤛', '🤜', '👏', '🙌', '👐', '🤲', '🤝', '🙏'],
    ['✌️', '🤞', '🤟', '🤘', '👌', '🤌', '🤏', '👈', '👉', '👆', '👇', '☝️'],
    // Hearts & Symbols
    ['❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔', '❣️', '💕'],
    ['💞', '💓', '💗', '💖', '💘', '💝', '💟', '♥️', '🔥', '✨', '⭐', '🌟'],
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.backgroundLighter,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              'Choose a reaction',
              style: AppTypography.headlineMedium,
            ),
          ),
          Flexible(
            child: GridView.builder(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: emojiCategories.expand((e) => e).length,
              itemBuilder: (context, index) {
                final allEmojis = emojiCategories.expand((e) => e).toList();
                final emoji = allEmojis[index];
                return ScaleOnTap(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onReactionSelected(emoji);
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(emoji, style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

/// Displays reactions on a message
class MessageReactions extends StatelessWidget {
  final List<ReactionData> reactions;
  final Function(String emoji)? onReactionTap;
  final bool isMine;

  const MessageReactions({
    super.key,
    required this.reactions,
    this.onReactionTap,
    this.isMine = false,
  });

  @override
  Widget build(BuildContext context) {
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final grouped = <String, int>{};
    for (final reaction in reactions) {
      grouped[reaction.emoji] = (grouped[reaction.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: isMine ? 0 : 52,
        right: isMine ? 8 : 0,
      ),
      child: Wrap(
        alignment: isMine ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: grouped.entries.map((entry) {
          return ScaleOnTap(
            onTap: () => onReactionTap?.call(entry.key),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.backgroundLighter,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.backgroundMedium, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(entry.key, style: const TextStyle(fontSize: 14)),
                  if (entry.value > 1) ...[
                    const SizedBox(width: 2),
                    Text(
                      '${entry.value}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class ReactionData {
  final String emoji;
  final int userId;
  final String userName;

  ReactionData({
    required this.emoji,
    required this.userId,
    required this.userName,
  });
}
