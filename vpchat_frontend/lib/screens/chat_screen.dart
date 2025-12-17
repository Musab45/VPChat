import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'dart:io';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import '../services/file_picker_service.dart';
import '../widgets/message_bubble.dart';
import 'group_details_screen.dart';

class ChatScreen extends StatefulWidget {
  final Chat chat;

  const ChatScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _searchController = TextEditingController();
  final _filePickerService = FilePickerService();
  final _apiService = ApiService();
  late ChatProvider _chatProvider;
  bool _isSendingMessage = false;
  bool _isUploadingFile = false;
  bool _showScrollToBottom = false;
  bool _showEmojiPicker = false;
  bool _isSearching = false;
  bool _isRecordingVoice = false;
  List<Message> _searchResults = [];
  int _selectedSearchResult = -1;

  @override
  void initState() {
    super.initState();
    _chatProvider = Provider.of<ChatProvider>(context, listen: false);
    _chatProvider.loadMessages(widget.chat.id);

    // Mark messages as delivered when opening chat
    _markMessagesAsDelivered();

    // Listen to scroll position to show/hide scroll-to-bottom button, mark messages as seen, and load more messages
    _scrollController.addListener(() {
      final shouldShow = _scrollController.offset > 200;
      if (shouldShow != _showScrollToBottom) {
        setState(() {
          _showScrollToBottom = shouldShow;
        });
      }

      // Mark visible messages as seen when scrolling
      _markVisibleMessagesAsSeen();

      // Load more messages when scrolling near the top (beginning of reversed list)
      if (_scrollController.position.pixels <= 100 && // Near the top
          !_chatProvider.isLoadingMoreMessages(widget.chat.id) &&
          _chatProvider.hasMoreMessages(widget.chat.id)) {
        _loadMoreMessages();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _messageController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onEmojiSelected(Emoji emoji) {
    final currentText = _messageController.text;
    final selection = _messageController.selection;

    // Handle invalid selection (when TextField is not focused)
    final start = selection.start == -1 ? currentText.length : selection.start;
    final end = selection.end == -1 ? currentText.length : selection.end;

    // Insert emoji at cursor position or at the end
    final newText = currentText.replaceRange(start, end, emoji.emoji);

    _messageController.text = newText;
    _messageController.selection = TextSelection.collapsed(
      offset: start + emoji.emoji.length,
    );

    // Update UI
    setState(() {});
  }

  void _startSearch() {
    setState(() {
      _isSearching = true;
      _searchResults = [];
      _selectedSearchResult = -1;
    });
  }

  void _cancelSearch() {
    setState(() {
      _isSearching = false;
      _searchController.clear();
      _searchResults = [];
      _selectedSearchResult = -1;
    });
  }

  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _selectedSearchResult = -1;
      });
      return;
    }

    final messages = _chatProvider.getMessages(widget.chat.id);
    final results = messages.where((message) {
      return message.content?.toLowerCase().contains(query.toLowerCase()) ??
          false;
    }).toList();

    setState(() {
      _searchResults = results;
      _selectedSearchResult = results.isNotEmpty ? 0 : -1;
    });
  }

  void _navigateToMessage(Message message) {
    final messages = _chatProvider.getMessages(widget.chat.id);
    final messageIndex = messages.indexWhere((m) => m.id == message.id);

    if (messageIndex != -1) {
      // Calculate the position to scroll to (reverse order in ListView)
      final scrollPosition =
          (messages.length - 1 - messageIndex) *
          80.0; // Approximate message height

      _scrollController.animateTo(
        scrollPosition,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  void _navigateSearchResult(bool next) {
    if (_searchResults.isEmpty) return;

    setState(() {
      if (next) {
        _selectedSearchResult =
            (_selectedSearchResult + 1) % _searchResults.length;
      } else {
        _selectedSearchResult = _selectedSearchResult <= 0
            ? _searchResults.length - 1
            : _selectedSearchResult - 1;
      }
    });

    _navigateToMessage(_searchResults[_selectedSearchResult]);
  }

  Widget _buildWelcomeMessage(BuildContext context, AuthProvider authProvider) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF40444B),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF5865F2), width: 3),
              ),
              child: Icon(
                widget.chat.type == ChatType.group ? Icons.tag : Icons.person,
                color: const Color(0xFF5865F2),
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            // Welcome text
            Text(
              'Welcome to #${widget.chat.getDisplayName(authProvider.user?.id ?? 0)}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            // Description
            Text(
              widget.chat.type == ChatType.group
                  ? 'This is the beginning of the #${widget.chat.getDisplayName(authProvider.user?.id ?? 0)} channel.'
                  : 'This is the beginning of your direct message history with ${widget.chat.getDisplayName(authProvider.user?.id ?? 0)}.',
              style: const TextStyle(
                color: Color(0xFF96989D),
                fontSize: 15,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (widget.chat.type == ChatType.group) ...[
              const SizedBox(height: 8),
              Text(
                '${widget.chat.participants.length} members',
                style: const TextStyle(color: Color(0xFF96989D), fontSize: 13),
              ),
            ],
            const SizedBox(height: 32),
            // CTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF40444B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF202225)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.chat_bubble_outline,
                    color: Color(0xFF5865F2),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Send the first message!',
                    style: TextStyle(
                      color: Color(0xFFDCDDDE),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
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

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: const Color(0xFF36393F),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          leading: MediaQuery.of(context).size.width < 768
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFFB9BBBE)),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to chats',
                  padding: const EdgeInsets.all(12),
                )
              : null,
          automaticallyImplyLeading: MediaQuery.of(context).size.width < 768,
          titleSpacing: 16,
          title: Row(
            children: [
              // Channel icon with better visual styling
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF40444B),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  widget.chat.type == ChatType.group ? Icons.tag : Icons.person,
                  color: const Color(0xFF96989D),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              // Chat name and description/status
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      widget.chat.getDisplayName(authProvider.user?.id ?? 0),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (widget.chat.type == ChatType.group)
                      Text(
                        '${widget.chat.participants.length} members',
                        style: const TextStyle(
                          color: Color(0xFF96989D),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    else if (chatProvider.isUserTyping(widget.chat.id))
                      const Text(
                        'typing...',
                        style: TextStyle(
                          color: Color(0xFF5865F2),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      )
                    else
                      const Text(
                        'Online',
                        style: TextStyle(
                          color: Color(0xFF43B581),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            // Call button
            IconButton(
              icon: const Icon(Icons.call_outlined, color: Color(0xFFB9BBBE)),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Voice call - Coming soon!')),
                );
              },
              tooltip: 'Voice call',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Video button
            IconButton(
              icon: const Icon(
                Icons.videocam_outlined,
                color: Color(0xFFB9BBBE),
              ),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Video call - Coming soon!')),
                );
              },
              tooltip: 'Video call',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // Search button
            IconButton(
              icon: const Icon(Icons.search, color: Color(0xFFB9BBBE)),
              onPressed: _startSearch,
              tooltip: 'Search',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            // More options button
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFFB9BBBE)),
              onPressed: () {
                _showChatOptions(context);
              },
              tooltip: 'More options',
              padding: const EdgeInsets.all(10),
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            ),
            const SizedBox(width: 8),
          ],
        ),
      ),
      body: Column(
        children: [
          // Divider
          Container(height: 1, color: const Color(0xFF202225)),

          // Offline/Reconnecting Banner
          if (!chatProvider.isOnline ||
              chatProvider.isReconnecting ||
              chatProvider.error != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: chatProvider.isReconnecting
                    ? const Color(0xFFFEE75C).withOpacity(0.2)
                    : const Color(0xFFED4245).withOpacity(0.2),
                border: Border(
                  bottom: BorderSide(
                    color: chatProvider.isReconnecting
                        ? const Color(0xFFFEE75C)
                        : const Color(0xFFED4245),
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    chatProvider.isReconnecting ? Icons.sync : Icons.cloud_off,
                    color: chatProvider.isReconnecting
                        ? const Color(0xFFFEE75C)
                        : const Color(0xFFED4245),
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      chatProvider.error ??
                          (chatProvider.isReconnecting
                              ? 'Reconnecting to chat server${chatProvider.reconnectAttempts > 0 ? " (${chatProvider.reconnectAttempts}/5)" : ""}...'
                              : 'No internet connection - Messages will be sent when online'),
                      style: TextStyle(
                        color: chatProvider.isReconnecting
                            ? const Color(0xFFFEE75C)
                            : const Color(0xFFED4245),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  if (!chatProvider.isReconnecting && !chatProvider.isConnected)
                    TextButton(
                      onPressed: () async {
                        await chatProvider.retryConnection();
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        backgroundColor: const Color(0xFF5865F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      child: const Text(
                        'Retry',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Search overlay
          if (_isSearching)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF36393F),
                border: Border(
                  bottom: BorderSide(color: Color(0xFF202225), width: 1),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search bar
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF40444B),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: TextField(
                            controller: _searchController,
                            style: const TextStyle(
                              color: Color(0xFFDCDDDE),
                              fontSize: 14,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Search messages...',
                              hintStyle: const TextStyle(
                                color: Color(0xFF72767D),
                                fontSize: 14,
                              ),
                              prefixIcon: const Icon(
                                Icons.search,
                                color: Color(0xFF96989D),
                                size: 20,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            onChanged: _performSearch,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFB9BBBE)),
                        onPressed: _cancelSearch,
                        tooltip: 'Close search',
                        padding: const EdgeInsets.all(8),
                        constraints: const BoxConstraints(
                          minWidth: 40,
                          minHeight: 40,
                        ),
                      ),
                    ],
                  ),
                  // Search results info
                  if (_searchController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Text(
                          _searchResults.isEmpty
                              ? 'No messages found'
                              : '${_searchResults.length} message${_searchResults.length == 1 ? '' : 's'} found',
                          style: const TextStyle(
                            color: Color(0xFF96989D),
                            fontSize: 12,
                          ),
                        ),
                        if (_searchResults.isNotEmpty) ...[
                          const Spacer(),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_up,
                              color: Color(0xFFB9BBBE),
                              size: 20,
                            ),
                            onPressed: () => _navigateSearchResult(false),
                            tooltip: 'Previous result',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                          Text(
                            '${_selectedSearchResult + 1}/${_searchResults.length}',
                            style: const TextStyle(
                              color: Color(0xFF96989D),
                              fontSize: 12,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFFB9BBBE),
                              size: 20,
                            ),
                            onPressed: () => _navigateSearchResult(true),
                            tooltip: 'Next result',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(
                              minWidth: 32,
                              minHeight: 32,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),

          // Messages list with FAB
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: const BoxDecoration(color: Color(0xFF36393F)),
                  child: chatProvider.getMessages(widget.chat.id).isEmpty
                      ? _buildWelcomeMessage(context, authProvider)
                      : ListView.builder(
                          controller: _scrollController,
                          reverse: true, // Newest messages at bottom
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          itemCount:
                              chatProvider.getMessages(widget.chat.id).length +
                              (chatProvider.isLoadingMoreMessages(
                                    widget.chat.id,
                                  )
                                  ? 1
                                  : 0),
                          itemBuilder: (context, index) {
                            // Show loading indicator at the top (index 0 when reversed)
                            if (index == 0 &&
                                chatProvider.isLoadingMoreMessages(
                                  widget.chat.id,
                                )) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                child: const Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Color(0xFF5865F2),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }

                            // Adjust index for loading indicator
                            final adjustedIndex =
                                chatProvider.isLoadingMoreMessages(
                                  widget.chat.id,
                                )
                                ? index - 1
                                : index;

                            final messages = chatProvider.getMessages(
                              widget.chat.id,
                            );
                            final message =
                                messages[messages.length - 1 - adjustedIndex];
                            final isMine =
                                message.sender.id == authProvider.user?.id;

                            // Different display logic for DMs vs Group chats
                            bool showAvatar = true;
                            bool showTimestamp = true;

                            if (widget.chat.type == ChatType.group) {
                              // Group chat: show sender info, but collapse consecutive messages
                              if (adjustedIndex < messages.length - 1) {
                                final nextMessage =
                                    messages[messages.length -
                                        2 -
                                        adjustedIndex];
                                if (nextMessage.sender.id ==
                                    message.sender.id) {
                                  final timeDiff = message.sentAt.difference(
                                    nextMessage.sentAt,
                                  );
                                  if (timeDiff.inMinutes < 5) {
                                    showAvatar = false;
                                    showTimestamp = false;
                                  }
                                }
                              }
                            } else {
                              // DM: don't show sender info for other user's messages
                              if (!isMine) {
                                showAvatar = false;
                                showTimestamp = false;
                              }
                            }

                            final isHighlighted =
                                _isSearching &&
                                _selectedSearchResult != -1 &&
                                _searchResults.isNotEmpty &&
                                message.id ==
                                    _searchResults[_selectedSearchResult].id;

                            return MessageBubble(
                              message: message,
                              isMine: isMine,
                              showAvatar: showAvatar,
                              showTimestamp: showTimestamp,
                              isHighlighted: isHighlighted,
                              onDeleteMessage: () => _deleteMessage(message.id),
                            );
                          },
                        ),
                ),
                // Scroll to bottom FAB
                if (_showScrollToBottom)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: Material(
                      elevation: 4,
                      borderRadius: BorderRadius.circular(28),
                      child: InkWell(
                        onTap: () {
                          _scrollController.animateTo(
                            0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOut,
                          );
                        },
                        borderRadius: BorderRadius.circular(28),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: const Color(0xFF5865F2),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: const Icon(
                            Icons.arrow_downward,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // Typing indicator (below messages)
          if (chatProvider.isUserTyping(widget.chat.id))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const SizedBox(width: 56),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF40444B),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF5865F2).withOpacity(0.6),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'typing...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Message input area
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            decoration: const BoxDecoration(color: Color(0xFF36393F)),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Voice recording indicator
                  if (_isRecordingVoice)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mic, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          const Text(
                            'Recording...',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.close,
                              color: Colors.red,
                              size: 16,
                            ),
                            onPressed: _cancelVoiceRecording,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Input container
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF40444B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _messageController.text.isNotEmpty
                            ? const Color(0xFF5865F2).withOpacity(0.3)
                            : Colors.transparent,
                        width: 1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Attachment button
                            Container(
                              margin: const EdgeInsets.only(left: 4, bottom: 4),
                              child: IconButton(
                                icon: _isUploadingFile
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Color(0xFFB9BBBE),
                                              ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.add_circle,
                                        color: Color(0xFF5865F2),
                                      ),
                                onPressed: _isUploadingFile
                                    ? null
                                    : _showFilePickerOptions,
                                tooltip: _isUploadingFile
                                    ? 'Uploading file...'
                                    : 'Attach file',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ),

                            // Message input
                            Expanded(
                              child: Container(
                                constraints: const BoxConstraints(
                                  maxHeight: 120,
                                  minHeight: 44,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: TextField(
                                  controller: _messageController,
                                  maxLines: null,
                                  textCapitalization:
                                      TextCapitalization.sentences,
                                  style: const TextStyle(
                                    color: Color(0xFFDCDDDE),
                                    fontSize: 15,
                                  ),
                                  decoration: InputDecoration(
                                    hintText:
                                        'Message #${widget.chat.getDisplayName(authProvider.user?.id ?? 0)}',
                                    hintStyle: const TextStyle(
                                      color: Color(0xFF72767D),
                                      fontSize: 15,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 8,
                                    ),
                                  ),
                                  onChanged: (value) {
                                    setState(() {}); // Update send button state
                                    _chatProvider.sendTypingIndicator(
                                      widget.chat.id,
                                      value.trim().isNotEmpty,
                                    );
                                  },
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty &&
                                        !_isSendingMessage) {
                                      _sendMessage();
                                    }
                                  },
                                ),
                              ),
                            ),

                            // Emoji button
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: IconButton(
                                icon: Icon(
                                  _showEmojiPicker
                                      ? Icons.keyboard
                                      : Icons.emoji_emotions,
                                  color: _showEmojiPicker
                                      ? const Color(0xFF5865F2)
                                      : const Color(0xFFB9BBBE),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _showEmojiPicker = !_showEmojiPicker;
                                  });
                                },
                                tooltip: _showEmojiPicker
                                    ? 'Hide Emoji'
                                    : 'Show Emoji',
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ),

                            // Voice message button
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              child: IconButton(
                                icon: Icon(
                                  _isRecordingVoice ? Icons.stop : Icons.mic,
                                  color: _isRecordingVoice
                                      ? Colors.red
                                      : _messageController.text
                                            .trim()
                                            .isNotEmpty
                                      ? const Color(0xFF72767D)
                                      : const Color(0xFFB9BBBE),
                                ),
                                onPressed:
                                    _messageController.text.trim().isNotEmpty
                                    ? null
                                    : (_isRecordingVoice
                                          ? _stopVoiceRecording
                                          : _startVoiceRecording),
                                tooltip:
                                    _messageController.text.trim().isNotEmpty
                                    ? 'Cannot record while typing'
                                    : (_isRecordingVoice
                                          ? 'Stop Recording'
                                          : 'Record Voice Message'),
                                padding: const EdgeInsets.all(8),
                                constraints: const BoxConstraints(
                                  minWidth: 44,
                                  minHeight: 44,
                                ),
                              ),
                            ),

                            // Send button (only show when there's text)
                            if (_messageController.text.trim().isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(
                                  right: 8,
                                  bottom: 4,
                                ),
                                child: IconButton(
                                  icon: _isSendingMessage
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFF5865F2),
                                                ),
                                          ),
                                        )
                                      : const Icon(
                                          Icons.send_rounded,
                                          color: Color(0xFF5865F2),
                                        ),
                                  onPressed: _isSendingMessage
                                      ? null
                                      : _sendMessage,
                                  tooltip: _isSendingMessage
                                      ? 'Sending...'
                                      : 'Send message',
                                  padding: const EdgeInsets.all(8),
                                  constraints: const BoxConstraints(
                                    minWidth: 44,
                                    minHeight: 44,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Character count for long messages
                        if (_messageController.text.length > 1800)
                          Padding(
                            padding: const EdgeInsets.only(
                              right: 12,
                              bottom: 8,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  '${_messageController.text.length}/2000',
                                  style: TextStyle(
                                    color: _messageController.text.length > 2000
                                        ? const Color(0xFFED4245)
                                        : const Color(0xFF96989D),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Emoji Picker
          if (_showEmojiPicker)
            Container(
              height: 250,
              decoration: const BoxDecoration(
                color: Color(0xFF2F3136),
                border: Border(
                  top: BorderSide(color: Color(0xFF202225), width: 1),
                ),
              ),
              child: EmojiPicker(
                onEmojiSelected: (category, emoji) {
                  _onEmojiSelected(emoji);
                },
                config: const Config(
                  emojiViewConfig: EmojiViewConfig(
                    columns: 8,
                    emojiSizeMax: 28,
                    verticalSpacing: 0,
                    horizontalSpacing: 0,
                    gridPadding: EdgeInsets.zero,
                    recentsLimit: 28,
                    replaceEmojiOnLimitExceed: false,
                    noRecents: Text(
                      'No Recents',
                      style: TextStyle(color: Color(0xFF96989D), fontSize: 20),
                      textAlign: TextAlign.center,
                    ),
                    loadingIndicator: SizedBox.shrink(),
                    buttonMode: ButtonMode.MATERIAL,
                  ),
                  categoryViewConfig: CategoryViewConfig(
                    initCategory: Category.SMILEYS,
                    backgroundColor: Color(0xFF2F3136),
                    indicatorColor: Color(0xFF5865F2),
                    iconColor: Color(0xFF96989D),
                    iconColorSelected: Color(0xFF5865F2),
                    backspaceColor: Color(0xFF96989D),
                    tabIndicatorAnimDuration: kTabScrollDuration,
                    categoryIcons: CategoryIcons(),
                  ),
                  skinToneConfig: SkinToneConfig(
                    enabled: true,
                    dialogBackgroundColor: Color(0xFF36393F),
                    indicatorColor: Color(0xFF5865F2),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _showFilePickerOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF2F3136),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFF4E5058),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Title
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    const Text(
                      'Send a file',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Options
              _buildFileOption(
                icon: Icons.camera_alt,
                iconColor: const Color(0xFFED4245),
                title: 'Take Photo',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              _buildFileOption(
                icon: Icons.photo_library,
                iconColor: const Color(0xFF5865F2),
                title: 'Choose from Gallery',
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromGallery();
                },
              ),
              _buildFileOption(
                icon: Icons.videocam,
                iconColor: const Color(0xFFFEE75C),
                title: 'Choose Video',
                onTap: () {
                  Navigator.pop(context);
                  _pickVideoFromGallery();
                },
              ),
              _buildFileOption(
                icon: Icons.insert_drive_file,
                iconColor: const Color(0xFF57F287),
                title: 'Choose File',
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFileOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFDCDDDE),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final file = await _filePickerService.pickImageFromCamera();
      if (file != null) {
        await _uploadFile(file);
      }
    } catch (e) {
      _showPermissionErrorSnackBar(e.toString());
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final file = await _filePickerService.pickImageFromGallery();
      if (file != null) {
        await _uploadFile(file);
      }
    } catch (e) {
      _showPermissionErrorSnackBar(e.toString());
    }
  }

  Future<void> _pickVideoFromGallery() async {
    try {
      final file = await _filePickerService.pickVideoFromGallery();
      if (file != null) {
        await _uploadFile(file);
      }
    } catch (e) {
      _showPermissionErrorSnackBar(e.toString());
    }
  }

  Future<void> _pickFile() async {
    try {
      final file = await _filePickerService.pickFile();
      if (file != null) {
        await _uploadFile(file);
      }
    } catch (e) {
      _showPermissionErrorSnackBar(e.toString());
    }
  }

  Future<void> _uploadFile(File file) async {
    if (_isUploadingFile) return; // Prevent multiple uploads

    setState(() => _isUploadingFile = true);

    try {
      await _apiService.uploadFile(widget.chat.id, file);

      // Don't manually add the message - SignalR will broadcast it automatically

      // Scroll to bottom (SignalR will trigger UI update when message arrives)
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Failed to upload file: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showPermissionErrorSnackBar(String errorMessage) {
    final isPermissionError =
        errorMessage.contains('permission') ||
        errorMessage.contains('denied') ||
        errorMessage.contains('Permanently denied');

    final isSimulatorError =
        errorMessage.contains('Simulator') ||
        errorMessage.contains('simulator');

    if (isSimulatorError) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Camera/gallery access is not available on Simulator. Please test file/camera features on a physical device.',
          ),
          duration: Duration(seconds: 6),
        ),
      );
    } else if (isPermissionError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Gallery access denied. Please grant permission in app settings to select photos/videos.',
          ),
          action: SnackBarAction(
            label: 'Settings',
            onPressed: () async {
              // Open app settings
              await openAppSettings();
            },
          ),
          duration: const Duration(seconds: 8),
        ),
      );
    } else {
      _showErrorSnackBar(errorMessage);
    }
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isNotEmpty && !_isSendingMessage) {
      setState(() => _isSendingMessage = true);

      try {
        final chatProvider = Provider.of<ChatProvider>(context, listen: false);
        await chatProvider.sendMessage(widget.chat.id, content);
        _messageController.clear();
        chatProvider.sendTypingIndicator(widget.chat.id, false);

        // Hide emoji picker after sending message
        _showEmojiPicker = false;

        // Scroll to bottom after sending
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_scrollController.hasClients) {
            _scrollController.animateTo(
              0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to send message: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isSendingMessage = false);
        }
      }
    }
  }

  void _startVoiceRecording() async {
    if (_isRecordingVoice) return;

    try {
      final hasPermission = await _filePickerService.hasMicrophonePermission();
      if (!hasPermission) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Microphone permission is required for voice messages',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      await _filePickerService.startRecording();
      setState(() {
        _isRecordingVoice = true;
        _showEmojiPicker = false; // Hide emoji picker when recording
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _stopVoiceRecording() async {
    if (!_isRecordingVoice) return;

    try {
      final audioFile = await _filePickerService.stopRecording();
      setState(() {
        _isRecordingVoice = false;
      });

      if (audioFile != null) {
        await _uploadVoiceMessage(audioFile);
      }
    } catch (e) {
      setState(() {
        _isRecordingVoice = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to stop recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _cancelVoiceRecording() async {
    if (!_isRecordingVoice) return;

    try {
      await _filePickerService.cancelRecording();
      setState(() {
        _isRecordingVoice = false;
      });
    } catch (e) {
      setState(() {
        _isRecordingVoice = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to cancel recording: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _uploadVoiceMessage(File audioFile) async {
    setState(() => _isUploadingFile = true);

    try {
      await _apiService.uploadFile(widget.chat.id, audioFile, content: 'voice');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload voice message: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUploadingFile = false);
      }
    }
  }

  void _showChatOptions(BuildContext context) {
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
            // Handle bar
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFF4E5058),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.chat.getDisplayName(
                      Provider.of<AuthProvider>(
                            context,
                            listen: false,
                          ).user?.id ??
                          0,
                    ),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Options
            _buildChatOption(
              icon: Icons.search,
              iconColor: const Color(0xFF5865F2),
              title: 'Search in chat',
              onTap: () {
                Navigator.pop(context);
                _startSearch();
              },
            ),
            _buildChatOption(
              icon: Icons.notifications_off,
              iconColor: const Color(0xFFFEE75C),
              title: 'Mute notifications',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mute notifications - Coming soon!'),
                  ),
                );
              },
            ),
            if (widget.chat.type == ChatType.group)
              _buildChatOption(
                icon: Icons.group,
                iconColor: const Color(0xFF57F287),
                title:
                    'View group details (${widget.chat.participants.length} members)',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          GroupDetailsScreen(chat: widget.chat),
                    ),
                  );
                },
              ),
            const SizedBox(height: 8),
            // Delete chat option (only for group creators or any member for 1-to-1)
            _buildChatOption(
              icon: Icons.delete,
              iconColor: const Color(0xFFED4245),
              title: widget.chat.type == ChatType.group
                  ? 'Delete group'
                  : 'Delete chat',
              onTap: () {
                Navigator.pop(context);
                _showDeleteChatConfirmation(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildChatOption({
    required IconData icon,
    required Color iconColor,
    required String title,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFFDCDDDE),
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteChatConfirmation(BuildContext context) {
    final isGroup = widget.chat.type == ChatType.group;
    final title = isGroup ? 'Delete Group' : 'Delete Chat';
    final message = isGroup
        ? 'Are you sure you want to delete this group? This will remove all members and cannot be undone.'
        : 'Are you sure you want to delete this chat? You will no longer see messages from this conversation.';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF36393F),
        title: Text(title, style: const TextStyle(color: Colors.white)),
        content: Text(message, style: const TextStyle(color: Colors.white70)),
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
              await _deleteChat();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteMessage(int messageId) async {
    try {
      await _apiService.deleteMessage(messageId);

      // Remove the message from the local list via ChatProvider
      _chatProvider.removeMessage(widget.chat.id, messageId);

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Message deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to delete message: $e')));
    }
  }

  Future<void> _deleteChat() async {
    try {
      await _apiService.deleteChat(widget.chat.id);

      // Navigate back to chat list
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${widget.chat.type == ChatType.group ? 'Group' : 'Chat'} deleted',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Failed to delete ${widget.chat.type == ChatType.group ? 'group' : 'chat'}: $e',
          ),
        ),
      );
    }
  }

  Future<void> _markMessagesAsDelivered() async {
    try {
      await _apiService.markMessagesAsDelivered(widget.chat.id);
      // The status updates will be handled via SignalR real-time updates
    } catch (e) {
      // Handle error silently or log to analytics
    }
  }

  Future<void> _loadMoreMessages() async {
    await _chatProvider.loadMoreMessages(widget.chat.id);
  }

  Future<void> _markVisibleMessagesAsSeen() async {
    final messages = _chatProvider.getMessages(widget.chat.id);
    if (messages.isEmpty) {
      return;
    }

    // Simple approach: mark all messages from other users as seen if we're near the bottom
    final scrollOffset = _scrollController.offset;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final isNearBottom =
        maxScroll - scrollOffset < 100; // Within 100 pixels of bottom

    if (!isNearBottom) return; // Only mark as seen when near bottom

    // Mark messages from other users as seen
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final unseenMessageIds = <int>[];

    for (final message in messages) {
      if (message.sender.id != authProvider.user?.id &&
          message.status != MessageStatus.seen) {
        unseenMessageIds.add(message.id);
      }
    }

    if (unseenMessageIds.isNotEmpty) {
      try {
        for (final messageId in unseenMessageIds) {
          await _apiService.markMessageAsSeen(messageId);
        }
        // Status updates will be handled via SignalR real-time updates
      } catch (e) {
        // Handle error silently or log to analytics
      }
    }
  }

  int _getFirstVisibleMessageIndex() {
    if (!_scrollController.hasClients) return -1;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Binary search to find first visible message
    final messages = _chatProvider.getMessages(widget.chat.id);
    int low = 0;
    int high = messages.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      // Estimate position (rough calculation)
      final estimatedPosition = mid * 80.0; // Approximate message height

      if (estimatedPosition < scrollOffset) {
        low = mid + 1;
      } else if (estimatedPosition > scrollOffset + viewportHeight) {
        high = mid - 1;
      } else {
        return mid;
      }
    }

    return low < messages.length ? low : -1;
  }

  int _getLastVisibleMessageIndex() {
    if (!_scrollController.hasClients) return -1;

    final scrollOffset = _scrollController.offset;
    final viewportHeight = _scrollController.position.viewportDimension;

    // Binary search to find last visible message
    final messages = _chatProvider.getMessages(widget.chat.id);
    int low = 0;
    int high = messages.length - 1;

    while (low <= high) {
      final mid = (low + high) ~/ 2;
      // Estimate position (rough calculation)
      final estimatedPosition = mid * 80.0; // Approximate message height

      if (estimatedPosition < scrollOffset) {
        low = mid + 1;
      } else if (estimatedPosition > scrollOffset + viewportHeight) {
        high = mid - 1;
      } else {
        // Find the last visible message
        int lastIndex = mid;
        while (lastIndex < messages.length - 1) {
          final nextEstimatedPosition = (lastIndex + 1) * 80.0;
          if (nextEstimatedPosition <= scrollOffset + viewportHeight) {
            lastIndex++;
          } else {
            break;
          }
        }
        return lastIndex;
      }
    }

    return high >= 0 ? high : -1;
  }
}
