import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_theme.dart';
import '../models/message.dart';
import 'animations/animated_widgets.dart';
import 'reaction_picker.dart';
import 'reply_preview.dart';
import 'voice_message_recorder.dart';

class AnimatedMessageBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isHighlighted;
  final int index;
  final VoidCallback? onDeleteMessage;
  final Function(Message)? onReply;
  final Function(String emoji)? onReaction;
  final VoidCallback? onScrollToReply;

  const AnimatedMessageBubble({
    super.key,
    required this.message,
    required this.isMine,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.isHighlighted = false,
    this.index = 0,
    this.onDeleteMessage,
    this.onReply,
    this.onReaction,
    this.onScrollToReply,
  });

  @override
  State<AnimatedMessageBubble> createState() => _AnimatedMessageBubbleState();
}

class _AnimatedMessageBubbleState extends State<AnimatedMessageBubble>
    with SingleTickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _highlightController;
  late Animation<Color?> _highlightAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _highlightAnimation =
        ColorTween(
          begin: Colors.transparent,
          end: AppColors.blurple.withValues(alpha: 0.2),
        ).animate(
          CurvedAnimation(
            parent: _highlightController,
            curve: Curves.easeInOut,
          ),
        );
  }

  @override
  void didUpdateWidget(AnimatedMessageBubble oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isHighlighted && !oldWidget.isHighlighted) {
      _highlightController.forward().then((_) {
        _highlightController.reverse();
      });
    }
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      delay: Duration(milliseconds: widget.index * 30),
      duration: AppAnimations.normal,
      offset: Offset(widget.isMine ? 20 : -20, 0),
      child: AnimatedBuilder(
        animation: _highlightAnimation,
        builder: (context, child) {
          return widget.isMine
              ? _buildMyMessage(context)
              : _buildOtherMessage(context);
        },
      ),
    );
  }

  Widget _buildMyMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.showTimestamp ? 8 : 2,
        ),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? AppColors.backgroundLighter
              : _isHovered
              ? AppColors.backgroundHover
              : _highlightAnimation.value ?? Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Message actions (show on hover)
            AnimatedOpacity(
              duration: AppAnimations.fast,
              opacity: _isHovered ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: AppAnimations.fast,
                offset: _isHovered ? Offset.zero : const Offset(-0.5, 0),
                child: _buildActionButtons(context),
              ),
            ),
            const Spacer(),
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  ScaleOnTap(
                    onLongPress: () => _showMessageActions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.only(
                          topLeft: const Radius.circular(18),
                          topRight: const Radius.circular(18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: Radius.circular(
                            widget.showTimestamp ? 4 : 18,
                          ),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.blurple.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Reply preview
                          if (widget.message.replyTo != null)
                            ReplyPreview(
                              replyTo: widget.message.replyTo!,
                              isMine: true,
                              onTap: widget.onScrollToReply,
                            ),
                          _buildMessageContent(context),
                          const SizedBox(height: 4),
                          _buildMessageStatus(),
                        ],
                      ),
                    ),
                  ),
                  // Reactions
                  if (widget.message.hasReactions) _buildReactions(context),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: AppAnimations.fast,
        curve: AppAnimations.defaultCurve,
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.showTimestamp ? 8 : 2,
        ),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? AppColors.backgroundLighter
              : _isHovered
              ? AppColors.backgroundHover
              : _highlightAnimation.value ?? Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Avatar with animation
            if (widget.showAvatar)
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: AppAnimations.normal,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Container(
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildAvatar(),
                    ),
                  );
                },
              )
            else
              const SizedBox(width: 52),
            // Message content
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.showTimestamp) _buildHeader(),
                  ScaleOnTap(
                    onLongPress: () => _showMessageActions(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundLighter,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(
                            widget.showTimestamp ? 4 : 18,
                          ),
                          topRight: const Radius.circular(18),
                          bottomLeft: const Radius.circular(18),
                          bottomRight: const Radius.circular(18),
                        ),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.65,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reply preview
                          if (widget.message.replyTo != null)
                            ReplyPreview(
                              replyTo: widget.message.replyTo!,
                              isMine: false,
                              onTap: widget.onScrollToReply,
                            ),
                          _buildMessageContent(context),
                        ],
                      ),
                    ),
                  ),
                  // Reactions
                  if (widget.message.hasReactions) _buildReactions(context),
                ],
              ),
            ),
            // Message actions
            AnimatedOpacity(
              duration: AppAnimations.fast,
              opacity: _isHovered ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: AppAnimations.fast,
                offset: _isHovered ? Offset.zero : const Offset(0.5, 0),
                child: _buildActionButtons(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: _getUserColor(
              widget.message.sender.username,
            ).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 20,
        backgroundColor: _getUserColor(widget.message.sender.username),
        child: Text(
          widget.message.sender.username.isNotEmpty
              ? widget.message.sender.username.substring(0, 1).toUpperCase()
              : 'U',
          style: AppTypography.titleMedium.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4, left: 4),
      child: Row(
        children: [
          Text(
            widget.message.sender.username,
            style: AppTypography.titleMedium.copyWith(
              color: _getUserColor(widget.message.sender.username),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTimestamp(widget.message.sentAt),
            style: AppTypography.labelSmall,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.backgroundDark),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            icon: Icons.emoji_emotions_outlined,
            tooltip: 'React',
            onPressed: () => _showReactionPicker(context),
          ),
          _buildActionButton(
            icon: Icons.reply_outlined,
            tooltip: 'Reply',
            onPressed: () {
              HapticFeedback.lightImpact();
              widget.onReply?.call(widget.message);
            },
          ),
          _buildActionButton(
            icon: Icons.more_horiz,
            tooltip: 'More',
            onPressed: () => _showMessageActions(context),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Tooltip(
          message: tooltip,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Icon(icon, size: 18, color: AppColors.textMuted),
          ),
        ),
      ),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.messageType) {
      case MessageType.text:
        return Text(
          widget.message.content ?? '',
          style: AppTypography.bodyLarge.copyWith(
            color: widget.isMine
                ? AppColors.textPrimary
                : AppColors.textSecondary,
          ),
        );
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildMediaContent(Icons.video_file, 'Video');
      case MessageType.audio:
        // Check if it's a voice message
        if (widget.message.isVoiceMessage) {
          return VoiceMessagePlayer(
            audioUrl: widget.message.fileUrl,
            durationSeconds: widget.message.audioDuration ?? 0,
            isMine: widget.isMine,
          );
        }
        return _buildMediaContent(Icons.audio_file, 'Audio');
      case MessageType.file:
        return _buildFileContent();
    }
  }

  Widget _buildReactions(BuildContext context) {
    final reactions = widget.message.reactions;
    if (reactions.isEmpty) return const SizedBox.shrink();

    // Group reactions by emoji
    final grouped = <String, int>{};
    for (final reaction in reactions) {
      grouped[reaction.emoji] = (grouped[reaction.emoji] ?? 0) + 1;
    }

    return Padding(
      padding: EdgeInsets.only(
        top: 4,
        left: widget.isMine ? 0 : 0,
        right: widget.isMine ? 0 : 0,
      ),
      child: Wrap(
        alignment: widget.isMine ? WrapAlignment.end : WrapAlignment.start,
        spacing: 4,
        runSpacing: 4,
        children: grouped.entries.map((entry) {
          return ScaleOnTap(
            onTap: () => widget.onReaction?.call(entry.key),
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

  Widget _buildImageContent(BuildContext context) {
    if (widget.message.fileUrl == null) {
      return const Text('Image', style: AppTypography.bodyLarge);
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context, widget.message.fileUrl!),
      child: Hero(
        tag: 'image_${widget.message.id}',
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            widget.message.fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 150,
                width: 200,
                decoration: BoxDecoration(
                  color: AppColors.backgroundMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                    color: AppColors.blurple,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                width: 150,
                decoration: BoxDecoration(
                  color: AppColors.backgroundMedium,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.broken_image,
                  color: AppColors.textMuted,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildMediaContent(IconData icon, String label) {
    return GestureDetector(
      onTap: () => _launchUrl(widget.message.fileUrl ?? ''),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.blurple.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: AppColors.blurple, size: 24),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message.fileName ?? label,
                style: AppTypography.bodyMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent() {
    return GestureDetector(
      onTap: () => _launchUrl(widget.message.fileUrl ?? ''),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.backgroundDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.insert_drive_file,
                color: AppColors.success,
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? 'File',
                    style: AppTypography.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (widget.message.fileSize != null)
                    Text(
                      _formatFileSize(widget.message.fileSize!),
                      style: AppTypography.labelSmall,
                    ),
                ],
              ),
            ),
            const Icon(Icons.download_outlined, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageStatus() {
    IconData icon;
    Color color;

    switch (widget.message.status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = AppColors.textPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = AppColors.textPrimary.withValues(alpha: 0.7);
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = AppColors.success;
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(widget.message.sentAt),
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textPrimary.withValues(alpha: 0.7),
          ),
        ),
        const SizedBox(width: 4),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: AppAnimations.fast,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Icon(icon, size: 14, color: color),
            );
          },
        ),
      ],
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black87,
        transitionDuration: AppAnimations.normal,
        reverseTransitionDuration: AppAnimations.fast,
        pageBuilder: (context, animation, secondaryAnimation) {
          return FadeTransition(
            opacity: animation,
            child: Scaffold(
              backgroundColor: Colors.transparent,
              appBar: AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              body: Center(
                child: Hero(
                  tag: 'image_${widget.message.id}',
                  child: InteractiveViewer(
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Image.network(imageUrl, fit: BoxFit.contain),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showMessageActions(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MessageActionsSheet(
        message: widget.message,
        isMine: widget.isMine,
        onDelete: widget.onDeleteMessage,
        onReply: widget.onReply,
      ),
    );
  }

  void _showReactionPicker(BuildContext context) {
    HapticFeedback.lightImpact();
    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height * 0.3,
            left: 20,
            right: 20,
            child: Center(
              child: ReactionPicker(
                onReactionSelected: (emoji) {
                  Navigator.pop(context);
                  widget.onReaction?.call(emoji);
                },
                onDismiss: () => Navigator.pop(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatTimestamp(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) {
        return 'Yesterday ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else if (difference.inDays < 7) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return '${weekdays[dateTime.weekday - 1]} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).round()} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
  }

  Color _getUserColor(String username) {
    int hash = 0;
    for (int i = 0; i < username.length; i++) {
      hash = hash * 31 + username.codeUnitAt(i);
    }
    hash = hash.abs();

    final colors = [
      AppColors.blurple,
      AppColors.success,
      AppColors.warning,
      AppColors.pink,
      AppColors.error,
      const Color(0xFFF47B67),
      const Color(0xFFFAA61A),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
    ];

    return colors[hash % colors.length];
  }
}

class _MessageActionsSheet extends StatelessWidget {
  final Message message;
  final bool isMine;
  final VoidCallback? onDelete;
  final Function(Message)? onReply;

  const _MessageActionsSheet({
    required this.message,
    required this.isMine,
    this.onDelete,
    this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.backgroundLighter,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Actions
            _buildActionTile(
              context,
              icon: Icons.reply_outlined,
              label: 'Reply',
              onTap: () {
                Navigator.pop(context);
                onReply?.call(message);
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.copy_outlined,
              label: 'Copy',
              onTap: () {
                Clipboard.setData(ClipboardData(text: message.content ?? ''));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copied to clipboard')),
                );
              },
            ),
            _buildActionTile(
              context,
              icon: Icons.push_pin_outlined,
              label: 'Pin',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pin - Coming soon!')),
                );
              },
            ),
            if (isMine)
              _buildActionTile(
                context,
                icon: Icons.edit_outlined,
                label: 'Edit',
                onTap: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Edit - Coming soon!')),
                  );
                },
              ),
            _buildActionTile(
              context,
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: isDestructive ? AppColors.error : AppColors.textMuted,
      ),
      title: Text(
        label,
        style: AppTypography.bodyLarge.copyWith(
          color: isDestructive ? AppColors.error : AppColors.textPrimary,
        ),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Delete Message', style: AppTypography.headlineLarge),
        content: Text(
          'Are you sure you want to delete this message?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
