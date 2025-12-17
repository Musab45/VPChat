import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../models/chat.dart';
import '../models/message.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/animations/animated_widgets.dart';
import '../widgets/animations/page_transitions.dart';
import '../widgets/animated_create_chat_dialog.dart';
import 'animated_chat_screen.dart';
import 'settings_screen.dart';
import 'profile_screen.dart';

class AnimatedChatListScreen extends StatefulWidget {
  const AnimatedChatListScreen({super.key});

  @override
  State<AnimatedChatListScreen> createState() => _AnimatedChatListScreenState();
}

class _AnimatedChatListScreenState extends State<AnimatedChatListScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fabController;
  late Animation<double> _fabAnimation;
  bool _isSearching = false;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
      vsync: this,
      duration: AppAnimations.slow,
    );
    _fabAnimation = CurvedAnimation(
      parent: _fabController,
      curve: AppAnimations.snappyCurve,
    );

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) _fabController.forward();
    });
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final chatProvider = Provider.of<ChatProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 768;

    return isMobile
        ? _buildMobileLayout(authProvider, chatProvider)
        : _buildDesktopLayout(authProvider, chatProvider);
  }

  Widget _buildMobileLayout(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: _buildAppBar(authProvider, chatProvider),
      body: Column(
        children: [
          // Search bar (animated)
          AnimatedContainer(
            duration: AppAnimations.normal,
            height: _isSearching ? 60 : 0,
            child: _isSearching ? _buildSearchBar() : const SizedBox.shrink(),
          ),
          // Chat list
          Expanded(
            child: _buildChatList(authProvider, chatProvider, isMobile: true),
          ),
        ],
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabAnimation,
        child: _buildFAB(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    return AppBar(
      backgroundColor: AppColors.backgroundMedium,
      elevation: 0,
      title: _isSearching
          ? null
          : FadeSlideIn(
              child: Row(
                children: [
                  // Logo
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.chat_bubble_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'VPChat',
                    style: AppTypography.headlineMedium.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
      actions: [
        // Connection status
        _buildConnectionStatus(chatProvider),
        // Search button
        IconButton(
          icon: AnimatedSwitcher(
            duration: AppAnimations.fast,
            child: Icon(
              _isSearching ? Icons.close : Icons.search,
              key: ValueKey(_isSearching),
              color: AppColors.textMuted,
            ),
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            setState(() {
              _isSearching = !_isSearching;
              if (!_isSearching) {
                _searchController.clear();
                _searchQuery = '';
              }
            });
          },
        ),
        // Menu
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: AppColors.textMuted),
          color: AppColors.backgroundMedium,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          onSelected: (value) async {
            HapticFeedback.lightImpact();
            if (value == 'profile') {
              AppNavigator.push(context, const ProfileScreen());
            } else if (value == 'settings') {
              AppNavigator.push(context, const SettingsScreen());
            } else if (value == 'logout') {
              HapticFeedback.mediumImpact();
              await authProvider.logout();
            }
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'profile',
              child: Row(
                children: [
                  const Icon(Icons.person_outline, color: AppColors.textMuted),
                  const SizedBox(width: 12),
                  Text('Profile', style: AppTypography.bodyMedium),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'settings',
              child: Row(
                children: [
                  const Icon(
                    Icons.settings_outlined,
                    color: AppColors.textMuted,
                  ),
                  const SizedBox(width: 12),
                  Text('Settings', style: AppTypography.bodyMedium),
                ],
              ),
            ),
            PopupMenuItem(
              value: 'logout',
              child: Row(
                children: [
                  const Icon(Icons.logout, color: AppColors.error),
                  const SizedBox(width: 12),
                  Text(
                    'Logout',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildConnectionStatus(ChatProvider chatProvider) {
    return AnimatedContainer(
      duration: AppAnimations.normal,
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: chatProvider.isConnected
            ? AppColors.online.withValues(alpha: 0.15)
            : AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PulseAnimation(
            animate: !chatProvider.isConnected,
            child: Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: chatProvider.isConnected
                    ? AppColors.online
                    : AppColors.error,
                shape: BoxShape.circle,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            chatProvider.isConnected ? 'Online' : 'Offline',
            style: AppTypography.labelSmall.copyWith(
              color: chatProvider.isConnected
                  ? AppColors.online
                  : AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return FadeSlideIn(
      offset: const Offset(0, -10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.backgroundMedium,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.backgroundLighter,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            autofocus: true,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search chats...',
              hintStyle: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
            onChanged: (value) =>
                setState(() => _searchQuery = value.toLowerCase()),
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
    if (chatProvider.isLoading) {
      return _buildLoadingState();
    }

    final filteredChats = chatProvider.chats.where((chat) {
      if (_searchQuery.isEmpty) return true;
      final name = chat
          .getDisplayName(authProvider.user?.id ?? 0)
          .toLowerCase();
      return name.contains(_searchQuery);
    }).toList();

    if (filteredChats.isEmpty) {
      return _buildEmptyState();
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.mediumImpact();
        await chatProvider.loadChats();
      },
      color: AppColors.blurple,
      backgroundColor: AppColors.backgroundMedium,
      child: ListView.builder(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        padding: const EdgeInsets.only(top: 8, bottom: 100),
        itemCount: filteredChats.length,
        itemBuilder: (context, index) {
          final chat = filteredChats[index];
          return StaggeredListItem(
            index: index,
            child: _buildChatItem(
              chat: chat,
              authProvider: authProvider,
              chatProvider: chatProvider,
              isMobile: isMobile,
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: AppColors.blurple),
          const SizedBox(height: 16),
          Text(
            'Loading chats...',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return FadeSlideIn(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.backgroundLighter,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                color: AppColors.textMuted,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty
                  ? 'No chats found'
                  : 'No conversations yet',
              style: AppTypography.headlineMedium.copyWith(
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Start a new chat to begin messaging',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textDark,
              ),
            ),
            if (_searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _showCreateChatMenu(context),
                icon: const Icon(Icons.add),
                label: const Text('Start a Chat'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.blurple,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildChatItem({
    required Chat chat,
    required AuthProvider authProvider,
    required ChatProvider chatProvider,
    required bool isMobile,
  }) {
    final displayName = chat.getDisplayName(authProvider.user?.id ?? 0);
    final unreadCount = chatProvider.getUnreadCount(chat.id);
    final hasUnread = unreadCount > 0;

    return ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        AppNavigator.push(context, AnimatedChatScreen(chat: chat));
      },
      onLongPress: () => _showChatOptions(context, chat),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.backgroundMedium,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasUnread
                ? AppColors.blurple.withValues(alpha: 0.3)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                Hero(
                  tag: 'avatar_${chat.id}',
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: chat.type == ChatType.group
                          ? AppColors.accentGradient
                          : null,
                      color: chat.type == ChatType.group
                          ? null
                          : _getAvatarColor(displayName),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color:
                              (chat.type == ChatType.group
                                      ? AppColors.blurple
                                      : _getAvatarColor(displayName))
                                  .withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: chat.type == ChatType.group
                          ? const Icon(
                              Icons.group,
                              color: Colors.white,
                              size: 24,
                            )
                          : Text(
                              displayName.isNotEmpty
                                  ? displayName.substring(0, 1).toUpperCase()
                                  : '?',
                              style: AppTypography.headlineMedium.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                ),
                // Online indicator
                if (chat.type != ChatType.group)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.backgroundMedium,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),
            // Chat info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          displayName,
                          style: AppTypography.titleMedium.copyWith(
                            fontWeight: hasUnread
                                ? FontWeight.w700
                                : FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Mute indicator
                      if (chatProvider.isChatMuted(chat.id))
                        Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.notifications_off,
                            size: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      if (chat.lastMessage != null)
                        Text(
                          _formatTime(chat.lastMessage!.sentAt),
                          style: AppTypography.labelSmall.copyWith(
                            color: hasUnread
                                ? AppColors.blurple
                                : AppColors.textDark,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (chat.type == ChatType.group)
                        Padding(
                          padding: const EdgeInsets.only(right: 4),
                          child: Icon(
                            Icons.group_outlined,
                            size: 14,
                            color: AppColors.textDark,
                          ),
                        ),
                      Expanded(
                        child: Text(
                          _getLastMessagePreview(chat.lastMessage),
                          style: AppTypography.bodySmall.copyWith(
                            color: hasUnread
                                ? AppColors.textSecondary
                                : AppColors.textDark,
                            fontWeight: hasUnread
                                ? FontWeight.w500
                                : FontWeight.w400,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.blurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: AppTypography.labelSmall.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
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
    );
  }

  Widget _buildFAB() {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.blurple.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.mediumImpact();
            _showCreateChatMenu(context);
          },
          borderRadius: BorderRadius.circular(16),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: Icon(Icons.edit_outlined, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(
    AuthProvider authProvider,
    ChatProvider chatProvider,
  ) {
    // Desktop layout implementation - similar to mobile but with sidebar
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: Row(
        children: [
          // Server sidebar
          _buildServerSidebar(),
          // Chat list sidebar
          Container(
            width: 300,
            color: AppColors.backgroundMedium,
            child: Column(
              children: [
                _buildDesktopHeader(authProvider),
                Expanded(
                  child: _buildChatList(
                    authProvider,
                    chatProvider,
                    isMobile: false,
                  ),
                ),
                _buildUserPanel(authProvider),
              ],
            ),
          ),
          // Main content
          Expanded(child: _buildEmptyMainContent()),
        ],
      ),
    );
  }

  Widget _buildServerSidebar() {
    return Container(
      width: 72,
      color: AppColors.backgroundDark,
      child: Column(
        children: [
          const SizedBox(height: 12),
          _buildServerIcon(Icons.home, true),
          const SizedBox(height: 8),
          Container(
            width: 32,
            height: 2,
            decoration: BoxDecoration(
              color: AppColors.backgroundLighter,
              borderRadius: BorderRadius.circular(1),
            ),
          ),
          const SizedBox(height: 8),
          _buildServerIcon(Icons.add, false),
        ],
      ),
    );
  }

  Widget _buildServerIcon(IconData icon, bool isSelected) {
    return ScaleOnTap(
      onTap: () {},
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blurple : AppColors.backgroundLight,
          borderRadius: BorderRadius.circular(isSelected ? 16 : 24),
        ),
        child: Icon(
          icon,
          color: isSelected ? Colors.white : AppColors.textMuted,
          size: 24,
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(AuthProvider authProvider) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.backgroundLight,
        border: Border(bottom: BorderSide(color: AppColors.backgroundDark)),
      ),
      child: Row(
        children: [
          Text('VPChat', style: AppTypography.headlineMedium),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textMuted),
            onPressed: () => setState(() => _isSearching = !_isSearching),
          ),
        ],
      ),
    );
  }

  Widget _buildUserPanel(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        border: Border(top: BorderSide(color: AppColors.backgroundDark)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.blurple,
            child: Text(
              authProvider.user?.username.substring(0, 1).toUpperCase() ?? 'U',
              style: AppTypography.titleMedium.copyWith(color: Colors.white),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  authProvider.user?.username ?? 'User',
                  style: AppTypography.titleMedium,
                ),
                Text(
                  'Online',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.online,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.settings_outlined,
              color: AppColors.textMuted,
              size: 20,
            ),
            onPressed: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMainContent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, color: AppColors.textDark, size: 64),
          const SizedBox(height: 16),
          Text(
            'Select a chat to start messaging',
            style: AppTypography.headlineMedium.copyWith(
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateChatMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => const AnimatedCreateChatDialog(),
    );
  }

  void _showChatOptions(BuildContext context, Chat chat) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              leading: const Icon(
                Icons.push_pin_outlined,
                color: AppColors.textMuted,
              ),
              title: Text('Pin chat', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pin - Coming soon!')),
                );
              },
            ),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, _) {
                final isMuted = chatProvider.isChatMuted(chat.id);
                return ListTile(
                  leading: Icon(
                    isMuted
                        ? Icons.notifications_active_outlined
                        : Icons.notifications_off_outlined,
                    color: AppColors.textMuted,
                  ),
                  title: Text(
                    isMuted ? 'Unmute notifications' : 'Mute notifications',
                    style: AppTypography.bodyLarge,
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    if (isMuted) {
                      chatProvider.unmuteChat(chat.id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Chat unmuted')),
                      );
                    } else {
                      _showMuteOptions(context, chat.id);
                    }
                  },
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Delete chat',
                style: AppTypography.bodyLarge.copyWith(color: AppColors.error),
              ),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showMuteOptions(BuildContext context, int chatId) {
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.backgroundMedium,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
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
              padding: const EdgeInsets.all(16),
              child: Text('Mute for...', style: AppTypography.headlineMedium),
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.textMuted),
              title: Text('1 hour', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                chatProvider.muteChat(
                  chatId,
                  duration: const Duration(hours: 1),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Muted for 1 hour')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.textMuted),
              title: Text('8 hours', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                chatProvider.muteChat(
                  chatId,
                  duration: const Duration(hours: 8),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Muted for 8 hours')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.schedule, color: AppColors.textMuted),
              title: Text('1 week', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                chatProvider.muteChat(
                  chatId,
                  duration: const Duration(days: 7),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Muted for 1 week')),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications_off,
                color: AppColors.textMuted,
              ),
              title: Text('Forever', style: AppTypography.bodyLarge),
              onTap: () {
                Navigator.pop(context);
                chatProvider.muteChat(chatId);
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(const SnackBar(content: Text('Chat muted')));
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      if (difference.inDays == 1) return 'Yesterday';
      if (difference.inDays < 7) {
        final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return weekdays[dateTime.weekday - 1];
      }
      return '${dateTime.day}/${dateTime.month}';
    }
    return '${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
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

  String _getLastMessagePreview(Message? message) {
    if (message == null) return 'No messages yet';

    switch (message.messageType) {
      case MessageType.text:
        return message.content ?? '';
      case MessageType.image:
        return '📷 Photo';
      case MessageType.video:
        return '🎥 Video';
      case MessageType.audio:
        return '🎵 Voice message';
      case MessageType.file:
        return '📎 ${message.fileName ?? 'File'}';
    }
  }
}
