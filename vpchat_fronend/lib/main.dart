import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/chat_provider.dart';
import 'screens/login_screen.dart';
import 'screens/chat_list_screen.dart';
import 'services/file_picker_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize permissions early
  final filePickerService = FilePickerService();
  await filePickerService.ensurePermissions();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

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
        title: 'Realtime Message',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark().copyWith(
          primaryColor: const Color(0xFF5865F2), // Discord blue
          scaffoldBackgroundColor: const Color(0xFF36393F), // Discord dark gray
          appBarTheme: const AppBarTheme(
            backgroundColor: Color(0xFF2F3136), // Discord darker gray
            elevation: 0,
            titleTextStyle: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            iconTheme: IconThemeData(color: Colors.white),
          ),
          cardColor: const Color(0xFF2F3136),
          dialogBackgroundColor: const Color(0xFF36393F),
          bottomSheetTheme: const BottomSheetThemeData(
            backgroundColor: Color(0xFF2F3136),
          ),
          textTheme: const TextTheme(
            bodyLarge: TextStyle(color: Colors.white),
            bodyMedium: TextStyle(color: Colors.white70),
            titleMedium: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            titleSmall: TextStyle(color: Colors.white70),
          ),
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: const Color(0xFF40444B),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
            hintStyle: const TextStyle(color: Colors.white54),
            labelStyle: const TextStyle(color: Colors.white70),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5865F2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          useMaterial3: true,
        ),
        home: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (auth.isLoading) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return auth.isAuthenticated
                ? const ChatListScreen()
                : const LoginScreen();
          },
        ),
      ),
    );
  }
}
