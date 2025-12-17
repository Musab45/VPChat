import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/create_chat_dialog.dart';
import '../widgets/create_group_dialog.dart';
import 'chat_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({Key? key}) : super(key: key);

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    if (isMobile) {
      return _buildMobileLayout(authProvider, chatProvider);
    } else {
      return _buildDesktopLayout(authProvider, chatProvider);
    }
  }

  Widget _buildMobileLayout(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3136),
        elevation: 0,
        title: const Text(
          'Realtime Chat',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          // Connection status in app bar for mobile
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: chatProvider.isConnected ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  chatProvider.isConnected ? 'Online' : 'Offline',
                  style: TextStyle(
                    color: chatProvider.isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Menu button with logout option
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white70),
            onSelected: (value) async {
              if (value == 'logout') {
                await authProvider.logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.white70),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
            color: const Color(0xFF2F3136),
          ),
        ],
      ),
      body: _buildChatList(authProvider, chatProvider, isMobile: true),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateChatMenu(context),
        backgroundColor: const Color(0xFF5865F2),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildDesktopLayout(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      body: Row(
        children: [
          // Server icons sidebar (Discord-style)
          Container(
            width: 72,
            color: const Color(0xFF202225),
            child: Column(
              children: [
                const SizedBox(height: 12),
                // Home/DM server icon
                _buildServerIcon(
                  icon: Icons.home,
                  isSelected: true,
                  onTap: () {},
                ),
                const SizedBox(height: 8),
                // Divider
                Container(
                  width: 32,
                  height: 2,
                  decoration: BoxDecoration(
                    color: const Color(0xFF2F3136),
                    borderRadius: BorderRadius.circular(1),
                  ),
                ),
                const SizedBox(height: 8),
                // Add server button
                _buildServerIcon(
                  icon: Icons.add,
                  isSelected: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Add server - Coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          // Channel sidebar with responsive width
          Container(
            width: 240,
            constraints: const BoxConstraints(
              minWidth: 280, // Minimum width for comfortable use
              maxWidth: 320, // Maximum width to prevent too wide
            ),
            color: const Color(0xFF2F3136),
            child: Column(
              children: [
                // Header
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF36393F),
                    border: Border(
                      bottom: BorderSide(color: Color(0xFF202225), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Text(
                        'Realtime Chat',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.logout,
                          color: Colors.white70,
                          size: 20,
                        ),
                        onPressed: () async {
                          await authProvider.logout();
                        },
                        tooltip: 'Logout',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                      ),
                    ],
                  ),
                ),

                // Connection status
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: chatProvider.isConnected
                              ? Colors.green
                              : Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        chatProvider.isConnected ? 'Connected' : 'Disconnected',
                        style: TextStyle(
                          color: chatProvider.isConnected
                              ? Colors.green
                              : Colors.red,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Channels header with create button
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.tag, color: Colors.white70, size: 18),
                      const SizedBox(width: 8),
                      const Text(
                        'CHANNELS',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(
                          Icons.add,
                          color: Colors.white70,
                          size: 18,
                        ),
                        onPressed: () => _showCreateChatMenu(context),
                        tooltip: 'Create new chat',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chat list
                Expanded(
                  child: _buildChatList(
                    authProvider,
                    chatProvider,
                    isMobile: false,
                  ),
                ),

                // User info at bottom
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Color(0xFF292B2F),
                    border: Border(
                      top: BorderSide(color: Color(0xFF202225), width: 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFF5865F2),
                        child: Text(
                          authProvider.user != null &&
                                  authProvider.user!.username.isNotEmpty
                              ? authProvider.user!.username
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              authProvider.user?.username ?? 'User',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: authProvider.user?.isOnline ?? false
                                        ? Colors.green
                                        : Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  authProvider.user?.isOnline ?? false
                                      ? 'Online'
                                      : 'Offline',
                                  style: TextStyle(
                                    color:
                                        (authProvider.user?.isOnline ?? false)
                                        ? Colors.green
                                        : Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
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

          // Main content area
          Expanded(
            child: Container(
              color: const Color(0xFF36393F),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.chat_bubble_outline,
                      color: Colors.white38,
                      size: 64,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select a chat to start messaging',
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Choose a conversation from the sidebar',
                      style: TextStyle(color: Colors.white38, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServerIcon({
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF5865F2)
                  : const Color(0xFF36393F),
              borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : const Color(0xFF96989D),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(
    AuthProvider authProvider,
    ChatProvider chatProvider, {
    required bool isMobile,
  }) {
    return chatProvider.isLoading
        ? const Center(
            child: CircularProgressIndicator(color: Color(0xFF5865F2)),
          )
        : chatProvider.chats.isEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.chat_bubble_outline,
                  color: Colors.white24,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'No chats yet',
                  style: TextStyle(
                    color: Colors.white54,
                    fontSize: isMobile ? 16 : 14,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Start a conversation to get chatting!',
                  style: TextStyle(
                    color: Colors.white38,
                    fontSize: isMobile ? 14 : 12,
                  ),
                ),
              ],
            ),
          )
        : ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: chatProvider.chats.length,
            itemBuilder: (context, index) {
              final chat = chatProvider.chats[index];
              return _buildChannelItem(
                chat: chat,
                authProvider: authProvider,
                isMobile: isMobile,
              );
            },
          );
  }

  Widget _buildChannelItem({
    required Chat chat,
    required AuthProvider authProvider,
    required bool isMobile,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isMobile) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ChatScreen(chat: chat)),
              );
            } else {
              // TODO: Implement desktop navigation (show chat in main area)
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Opening chat: ${chat.getDisplayName(authProvider.user?.id ?? 0)}',
                  ),
                ),
              );
            }
          },
          borderRadius: BorderRadius.circular(4),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 12,
              vertical: isMobile ? 12 : 6,
            ),
            child: Row(
              children: [
                // Channel icon
                Icon(
                  chat.type == ChatType.group ? Icons.tag : Icons.person,
                  color: const Color(0xFF96989D),
                  size: 20,
                ),
                const SizedBox(width: 12),
                // Channel name and last message
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chat.getDisplayName(authProvider.user?.id ?? 0),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isMobile ? 16 : 15,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (chat.lastMessage != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          chat.lastMessage!.content ?? 'Attachment',
                          style: const TextStyle(
                            color: Color(0xFF96989D),
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showCreateChatMenu(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF36393F),
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

            // Menu items
            ListTile(
              leading: const Icon(Icons.person, color: Color(0xFFB9BBBE)),
              title: const Text(
                'New Chat',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: const Text(
                'Start a conversation with someone',
                style: TextStyle(color: Color(0xFF96989D), fontSize: 14),
              ),
              onTap: () async {
                Navigator.of(context).pop(); // Close the menu
                final chat = await showDialog(
                  context: context,
                  builder: (context) => const CreateChatDialog(),
                );

                if (chat != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: chat),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Chat created with ${chat.getDisplayName(authProvider.user?.id ?? 0)}',
                      ),
                    ),
                  );
                }
              },
            ),

            ListTile(
              leading: const Icon(Icons.group, color: Color(0xFFB9BBBE)),
              title: const Text(
                'New Group',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              subtitle: const Text(
                'Create a group chat with multiple people',
                style: TextStyle(color: Color(0xFF96989D), fontSize: 14),
              ),
              onTap: () async {
                Navigator.of(context).pop(); // Close the menu
                final chat = await showDialog(
                  context: context,
                  builder: (context) => const CreateGroupDialog(),
                );

                if (chat != null && mounted) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(chat: chat),
                    ),
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Group "${chat.name ?? 'Unnamed Group'}" created',
                      ),
                    ),
                  );
                }
              },
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
