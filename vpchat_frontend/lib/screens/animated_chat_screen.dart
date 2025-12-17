import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import '../config/app_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../services/file_picker_service.dart';
import '../widgets/animated_message_bubble.dart';
import '../widgets/animations/animated_widgets.dart';
import '../widgets/reply_preview.dart';
import '../widgets/voice_message_recorder.dart';

class AnimatedChatScreen extends StatefulWidget {
  final Chat chat;

  const AnimatedChatScreen({super.key, required this.chat});

  @override
  State<AnimatedChatScreen> createState() => _AnimatedChatScreenState();
}

class _AnimatedChatScreenState extends State<AnimatedChatScreen>
    with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _filePickerService = FilePickerService();
  final _apiService = ApiService();
  late ChatProvider _chatProvider;

  bool _isSendingMessage = false;
  bool _isUploadingFile = false;
  bool _showScrollToBottom = false;
  bool _showEmojiPicker = false;
  bool _hasText = false;
  bool _isRecordingVoice = false;
  Message? _replyingTo;

  late AnimationController _inputController;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.loadMessages(widget.chat.id);
    _chatProvider.setCurrentOpenChat(widget.chat.id);

    _inputController = AnimationController(
      vsync: this,
      duration: AppAnimations.normal,
    );

    _scrollController.addListener(_onScroll);
    _messageController.addListener(_onTextChanged);
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 200;
    if (shouldShow != _showScrollToBottom) {
      setState(() => _showScrollToBottom = shouldShow);
    }

    // Load more messages when near top
    if (_scrollController.position.pixels <= 100 &&
        !_chatProvider.isLoadingMoreMessages(widget.chat.id) &&
        _chatProvider.hasMoreMessages(widget.chat.id)) {
      _chatProvider.loadMoreMessages(widget.chat.id);
    }
  }

  void _onTextChanged() {
    final hasText = _messageController.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
      if (hasText) {
        _inputController.forward();
      } else {
        _inputController.reverse();
      }
    }
    _chatProvider.sendTypingIndicator(widget.chat.id, hasText);
  }

  @override
  void dispose() {
    _chatProvider.setCurrentOpenChat(null);
    _scrollController.dispose();
    _messageController.dispose();
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(authProvider, chatProvider),
      body: Column(
        children: [
          // Connection banner
          _buildConnectionBanner(chatProvider),
          // Messages
          Expanded(
            child: Stack(
              children: [
                _buildMessageList(authProvider, chatProvider),
                _buildScrollToBottomButton(),
              ],
            ),
          ),
          // Typing indicator
          _buildTypingIndicator(chatProvider),
          // Reply bar
          if (_replyingTo != null)
            ReplyInputBar(message: _replyingTo!, onCancel: _clearReplyingTo),
          // Voice recorder or Input area
          if (_isRecordingVoice)
            VoiceMessageRecorder(
              onRecordingComplete: _onVoiceRecordingComplete,
              onCancel: () => setState(() => _isRecordingVoice = false),
            )
          else
            _buildInputArea(authProvider),
          // Emoji picker
          _buildEmojiPicker(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    final displayName = widget.chat.getDisplayName(authProvider.user?.id ?? 0);

    return AppBar(
      backgroundColor: AppColors.backgroundMedium,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(
          Icons.arrow_back_ios_new,
          color: AppColors.textMuted,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: ScaleOnTap(
        onTap: () => _showChatInfo(context),
        child: Row(
          children: [
            Hero(
              tag: 'avatar_${widget.chat.id}',
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: widget.chat.type == ChatType.group
                      ? AppColors.accentGradient
                      : null,
                  color: widget.chat.type == ChatType.group
                      ? null
                      : _getAvatarColor(displayName),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: widget.chat.type == ChatType.group
                      ? const Icon(Icons.group, color: Colors.white, size: 20)
                      : Text(
                          displayName.isNotEmpty
                              ? displayName.substring(0, 1).toUpperCase()
                              : '?',
                          style: AppTypography.titleMedium.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTypography.titleMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  AnimatedSwitcher(
                    duration: AppAnimations.fast,
                    child: chatProvider.isUserTyping(widget.chat.id)
                        ? Row(
                            key: const ValueKey('typing'),
                            children: [
                              TypingDotsAnimation(
                                color: AppColors.blurple,
                                size: 4,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'typing...',
                                style: AppTypography.labelSmall.copyWith(
                                  color: AppColors.blurple,
                                ),
                              ),
                            ],
                          )
                        : Text(
                            key: const ValueKey('status'),
                            widget.chat.type == ChatType.group
                                ? '${widget.chat.participants.length} members'
                                : 'Online',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.online,
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.videocam_outlined, color: AppColors.textMuted),
          onPressed: () => _showComingSoon('Video call'),
        ),
        IconButton(
          icon: const Icon(Icons.call_outlined, color: AppColors.textMuted),
          onPressed: () => _showComingSoon('Voice call'),
        ),
        IconButton(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          onPressed: () => _showChatOptions(context),
        ),
      ],
    );
  }

  Widget _buildConnectionBanner(ChatProvider chatProvider) {
    if (chatProvider.isOnline && !chatProvider.isReconnecting) {
      return const SizedBox.shrink();
    }

    return FadeSlideIn(
      offset: const Offset(0, -10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: chatProvider.isReconnecting
              ? AppColors.warning.withValues(alpha: 0.15)
              : AppColors.error.withValues(alpha: 0.15),
          border: Border(
            bottom: BorderSide(
              color: chatProvider.isReconnecting
                  ? AppColors.warning
                  : AppColors.error,
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              chatProvider.isReconnecting ? Icons.sync : Icons.cloud_off,
              color: chatProvider.isReconnecting
                  ? AppColors.warning
                  : AppColors.error,
              size: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                chatProvider.isReconnecting
                    ? 'Reconnecting...'
                    : 'No connection - Messages will be sent when online',
                style: AppTypography.bodySmall.copyWith(
                  color: chatProvider.isReconnecting
                      ? AppColors.warning
                      : AppColors.error,
                ),
              ),
            ),
            if (!chatProvider.isReconnecting)
              TextButton(
                onPressed: () => chatProvider.retryConnection(),
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.blurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(
                  'Retry',
                  style: AppTypography.labelSmall.copyWith(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageList(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    final messages = chatProvider.getMessages(widget.chat.id);

    if (messages.isEmpty) {
      return _buildWelcomeMessage(authProvider);
    }

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      itemCount:
          messages.length +
          (chatProvider.isLoadingMoreMessages(widget.chat.id) ? 1 : 0),
      itemBuilder: (context, index) {
        if (chatProvider.isLoadingMoreMessages(widget.chat.id) &&
            index == messages.length) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: AppColors.blurple,
                  strokeWidth: 2,
                ),
              ),
            ),
          );
        }

        final message = messages[messages.length - 1 - index];
        final isMine = message.sender.id == authProvider.user?.id;

        bool showAvatar = true;
        bool showTimestamp = true;

        if (index < messages.length - 1) {
          final nextMessage = messages[messages.length - 2 - index];
          if (nextMessage.sender.id == message.sender.id) {
            final timeDiff = message.sentAt.difference(nextMessage.sentAt);
            if (timeDiff.inMinutes < 5) {
              showAvatar = false;
              showTimestamp = false;
            }
          }
        }

        return AnimatedMessageBubble(
          message: message,
          isMine: isMine,
          showAvatar: showAvatar,
          showTimestamp: showTimestamp,
          index: index,
          onDeleteMessage: () => _deleteMessage(message.id),
          onReply: (msg) => _setReplyingTo(msg),
          onReaction: (emoji) => _addReaction(message.id, emoji),
        );
      },
    );
  }

  void _setReplyingTo(Message message) {
    setState(() => _replyingTo = message);
    HapticFeedback.lightImpact();
  }

  void _clearReplyingTo() {
    setState(() => _replyingTo = null);
  }

  void _addReaction(int messageId, String emoji) {
    // In a real app, this would call the API to add a reaction
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Reacted with $emoji'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  Widget _buildWelcomeMessage(AuthProvider authProvider) {
    final displayName = widget.chat.getDisplayName(authProvider.user?.id ?? 0);

    return FadeSlideIn(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blurple.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Icon(
                  widget.chat.type == ChatType.group
                      ? Icons.group
                      : Icons.person,
                  color: Colors.white,
                  size: 36,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Start chatting with',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                displayName,
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppColors.backgroundLighter,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.waving_hand,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Say hello!',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollToBottomButton() {
    return AnimatedPositioned(
      duration: AppAnimations.normal,
      curve: AppAnimations.defaultCurve,
      right: 16,
      bottom: _showScrollToBottom ? 16 : -60,
      child: ScaleOnTap(
        onTap: () {
          HapticFeedback.lightImpact();
          _scrollController.animateTo(
            0,
            duration: AppAnimations.normal,
            curve: AppAnimations.defaultCurve,
          );
        },
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.backgroundMedium,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.backgroundLighter),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(
            Icons.keyboard_arrow_down,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ChatProvider chatProvider) {
    if (!chatProvider.isUserTyping(widget.chat.id)) {
      return const SizedBox.shrink();
    }

    return FadeSlideIn(
      offset: const Offset(0, 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SizedBox(width: 56),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundLighter,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TypingDotsAnimation(color: AppColors.textMuted, size: 8),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        border: Border(top: BorderSide(color: AppColors.backgroundDark)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Attachment button
            ScaleOnTap(
              onTap: _isUploadingFile ? null : _showFilePickerOptions,
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLighter,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _isUploadingFile
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: CircularProgressIndicator(
                          color: AppColors.blurple,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.add, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(width: 8),
            // Text input
            Expanded(
              child: AnimatedContainer(
                duration: AppAnimations.fast,
                decoration: BoxDecoration(
                  color: AppColors.backgroundLighter,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _hasText
                        ? AppColors.blurple.withValues(alpha: 0.5)
                        : Colors.transparent,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 120),
                        child: TextField(
                          controller: _messageController,
                          maxLines: null,
                          textCapitalization: TextCapitalization.sentences,
                          style: AppTypography.bodyLarge.copyWith(
                            color: AppColors.textPrimary,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Message...',
                            hintStyle: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDark,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                    ),
                    // Emoji button
                    IconButton(
                      icon: Icon(
                        _showEmojiPicker
                            ? Icons.keyboard
                            : Icons.emoji_emotions_outlined,
                        color: _showEmojiPicker
                            ? AppColors.blurple
                            : AppColors.textMuted,
                      ),
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            // Send/Voice button
            AnimatedSwitcher(
              duration: AppAnimations.fast,
              transitionBuilder: (child, animation) {
                return ScaleTransition(scale: animation, child: child);
              },
              child: _hasText
                  ? ScaleOnTap(
                      key: const ValueKey('send'),
                      onTap: _isSendingMessage ? null : _sendMessage,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.blurple.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: _isSendingMessage
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                      ),
                    )
                  : ScaleOnTap(
                      key: const ValueKey('mic'),
                      onTap: _startVoiceRecording,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.backgroundLighter,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.mic,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiPicker() {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      height: _showEmojiPicker ? 280 : 0,
      child: _showEmojiPicker
          ? EmojiPicker(
              onEmojiSelected: (category, emoji) {
                _messageController.text += emoji.emoji;
                _messageController.selection = TextSelection.fromPosition(
                  TextPosition(offset: _messageController.text.length),
                );
              },
              config: const Config(
                emojiViewConfig: EmojiViewConfig(
                  columns: 8,
                  emojiSizeMax: 28,
                  backgroundColor: AppColors.backgroundMedium,
                ),
                categoryViewConfig: CategoryViewConfig(
                  backgroundColor: AppColors.backgroundMedium,
                  indicatorColor: AppColors.blurple,
                  iconColor: AppColors.textMuted,
                  iconColorSelected: AppColors.blurple,
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Future<void> _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty || _isSendingMessage) return;

    setState(() => _isSendingMessage = true);
    HapticFeedback.lightImpact();

    try {
      // TODO: Include reply reference when sending
      // final replyToId = _replyingTo?.id;
      await _chatProvider.sendMessage(widget.chat.id, content);
      _messageController.clear();
      _clearReplyingTo();
      setState(() => _showEmojiPicker = false);

      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: AppAnimations.normal,
            curve: AppAnimations.defaultCurve,
          );
        }
      });
    } catch (e) {
      _showError('Failed to send message');
    } finally {
      if (mounted) setState(() => _isSendingMessage = false);
    }
  }

  void _startVoiceRecording() {
    HapticFeedback.mediumImpact();
    setState(() => _isRecordingVoice = true);
  }

  Future<void> _onVoiceRecordingComplete(File file, int durationSeconds) async {
    setState(() => _isRecordingVoice = false);

    // Upload the voice message
    try {
      debugPrint(
        '📤 Uploading voice message: ${file.path} (${durationSeconds}s)',
      );
      await _apiService.uploadFile(widget.chat.id, file);
      HapticFeedback.mediumImpact();
      debugPrint('✅ Voice message sent successfully');

      // Scroll to bottom after sending
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            0,
            duration: AppAnimations.normal,
            curve: AppAnimations.defaultCurve,
          );
        }
      });
    } catch (e) {
      debugPrint('❌ Voice message upload failed: $e');
      _showError(
        'Failed to send voice message: ${e.toString().replaceAll('Exception: ', '')}',
      );
    } finally {
      // Clean up the temp file
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      await _apiService.deleteMessage(messageId);
      _chatProvider.removeMessage(widget.chat.id, messageId);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to delete message');
    }
  }

  void _showFilePickerOptions() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text('Share', style: AppTypography.headlineMedium),
            ),
            const SizedBox(height: 8),
            _buildFileOption(
              icon: Icons.camera_alt,
              color: AppColors.error,
              label: 'Camera',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            _buildFileOption(
              icon: Icons.photo_library,
              color: AppColors.blurple,
              label: 'Gallery',
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            _buildFileOption(
              icon: Icons.insert_drive_file,
              color: AppColors.success,
              label: 'Document',
              onTap: () {
                Navigator.pop(context);
                _pickFile();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildFileOption({
    required IconData icon,
    required Color color,
    required String label,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label, style: AppTypography.bodyLarge),
      onTap: onTap,
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _filePickerService.pickImageFromCamera();
      if (file != null) await _uploadFile(file);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _filePickerService.pickImageFromGallery();
      if (file != null) await _uploadFile(file);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await _filePickerService.pickFile();
      if (file != null) await _uploadFile(file);
    } catch (e) {
      _showError(e.toString());
    }
  }

  Future<void> _uploadFile(File file) async {
    if (_isUploadingFile) return;
    setState(() => _isUploadingFile = true);

    try {
      await _apiService.uploadFile(widget.chat.id, file);
      HapticFeedback.mediumImpact();
    } catch (e) {
      _showError('Failed to upload file');
    } finally {
      if (mounted) setState(() => _isUploadingFile = false);
    }
  }

  void _showChatInfo(BuildContext context) {
    _showComingSoon('Chat info');
  }

  void _showChatOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
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
            ListTile(
              leading: const Icon(Icons.search, color: AppColors.textMuted),
              title: Text('Search', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Search');
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_outlined,
                color: AppColors.textMuted,
              ),
              title: Text('Mute', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Mute');
              },
            ),
            ListTile(
              leading: const Icon(Icons.wallpaper, color: AppColors.textMuted),
              title: Text('Wallpaper', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Wallpaper');
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Clear chat',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showComingSoon('Clear chat');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming soon!'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showError(String message) {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _getAvatarColor(String name) {
    int hash = 0;
    for (int i = 0; i < name.length; i++) {
      hash = hash * 31 + name.codeUnitAt(i);
    }
    final colors = [
      AppColors.blurple,
      AppColors.success,
      AppColors.warning,
      AppColors.pink,
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
    ];
    return colors[hash.abs() % colors.length];
  }
}
