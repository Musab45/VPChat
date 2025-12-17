import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/chat.dart';
import '../models/user.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class GroupMember {
  final int userId;
  final String username;
  final bool isOnline;
  final DateTime? lastSeen;
  final int role; // 0 = Member, 1 = Admin, 2 = Creator
  final DateTime joinedAt;

  GroupMember({
    required this.userId,
    required this.username,
    required this.isOnline,
    this.lastSeen,
    required this.role,
    required this.joinedAt,
  });

  factory GroupMember.fromJson(Map<String, dynamic> json) {
    return GroupMember(
      userId: json['userId'] as int,
      username: json['username'] as String,
      isOnline: json['isOnline'] as bool,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'] as String)
          : null,
      role: json['role'] as int,
      joinedAt: DateTime.parse(json['joinedAt'] as String),
    );
  }

  String getRoleName() {
    switch (role) {
      case 0:
        return 'Member';
      case 1:
        return 'Admin';
      case 2:
        return 'Creator';
      default:
        return 'Member';
    }
  }

  Color getRoleColor() {
    switch (role) {
      case 0:
        return const Color(0xFF96989D); // Gray for member
      case 1:
        return const Color(0xFFFEE75C); // Yellow for admin
      case 2:
        return const Color(0xFF5865F2); // Blue for creator
      default:
        return const Color(0xFF96989D);
    }
  }
}

class GroupDetailsScreen extends StatefulWidget {
  final Chat chat;

  const GroupDetailsScreen({Key? key, required this.chat}) : super(key: key);

  @override
  State<GroupDetailsScreen> createState() => _GroupDetailsScreenState();
}

class _GroupDetailsScreenState extends State<GroupDetailsScreen> {
  final ApiService _apiService = ApiService();
  List<GroupMember>? _members;
  Map<String, dynamic>? _groupData;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGroupDetails();
  }

  Future<void> _loadGroupDetails() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Fetch real group details from API
      _groupData = await _apiService.getGroupDetails(widget.chat.id);

      // Parse members from the API response
      final membersData = _groupData!['members'] as List<dynamic>;
      _members = membersData
          .map((memberJson) => GroupMember.fromJson(memberJson))
          .toList();

      // Sort members: Creator first, then Admins, then Members
      _members!.sort((a, b) {
        if (a.role != b.role) {
          return b.role.compareTo(a.role); // Higher role first
        }
        return a.username.compareTo(
          b.username,
        ); // Alphabetical within same role
      });
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final currentUserId = authProvider.user?.id ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFF36393F),
      appBar: AppBar(
        backgroundColor: const Color(0xFF2F3136),
        elevation: 0,
        title: const Text(
          'Group Details',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFB9BBBE)),
          onPressed: () => Navigator.of(context).pop(),
          tooltip: 'Back',
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF5865F2)),
              ),
            )
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFED4245),
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Failed to load group details',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: Color(0xFF96989D),
                      fontSize: 14,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loadGroupDetails,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF5865F2),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Color(0xFF2F3136),
                      border: Border(
                        bottom: BorderSide(color: Color(0xFF202225), width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Group Icon
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: const Color(0xFF40444B),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.tag,
                            color: Color(0xFF5865F2),
                            size: 30,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Group Info
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _groupData?['name'] ??
                                    widget.chat.getDisplayName(currentUserId),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_groupData?['memberCount'] ?? _members?.length ?? 0} members',
                                style: const TextStyle(
                                  color: Color(0xFF96989D),
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Created ${DateFormat('MMM d, yyyy').format(DateTime.parse(_groupData?['createdAt'] ?? widget.chat.createdAt.toIso8601String()))}',
                                style: const TextStyle(
                                  color: Color(0xFF96989D),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Members Section
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MEMBERS',
                          style: TextStyle(
                            color: Color(0xFF96989D),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_members != null)
                          ..._members!.map(
                            (member) => _buildMemberTile(member, currentUserId),
                          ),
                      ],
                    ),
                  ),

                  // Leave Group Section (only for non-creators)
                  if (_members != null && !_isCurrentUserCreator(currentUserId))
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFED4245).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFED4245).withOpacity(0.3),
                          ),
                        ),
                        child: Column(
                          children: [
                            const Icon(
                              Icons.exit_to_app,
                              color: Color(0xFFED4245),
                              size: 32,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Leave Group',
                              style: TextStyle(
                                color: Color(0xFFED4245),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'You will no longer receive messages from this group',
                              style: TextStyle(
                                color: Color(0xFF96989D),
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () =>
                                  _showLeaveGroupConfirmation(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFED4245),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                              ),
                              child: const Text('Leave Group'),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
      floatingActionButton: _canAddMembers(currentUserId)
          ? FloatingActionButton(
              onPressed: () => _showAddMemberDialog(context),
              backgroundColor: const Color(0xFF5865F2),
              child: const Icon(Icons.person_add, color: Colors.white),
              tooltip: 'Add Member',
            )
          : null,
    );
  }

  Widget _buildMemberTile(GroupMember member, int currentUserId) {
    final isCurrentUser = member.userId == currentUserId;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2F3136),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF40444B),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.person,
              color: member.isOnline
                  ? const Color(0xFF57F287)
                  : const Color(0xFF96989D),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Member Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      member.username,
                      style: TextStyle(
                        color: isCurrentUser
                            ? const Color(0xFF5865F2)
                            : Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5865F2).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'YOU',
                          style: TextStyle(
                            color: Color(0xFF5865F2),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: member.getRoleColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        member.getRoleName(),
                        style: TextStyle(
                          color: member.getRoleColor(),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      member.isOnline
                          ? 'Online'
                          : member.lastSeen != null
                          ? 'Last seen ${DateFormat('MMM d').format(member.lastSeen!)}'
                          : 'Offline',
                      style: TextStyle(
                        color: member.isOnline
                            ? const Color(0xFF57F287)
                            : const Color(0xFF96989D),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Online indicator
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: member.isOnline
                  ? const Color(0xFF57F287)
                  : Colors.transparent,
              shape: BoxShape.circle,
              border: member.isOnline
                  ? null
                  : Border.all(color: const Color(0xFF96989D), width: 1),
            ),
          ),
        ],
      ),
    );
  }

  bool _canAddMembers(int currentUserId) {
    if (_members == null) return false;

    // Check if current user is admin or creator
    final currentUserMember = _members!.firstWhere(
      (member) => member.userId == currentUserId,
      orElse: () => GroupMember(
        userId: 0,
        username: '',
        isOnline: false,
        role: 0,
        joinedAt: DateTime.now(),
      ),
    );

    // Role 1 = Admin, Role 2 = Creator
    return currentUserMember.role >= 1;
  }

  void _showAddMemberDialog(BuildContext context) {
    final usernameController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => Dialog(
          backgroundColor: const Color(0xFF36393F),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                const Text(
                  'Add Member',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter the username of the person you want to add',
                  style: TextStyle(color: Color(0xFF96989D), fontSize: 14),
                ),
                const SizedBox(height: 24),

                // Username input
                TextField(
                  controller: usernameController,
                  style: const TextStyle(
                    color: Color(0xFFDCDDDE),
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Username',
                    hintStyle: const TextStyle(
                      color: Color(0xFF72767D),
                      fontSize: 16,
                    ),
                    filled: true,
                    fillColor: const Color(0xFF40444B),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _addMember(
                    context,
                    usernameController.text.trim(),
                    () => setState(() => isLoading = !isLoading),
                  ),
                ),

                const SizedBox(height: 24),

                // Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: isLoading
                          ? null
                          : () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF96989D),
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: isLoading
                          ? null
                          : () => _addMember(
                              context,
                              usernameController.text.trim(),
                              () => setState(() => isLoading = !isLoading),
                            ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF5865F2),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text(
                              'Add Member',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _addMember(
    BuildContext context,
    String username,
    VoidCallback toggleLoading,
  ) async {
    if (username.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please enter a username')));
      return;
    }

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    if (authProvider.user?.username == username) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You cannot add yourself to the group')),
      );
      return;
    }

    toggleLoading(); // Set loading to true

    try {
      final apiService = ApiService();
      final success = await apiService.addGroupMember(widget.chat.id, username);

      if (success && mounted) {
        Navigator.of(context).pop(); // Close dialog
        _loadGroupDetails(); // Refresh group details

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('$username added to the group')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    } finally {
      if (mounted) {
        toggleLoading(); // Set loading to false
      }
    }
  }

  bool _isCurrentUserCreator(int currentUserId) {
    if (_members == null) return false;
    final currentUserMember = _members!.firstWhere(
      (member) => member.userId == currentUserId,
      orElse: () => GroupMember(
        userId: -1,
        username: '',
        isOnline: false,
        role: 0,
        joinedAt: DateTime.now(),
      ),
    );
    return currentUserMember.role == 2; // Creator role
  }

  void _showLeaveGroupConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF36393F),
        title: const Text('Leave Group', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to leave this group? You will no longer receive messages from this group.',
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
              await _leaveGroup();
            },
            child: const Text(
              'Leave',
              style: TextStyle(color: Color(0xFFED4245)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _leaveGroup() async {
    try {
      final apiService = ApiService();
      await apiService.leaveGroup(widget.chat.id);

      // Navigate back to chat list
      Navigator.of(context).pop();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You have left the group')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to leave group: $e')));
    }
  }
}
