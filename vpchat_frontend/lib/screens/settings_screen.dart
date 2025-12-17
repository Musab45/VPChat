import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../services/settings_service.dart';
import '../widgets/animations/animated_widgets.dart';
import '../widgets/animations/page_transitions.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final SettingsService _settingsService = SettingsService();
  AppSettings _settings = AppSettings();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final settings = await _settingsService.getSettings();
    setState(() {
      _settings = settings;
      _isLoading = false;
    });
  }

  Future<void> _updateSettings(AppSettings newSettings) async {
    setState(() => _settings = newSettings);
    await _settingsService.saveSettings(newSettings);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

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
        title: Text('Settings', style: AppTypography.headlineMedium),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.blurple),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Profile card
                  FadeSlideIn(child: _buildProfileCard(authProvider)),

                  const SizedBox(height: 16),

                  // Appearance section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 100),
                    child: _buildSection(
                      title: 'APPEARANCE',
                      icon: Icons.palette_outlined,
                      children: [
                        _buildThemeSelector(),
                        _buildSliderTile(
                          icon: Icons.text_fields,
                          label: 'Font Size',
                          value: _settings.fontSize,
                          min: 0.8,
                          max: 1.4,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(fontSize: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.view_compact_outlined,
                          label: 'Compact Mode',
                          subtitle: 'Show more messages on screen',
                          value: _settings.compactMode,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(compactMode: value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chat section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 150),
                    child: _buildSection(
                      title: 'CHAT',
                      icon: Icons.chat_outlined,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.keyboard_return,
                          label: 'Enter to Send',
                          subtitle: 'Press Enter to send messages',
                          value: _settings.enterToSend,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(enterToSend: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.more_horiz,
                          label: 'Typing Indicator',
                          subtitle: 'Show when others are typing',
                          value: _settings.showTypingIndicator,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(showTypingIndicator: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.download_outlined,
                          label: 'Auto-download Media',
                          subtitle: 'Automatically download images and videos',
                          value: _settings.autoDownloadMedia,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(autoDownloadMedia: value),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Notifications section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 200),
                    child: _buildSection(
                      title: 'NOTIFICATIONS',
                      icon: Icons.notifications_outlined,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.notifications_active_outlined,
                          label: 'Push Notifications',
                          subtitle: 'Receive message notifications',
                          value: _settings.notifications.enabled,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(
                                notifications: _settings.notifications.copyWith(
                                  enabled: value,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.visibility_outlined,
                          label: 'Show Preview',
                          subtitle: 'Show message content in notifications',
                          value: _settings.notifications.showPreview,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(
                                notifications: _settings.notifications.copyWith(
                                  showPreview: value,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.volume_up_outlined,
                          label: 'Sound',
                          subtitle: 'Play notification sound',
                          value: _settings.notifications.sound,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(
                                notifications: _settings.notifications.copyWith(
                                  sound: value,
                                ),
                              ),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.vibration,
                          label: 'Vibration',
                          subtitle: 'Vibrate on notifications',
                          value: _settings.notifications.vibration,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(
                                notifications: _settings.notifications.copyWith(
                                  vibration: value,
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Privacy section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 250),
                    child: _buildSection(
                      title: 'PRIVACY',
                      icon: Icons.lock_outlined,
                      children: [
                        _buildSwitchTile(
                          icon: Icons.circle,
                          label: 'Online Status',
                          subtitle: 'Show when you\'re online',
                          value: _settings.showOnlineStatus,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(showOnlineStatus: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.done_all,
                          label: 'Read Receipts',
                          subtitle: 'Show when you\'ve read messages',
                          value: _settings.showReadReceipts,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(showReadReceipts: value),
                            );
                          },
                        ),
                        _buildSwitchTile(
                          icon: Icons.edit_outlined,
                          label: 'Typing Status',
                          subtitle: 'Show when you\'re typing',
                          value: _settings.showTypingStatus,
                          onChanged: (value) {
                            _updateSettings(
                              _settings.copyWith(showTypingStatus: value),
                            );
                          },
                        ),
                        _buildNavigationTile(
                          icon: Icons.access_time,
                          label: 'Last Seen',
                          value: _getLastSeenLabel(
                            _settings.lastSeenVisibility,
                          ),
                          onTap: () => _showLastSeenOptions(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Storage section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 300),
                    child: _buildSection(
                      title: 'STORAGE',
                      icon: Icons.storage_outlined,
                      children: [
                        _buildNavigationTile(
                          icon: Icons.folder_outlined,
                          label: 'Storage Usage',
                          value: '124 MB',
                          onTap: () => _showStorageDetails(context),
                        ),
                        _buildNavigationTile(
                          icon: Icons.delete_sweep_outlined,
                          label: 'Clear Cache',
                          onTap: () => _clearCache(context),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // About section
                  FadeSlideIn(
                    delay: const Duration(milliseconds: 350),
                    child: _buildSection(
                      title: 'ABOUT',
                      icon: Icons.info_outlined,
                      children: [
                        _buildNavigationTile(
                          icon: Icons.description_outlined,
                          label: 'Terms of Service',
                          onTap: () {},
                        ),
                        _buildNavigationTile(
                          icon: Icons.privacy_tip_outlined,
                          label: 'Privacy Policy',
                          onTap: () {},
                        ),
                        _buildInfoTile(
                          icon: Icons.code,
                          label: 'Version',
                          value: '1.0.0',
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

  Widget _buildProfileCard(AuthProvider authProvider) {
    final user = authProvider.user;
    return ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        AppNavigator.push(context, const ProfileScreen());
      },
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.blurple.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.username.isNotEmpty == true
                      ? user!.username.substring(0, 1).toUpperCase()
                      : 'U',
                  style: AppTypography.headlineLarge.copyWith(
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user?.username ?? 'Unknown',
                    style: AppTypography.titleLarge.copyWith(
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View and edit profile',
                    style: AppTypography.bodySmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
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
            child: Row(
              children: [
                Icon(icon, color: AppColors.textMuted, size: 16),
                const SizedBox(width: 8),
                Text(title, style: AppTypography.labelLarge),
              ],
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitle != null)
                  Text(subtitle, style: AppTypography.bodySmall),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: (newValue) {
              HapticFeedback.lightImpact();
              onChanged(newValue);
            },
            activeColor: AppColors.blurple,
          ),
        ],
      ),
    );
  }

  Widget _buildSliderTile({
    required IconData icon,
    required String label,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.textMuted, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: AppTypography.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                '${(value * 100).round()}%',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.blurple,
                ),
              ),
            ],
          ),
          Slider(
            value: value,
            min: min,
            max: max,
            activeColor: AppColors.blurple,
            inactiveColor: AppColors.backgroundLighter,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String label,
    String? value,
    required VoidCallback onTap,
  }) {
    return ScaleOnTap(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppColors.textMuted, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTypography.bodyLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            if (value != null) Text(value, style: AppTypography.bodyMedium),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textDark,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          Text(value, style: AppTypography.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildThemeSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Icon(
            Icons.dark_mode_outlined,
            color: AppColors.textMuted,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Theme',
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
          ),
          SegmentedButton<AppThemeMode>(
            segments: const [
              ButtonSegment(
                value: AppThemeMode.light,
                icon: Icon(Icons.light_mode, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.dark,
                icon: Icon(Icons.dark_mode, size: 16),
              ),
              ButtonSegment(
                value: AppThemeMode.system,
                icon: Icon(Icons.settings_suggest, size: 16),
              ),
            ],
            selected: {_settings.themeMode},
            onSelectionChanged: (selection) {
              HapticFeedback.lightImpact();
              _updateSettings(_settings.copyWith(themeMode: selection.first));
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.blurple;
                }
                return AppColors.backgroundLighter;
              }),
            ),
          ),
        ],
      ),
    );
  }

  String _getLastSeenLabel(LastSeenVisibility visibility) {
    switch (visibility) {
      case LastSeenVisibility.everyone:
        return 'Everyone';
      case LastSeenVisibility.contacts:
        return 'Contacts';
      case LastSeenVisibility.nobody:
        return 'Nobody';
    }
  }

  void _showLastSeenOptions(BuildContext context) {
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
              child: Text(
                'Who can see your last seen?',
                style: AppTypography.headlineMedium,
              ),
            ),
            ...LastSeenVisibility.values.map((option) {
              final isSelected = _settings.lastSeenVisibility == option;
              return ListTile(
                leading: Icon(
                  isSelected
                      ? Icons.radio_button_checked
                      : Icons.radio_button_off,
                  color: isSelected ? AppColors.blurple : AppColors.textMuted,
                ),
                title: Text(
                  _getLastSeenLabel(option),
                  style: AppTypography.bodyLarge,
                ),
                onTap: () {
                  _updateSettings(
                    _settings.copyWith(lastSeenVisibility: option),
                  );
                  Navigator.pop(context);
                },
              );
            }),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showStorageDetails(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Storage details - Coming soon!')),
    );
  }

  void _clearCache(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.backgroundLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text('Clear Cache', style: AppTypography.headlineLarge),
        content: Text(
          'This will clear all cached data including images and files. Your messages will not be affected.',
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Cache cleared!')));
            },
            child: const Text('Clear'),
          ),
        ],
      ),
    );
  }
}
