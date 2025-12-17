import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/app_theme.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/animated_login_screen.dart';
import 'screens/animated_chat_list_screen.dart';
import 'services/file_picker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppColors.backgroundDark,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize permissions early
  final filePickerService = FilePickerService();
  await filePickerService.ensurePermissions();

  runApp(const VPChatApp());
}

class VPChatApp extends StatelessWidget {
  const VPChatApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, ChatProvider>(
          create: (_) => ChatProvider(),
          update: (_, auth, previous) {
            if (auth.isAuthenticated &&
                auth.token != null &&
                auth.user != null) {
              previous?.initialize(auth.token!, auth.user!);
            }
            return previous ?? ChatProvider();
          },
        ),
      ],
      child: MaterialApp(
        title: 'VPChat',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const SplashScreen();
            }
            return auth.isAuthenticated
                ? const AnimatedChatListScreen()
                : const AnimatedLoginScreen();
          },
        ),
      ),
    );
  }
}

/// Beautiful splash screen with animations
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated logo
            ScaleTransition(
              scale: _scaleAnimation,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  gradient: AppColors.accentGradient,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.blurple.withValues(alpha: 0.5),
                      blurRadius: 40,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.chat_bubble_rounded,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            ),
            const SizedBox(height: 32),
            // App name
            FadeTransition(
              opacity: _fadeAnimation,
              child: ShaderMask(
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
            ),
            const SizedBox(height: 48),
            // Loading indicator
            FadeTransition(
              opacity: _fadeAnimation,
              child: const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.blurple,
                  strokeWidth: 3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
