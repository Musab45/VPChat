import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/message.dart';
import 'animations/animated_widgets.dart';

/// Shows a preview of the message being replied to
class ReplyPreview extends StatelessWidget {
  final ReplyTo replyTo;
  final bool isMine;
  final VoidCallback? onTap;

  const ReplyPreview({
    super.key,
    required this.replyTo,
    this.isMine = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ScaleOnTap(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isMine
              ? Colors.white.withValues(alpha: 0.1)
              : AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: isMine
                  ? Colors.white.withValues(alpha: 0.5)
                  : AppColors.blurple,
              width: 3,
            ),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              replyTo.senderName,
              style: AppTypography.labelSmall.copyWith(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.8)
                    : AppColors.blurple,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              replyTo.previewText,
              style: AppTypography.bodySmall.copyWith(
                color: isMine
                    ? Colors.white.withValues(alpha: 0.7)
                    : AppColors.textMuted,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

/// Input bar showing the message being replied to
class ReplyInputBar extends StatelessWidget {
  final Message message;
  final VoidCallback onCancel;

  const ReplyInputBar({
    super.key,
    required this.message,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return FadeSlideIn(
      offset: const Offset(0, 10),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          border: Border(
            top: BorderSide(color: AppColors.backgroundDark),
            left: BorderSide(color: AppColors.blurple, width: 3),
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.reply, color: AppColors.blurple, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Replying to ${message.sender.username}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.blurple,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _getPreviewText(),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(
                Icons.close,
                color: AppColors.textMuted,
                size: 20,
              ),
              onPressed: onCancel,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            ),
          ],
        ),
      ),
    );
  }

  String _getPreviewText() {
    switch (message.messageType) {
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.file:
        return '📎 ${message.fileName ?? 'File'}';
      case MessageType.text:
        return message.content ?? '';
    }
  }
}
