import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/message.dart';

class MessageBubble extends StatefulWidget {
  final Message message;
  final bool isMine;
  final bool showAvatar;
  final bool showTimestamp;
  final bool isHighlighted;
  final VoidCallback? onDeleteMessage;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.isMine,
    this.showAvatar = true,
    this.showTimestamp = true,
    this.isHighlighted = false,
    this.onDeleteMessage,
  }) : super(key: key);

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    // For user's own messages, align to the right
    if (widget.isMine) {
      return _buildMyMessage(context);
    }
    // For other users' messages, align to the left (Discord style)
    return _buildOtherMessage(context);
  }

  Widget _buildMyMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.showTimestamp ? 8 : 2,
        ),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? const Color(0xFF40444B)
              : _isHovered
              ? const Color(0xFF32353B)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message actions (show on hover) - left side for my messages
            if (_isHovered)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3136),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF202225), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_outlined,
                      tooltip: 'Edit',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Edit message - Coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.more_horiz,
                      tooltip: 'More',
                      onPressed: () => _showMessageActions(context),
                    ),
                  ],
                ),
              ),
            // Spacer to push content to the right
            const Spacer(),
            // Message content (expanded to take available width)
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Message content with background container
                  Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5865F2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildMessageContent(context),
                          const SizedBox(height: 4),
                          _buildMessageStatus(),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Avatar space placeholder (right side for my messages)
            const SizedBox(width: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildOtherMessage(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: widget.showTimestamp ? 8 : 2,
        ),
        decoration: BoxDecoration(
          color: widget.isHighlighted
              ? const Color(0xFF40444B)
              : _isHovered
              ? const Color(0xFF32353B)
              : Colors.transparent,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User avatar (always show space for alignment)
            if (widget.showAvatar)
              Container(
                margin: const EdgeInsets.only(right: 16, top: 2),
                child: CircleAvatar(
                  radius: 20,
                  backgroundColor: _getUserColor(
                    widget.message.sender.username,
                  ),
                  child: Text(
                    widget.message.sender.username.isNotEmpty
                        ? widget.message.sender.username
                              .substring(0, 1)
                              .toUpperCase()
                        : 'U',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              const SizedBox(width: 56),
            // Message content with container background
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Username and timestamp header (only show if first message in group)
                  if (widget.showTimestamp)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4, left: 12),
                      child: Row(
                        children: [
                          Text(
                            widget.message.sender.username,
                            style: TextStyle(
                              color: _getUserColor(
                                widget.message.sender.username,
                              ),
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _formatTimestamp(widget.message.sentAt),
                            style: const TextStyle(
                              color: Color(0xFF96989D),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Message content with background container
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF40444B),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.5,
                      ),
                      child: _buildMessageContent(context),
                    ),
                  ),
                ],
              ),
            ),
            // Message actions (show on hover)
            if (_isHovered)
              Container(
                margin: const EdgeInsets.only(left: 8),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  color: const Color(0xFF2F3136),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF202225), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildActionButton(
                      icon: Icons.add_reaction_outlined,
                      tooltip: 'Add reaction',
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Add reaction - Coming soon!'),
                          ),
                        );
                      },
                    ),
                    _buildActionButton(
                      icon: Icons.more_horiz,
                      tooltip: 'More',
                      onPressed: () => _showMessageActions(context),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 16),
      color: const Color(0xFFB9BBBE),
      onPressed: onPressed,
      tooltip: tooltip,
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
    );
  }

  Widget _buildMessageContent(BuildContext context) {
    switch (widget.message.messageType) {
      case MessageType.text:
        return Text(
          widget.message.content ?? '',
          style: const TextStyle(
            color: Color(0xFFDCDDDE),
            fontSize: 15,
            height: 1.4,
          ),
        );
      case MessageType.image:
        return _buildImageContent(context);
      case MessageType.video:
        return _buildVideoContent(context);
      case MessageType.audio:
        return _buildAudioContent();
      case MessageType.file:
        return _buildFileContent(context);
    }
  }

  Widget _buildMessageStatus() {
    if (!widget.isMine) return const SizedBox.shrink();

    IconData icon;
    Color color;

    switch (widget.message.status) {
      case MessageStatus.sent:
        icon = Icons.check;
        color = Colors.white70;
        break;
      case MessageStatus.delivered:
        icon = Icons.done_all;
        color = Colors.white70;
        break;
      case MessageStatus.seen:
        icon = Icons.done_all;
        color = const Color(0xFF57F287); // Discord green
        break;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _formatTimestamp(widget.message.sentAt),
          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
        ),
        const SizedBox(width: 4),
        Icon(icon, size: 14, color: color),
      ],
    );
  }

  Widget _buildImageContent(BuildContext context) {
    if (widget.message.fileUrl == null) {
      return const Text(
        'Image',
        style: TextStyle(color: Color(0xFFDCDDDE), fontSize: 15),
      );
    }

    return GestureDetector(
      onTap: () => _showFullScreenImage(context, widget.message.fileUrl!),
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(4)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.network(
            widget.message.fileUrl!,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                height: 100,
                width: 100,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.broken_image, color: Colors.white54),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildVideoContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(widget.message.fileUrl ?? ''),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3136),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.video_file, color: Color(0xFFDCDDDE), size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message.fileName ?? 'Video',
                style: const TextStyle(color: Color(0xFFDCDDDE), fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioContent() {
    return GestureDetector(
      onTap: () => _launchUrl(widget.message.fileUrl ?? ''),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3136),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.audio_file, color: Color(0xFFDCDDDE), size: 24),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message.fileName ?? 'Audio',
                style: const TextStyle(color: Color(0xFFDCDDDE), fontSize: 15),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileContent(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchUrl(widget.message.fileUrl ?? ''),
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.only(top: 4),
        decoration: BoxDecoration(
          color: const Color(0xFF2F3136),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.insert_drive_file,
              color: Color(0xFFDCDDDE),
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.message.fileName ?? 'File',
                    style: const TextStyle(
                      color: Color(0xFFDCDDDE),
                      fontSize: 15,
                    ),
                  ),
                  if (widget.message.fileSize != null)
                    Text(
                      _formatFileSize(widget.message.fileSize!),
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF96989D),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showFullScreenImage(BuildContext context, String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Image.network(
                imageUrl,
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.broken_image, color: Colors.white, size: 64),
                        SizedBox(height: 16),
                        Text(
                          'Failed to load image',
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).round()} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).round()} MB';
    return '${(bytes / (1024 * 1024 * 1024)).round()} GB';
  }

  void _showMessageActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F3136),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.reply, color: Colors.white70),
              title: const Text('Reply', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement reply
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white70),
              title: const Text(
                'Copy text',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement copy
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Copy - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.bookmark_border, color: Colors.white70),
              title: const Text(
                'Pin message',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement pin
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pin message - Coming soon!')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete message',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF36393F),
        title: const Text(
          'Delete Message',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to delete this message? This action cannot be undone.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Colors.white70),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await _deleteMessage();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage() async {
    try {
      if (widget.onDeleteMessage != null) {
        widget.onDeleteMessage!();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Delete functionality not available')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
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
        return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
      }
    } else if (difference.inHours > 0) {
      return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'now';
    }
  }

  Color _getUserColor(String username) {
    // Generate a consistent, unique color based on username
    // Use a more sophisticated hash to better distribute colors
    int hash = 0;
    for (int i = 0; i < username.length; i++) {
      hash = hash * 31 + username.codeUnitAt(i);
    }
    hash = hash.abs();

    // Expanded color palette with more distinct colors for better differentiation
    final colors = [
      const Color(0xFF5865F2), // Discord blue
      const Color(0xFF57F287), // Discord green
      const Color(0xFFFEE75C), // Discord yellow
      const Color(0xFFEB459E), // Discord pink
      const Color(0xFFED4245), // Discord red
      const Color(0xFFF47B67), // Discord orange
      const Color(0xFFFAA61A), // Discord gold
      const Color(0xFF9B59B6), // Purple
      const Color(0xFF1ABC9C), // Teal
      const Color(0xFFE67E22), // Carrot
      const Color(0xFF34495E), // Dark blue-gray
      const Color(0xFF16A085), // Dark teal
      const Color(0xFF27AE60), // Dark green
      const Color(0xFF2980B9), // Dark blue
      const Color(0xFF8E44AD), // Dark purple
      const Color(0xFFD35400), // Dark orange
      const Color(0xFFC0392B), // Dark red
      const Color(0xFF7F8C8D), // Gray
    ];

    return colors[hash % colors.length];
  }
}
