import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../config/app_theme.dart';
import '../providers/auth_provider.dart';
import '../widgets/animations/animated_widgets.dart';

class AnimatedLoginScreen extends StatefulWidget {
  const AnimatedLoginScreen({super.key});

  @override
  State<AnimatedLoginScreen> createState() => _AnimatedLoginScreenState();
}

class _AnimatedLoginScreenState extends State<AnimatedLoginScreen>
    with TickerProviderStateMixin {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLogin = true;
  bool _obscurePassword = true;
  bool _isUsernameFocused = false;
  bool _isPasswordFocused = false;

  late AnimationController _logoController;
  late AnimationController _formController;
  late Animation<double> _logoAnimation;
  late Animation<double> _formAnimation;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _formController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _logoAnimation = CurvedAnimation(
      parent: _logoController,
      curve: AppAnimations.snappyCurve,
    );

    _formAnimation = CurvedAnimation(
      parent: _formController,
      curve: AppAnimations.defaultCurve,
    );

    _usernameFocus.addListener(() {
      setState(() => _isUsernameFocused = _usernameFocus.hasFocus);
    });

    _passwordFocus.addListener(() {
      setState(() => _isPasswordFocused = _passwordFocus.hasFocus);
    });

    // Start animations
    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      _formController.forward();
    });
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _logoController.dispose();
    _formController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Container(
            height: size.height - MediaQuery.of(context).padding.top,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const Spacer(flex: 1),

                // Logo and title
                ScaleTransition(
                  scale: _logoAnimation,
                  child: FadeTransition(
                    opacity: _logoAnimation,
                    child: _buildLogo(),
                  ),
                ),

                const SizedBox(height: 48),

                // Form
                FadeTransition(
                  opacity: _formAnimation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(_formAnimation),
                    child: _buildForm(authProvider),
                  ),
                ),

                const Spacer(flex: 2),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Animated logo container
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: AppColors.blurple.withValues(alpha: 0.4),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.chat_bubble_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 24),
        // App name with gradient
        ShaderMask(
          shaderCallback: (bounds) =>
              AppColors.accentGradient.createShader(bounds),
          child: Text(
            'VPChat',
            style: AppTypography.displayLarge.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          _isLogin ? 'Welcome back!' : 'Create your account',
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }

  Widget _buildForm(AuthProvider authProvider) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.backgroundMedium,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.backgroundLighter),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tab switcher
          _buildTabSwitcher(),
          const SizedBox(height: 24),

          // Username field
          _buildTextField(
            controller: _usernameController,
            focusNode: _usernameFocus,
            isFocused: _isUsernameFocused,
            label: 'Username',
            icon: Icons.person_outline,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
          ),
          const SizedBox(height: 16),

          // Password field
          _buildTextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            isFocused: _isPasswordFocused,
            label: 'Password',
            icon: Icons.lock_outline,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _handleSubmit(authProvider),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: AppColors.textMuted,
              ),
              onPressed: () =>
                  setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),

          // Error message
          if (authProvider.error != null) ...[
            const SizedBox(height: 16),
            FadeSlideIn(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        authProvider.error!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Submit button
          _buildSubmitButton(authProvider),

          const SizedBox(height: 16),

          // Forgot password (login only)
          if (_isLogin)
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Forgot password - Coming soon!'),
                    ),
                  );
                },
                child: Text(
                  'Forgot password?',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.blurple,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabSwitcher() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.backgroundLighter,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildTab('Login', _isLogin, () => _switchMode(true)),
          ),
          Expanded(
            child: _buildTab('Register', !_isLogin, () => _switchMode(false)),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        curve: AppAnimations.defaultCurve,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.blurple : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.blurple.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.titleMedium.copyWith(
              color: isSelected ? AppColors.textPrimary : AppColors.textMuted,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required bool isFocused,
    required String label,
    required IconData icon,
    bool obscureText = false,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    Widget? suffixIcon,
  }) {
    return AnimatedContainer(
      duration: AppAnimations.fast,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFocused ? AppColors.blurple : Colors.transparent,
          width: 2,
        ),
        boxShadow: isFocused
            ? [
                BoxShadow(
                  color: AppColors.blurple.withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: AppTypography.bodyMedium.copyWith(
            color: isFocused ? AppColors.blurple : AppColors.textMuted,
          ),
          prefixIcon: AnimatedContainer(
            duration: AppAnimations.fast,
            child: Icon(
              icon,
              color: isFocused ? AppColors.blurple : AppColors.textMuted,
            ),
          ),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: AppColors.backgroundLighter,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AuthProvider authProvider) {
    return ScaleOnTap(
      onTap: authProvider.isLoading ? null : () => _handleSubmit(authProvider),
      child: AnimatedContainer(
        duration: AppAnimations.normal,
        height: 56,
        decoration: BoxDecoration(
          gradient: authProvider.isLoading ? null : AppColors.primaryGradient,
          color: authProvider.isLoading ? AppColors.backgroundLighter : null,
          borderRadius: BorderRadius.circular(12),
          boxShadow: authProvider.isLoading
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
          child: authProvider.isLoading
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
                      _isLogin ? 'Sign In' : 'Create Account',
                      style: AppTypography.titleLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  void _switchMode(bool isLogin) {
    if (_isLogin != isLogin) {
      HapticFeedback.lightImpact();
      setState(() => _isLogin = isLogin);
    }
  }

  Future<void> _handleSubmit(AuthProvider authProvider) async {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all fields'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    bool success;
    if (_isLogin) {
      success = await authProvider.login(username, password);
    } else {
      success = await authProvider.register(username, password);
    }

    if (!success && mounted) {
      HapticFeedback.heavyImpact();
    }
  }
}
