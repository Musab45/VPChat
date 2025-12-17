import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/animations/animated_widgets.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isEditing = false;
  late TextEditingController _usernameController;
  late TextEditingController _statusController;
  String _selectedStatus = 'online';

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    _usernameController = TextEditingController(
      text: authProvider.user?.username ?? '',
    );
    _statusController = TextEditingController(
      text: 'Hey there! I\'m using VPChat',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _statusController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
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
        title: Text('Profile', style: AppTypography.headlineMedium),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: Text(
                'Save',
                style: TextStyle(
                  color: AppColors.blurple,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Profile header
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.backgroundMedium,
                  border: Border(
                    bottom: BorderSide(color: AppColors.backgroundDark),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            gradient: AppColors.accentGradient,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.blurple.withValues(alpha: 0.4),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              user?.username.isNotEmpty == true
                                  ? user!.username.substring(0, 1).toUpperCase()
                                  : 'U',
                              style: AppTypography.displayLarge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          right: 0,
                          bottom: 0,
                          child: ScaleOnTap(
                            onTap: _changeAvatar,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.blurple,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.backgroundMedium,
                                  width: 3,
                                ),
                              ),
                              child: const Icon(
                                Icons.camera_alt,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                        // Online status indicator
                        Positioned(
                          right: 4,
                          top: 4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: _getStatusColor(_selectedStatus),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.backgroundMedium,
                                width: 3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Username
                    if (_isEditing)
                      SizedBox(
                        width: 200,
                        child: TextField(
                          controller: _usernameController,
                          textAlign: TextAlign.center,
                          style: AppTypography.headlineLarge,
                          decoration: InputDecoration(
                            hintText: 'Username',
                            hintStyle: AppTypography.headlineLarge.copyWith(
                              color: AppColors.textDark,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      )
                    else
                      Text(
                        user?.username ?? 'Unknown',
                        style: AppTypography.headlineLarge,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${user?.id ?? 0}',
                      style: AppTypography.labelSmall,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Status section
            FadeSlideIn(
              delay: const Duration(milliseconds: 100),
              child: _buildSection(
                title: 'STATUS',
                children: [
                  _buildStatusOption('online', 'Online', AppColors.online),
                  _buildStatusOption('idle', 'Idle', AppColors.idle),
                  _buildStatusOption('dnd', 'Do Not Disturb', AppColors.dnd),
                  _buildStatusOption(
                    'invisible',
                    'Invisible',
                    AppColors.offline,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // About section
            FadeSlideIn(
              delay: const Duration(milliseconds: 200),
              child: _buildSection(
                title: 'ABOUT ME',
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: _isEditing
                        ? TextField(
                            controller: _statusController,
                            maxLines: 3,
                            maxLength: 150,
                            style: AppTypography.bodyLarge.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Write something about yourself...',
                              hintStyle: AppTypography.bodyLarge.copyWith(
                                color: AppColors.textDark,
                              ),
                              filled: true,
                              fillColor: AppColors.backgroundLighter,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          )
                        : Row(
                            children: [
                              Expanded(
                                child: Text(
                                  _statusController.text.isEmpty
                                      ? 'No status set'
                                      : _statusController.text,
                                  style: AppTypography.bodyLarge.copyWith(
                                    color: _statusController.text.isEmpty
                                        ? AppColors.textDark
                                        : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Account info section
            FadeSlideIn(
              delay: const Duration(milliseconds: 300),
              child: _buildSection(
                title: 'ACCOUNT',
                children: [
                  _buildInfoTile(
                    icon: Icons.person_outline,
                    label: 'Username',
                    value: user?.username ?? 'Unknown',
                  ),
                  _buildInfoTile(
                    icon: Icons.calendar_today_outlined,
                    label: 'Member since',
                    value: 'December 2024',
                  ),
                  _buildInfoTile(
                    icon: Icons.security_outlined,
                    label: 'Account status',
                    value: 'Verified',
                    valueColor: AppColors.success,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Danger zone
            FadeSlideIn(
              delay: const Duration(milliseconds: 400),
              child: _buildSection(
                title: 'DANGER ZONE',
                children: [
                  _buildActionTile(
                    icon: Icons.logout,
                    label: 'Log Out',
                    color: AppColors.warning,
                    onTap: () => _showLogoutConfirmation(context, authProvider),
                  ),
                  _buildActionTile(
                    icon: Icons.delete_forever,
                    label: 'Delete Account',
                    color: AppColors.error,
                    onTap: () => _showDeleteAccountConfirmation(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(title, style: AppTypography.labelLarge),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusOption(String value, String label, Color color) {
    final isSelected = _selectedStatus == value;
    return ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedStatus = value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.backgroundLighter : Colors.transparent,
        ),
        child: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: isSelected
                      ? AppColors.textPrimary
                      : AppColors.textSecondary,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check, color: AppColors.blurple, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: AppTypography.bodyMedium)),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ScaleOnTap(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppTypography.bodyLarge.copyWith(color: color)),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'online':
        return AppColors.online;
      case 'idle':
        return AppColors.idle;
      case 'dnd':
        return AppColors.dnd;
      case 'invisible':
        return AppColors.offline;
      default:
        return AppColors.online;
    }
  }

  void _changeAvatar() {
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Avatar upload - Coming soon!')),
    );
  }

  void _saveProfile() {
    HapticFeedback.mediumImpact();
    setState(() => _isEditing = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile updated!')));
  }

  void _showLogoutConfirmation(
    BuildContext context,
    AuthProvider authProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Log Out', style: AppTypography.headlineLarge),
        content: Text(
          'Are you sure you want to log out?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await authProvider.logout();
              if (context.mounted) {
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          'Delete Account',
          style: AppTypography.headlineLarge.copyWith(color: AppColors.error),
        ),
        content: Text(
          'This action cannot be undone. All your data will be permanently deleted.',
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Account deletion - Coming soon!'),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
