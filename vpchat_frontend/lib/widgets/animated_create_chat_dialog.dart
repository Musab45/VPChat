import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../providers/chat_provider.dart';
import '../services/api_service.dart';
import 'animations/animated_widgets.dart';
import 'animations/page_transitions.dart';
import '../screens/animated_chat_screen.dart';

class AnimatedCreateChatDialog extends StatefulWidget {
  const AnimatedCreateChatDialog({super.key});

  @override
  State<AnimatedCreateChatDialog> createState() =>
      _AnimatedCreateChatDialogState();
}

class _AnimatedCreateChatDialogState extends State<AnimatedCreateChatDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _usernameController = TextEditingController();
  final _groupNameController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _usernameController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Text('New Conversation', style: AppTypography.headlineLarge),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.backgroundLighter,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppColors.blurple,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blurple.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.white,
                unselectedLabelColor: AppColors.textMuted,
                labelStyle: AppTypography.titleMedium,
                tabs: const [
                  Tab(text: 'Direct Message'),
                  Tab(text: 'Group Chat'),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Tab content
            SizedBox(
              height: 200,
              child: TabBarView(
                controller: _tabController,
                children: [_buildDirectMessageTab(), _buildGroupChatTab()],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDirectMessageTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Enter the username of the person you want to chat with',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _usernameController,
            label: 'Username',
            icon: Icons.person_outline,
            onSubmitted: (_) => _createDirectChat(),
          ),
          const Spacer(),
          _buildCreateButton(label: 'Start Chat', onPressed: _createDirectChat),
        ],
      ),
    );
  }

  Widget _buildGroupChatTab() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildTextField(
            controller: _groupNameController,
            label: 'Group Name',
            icon: Icons.group_outlined,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: _usernameController,
            label: 'Add members (comma separated)',
            icon: Icons.person_add_outlined,
          ),
          const Spacer(),
          _buildCreateButton(
            label: 'Create Group',
            onPressed: _createGroupChat,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    void Function(String)? onSubmitted,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.backgroundDark),
      ),
      child: TextField(
        controller: controller,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        onSubmitted: onSubmitted,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textMuted,
          ),
          prefixIcon: Icon(icon, color: AppColors.textMuted),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildCreateButton({
    required String label,
    required VoidCallback onPressed,
  }) {
    return ScaleOnTap(
      onTap: _isLoading ? null : onPressed,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        height: 52,
        decoration: BoxDecoration(
          gradient: _isLoading ? null : AppColors.primaryGradient,
          color: _isLoading ? AppColors.backgroundLighter : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: _isLoading
              ? null
              : [
                  BoxShadow(
                    color: AppColors.blurple.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Center(
          child: _isLoading
              ? const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    color: AppColors.blurple,
                    strokeWidth: 2,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      style: AppTypography.titleMedium.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Future<void> _createDirectChat() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      _showError('Please enter a username');
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.username == username) {
      _showError('You cannot create a chat with yourself');
      return;
    }

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await _apiService.createOneToOneChat(username);
      await chatProvider.loadChats();

      if (mounted) {
        Navigator.pop(context);
        AppNavigator.push(context, AnimatedChatScreen(chat: chat));
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _createGroupChat() async {
    final groupName = _groupNameController.text.trim();
    final membersText = _usernameController.text.trim();

    if (groupName.isEmpty) {
      _showError('Please enter a group name');
      return;
    }

    if (membersText.isEmpty) {
      _showError('Please add at least one member');
      return;
    }

    final members = membersText
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    setState(() => _isLoading = true);
    HapticFeedback.mediumImpact();

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final chat = await _apiService.createGroupChat(groupName, members);
      await chatProvider.loadChats();

      if (mounted) {
        Navigator.pop(context);
        AppNavigator.push(context, AnimatedChatScreen(chat: chat));
      }
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
}
