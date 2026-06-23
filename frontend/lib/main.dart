import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack: ${details.stack}');
  };

  // Use Flutter's guarded runner to prevent hard crashes.
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrint('FlutterError: ${details.exceptionAsString()}');
    debugPrint('Stack: ${details.stack}');
  };

  // NOTE: runZonedGuarded requires dart:async; we rely on FlutterError + guarded init below.

  if (!kIsWeb) {
    // Request battery optimization exemption (critical for Samsung)
    try {
      await Permission.ignoreBatteryOptimizations.request();
    } catch (_) {}

    // Request notification permission (Android 13+)
    try {
      await Permission.notification.request();
    } catch (_) {}

    try {
      await NotificationService.init();
    } catch (e) {
      debugPrint('Notification init error: $e');
    }

    try {
      await BackgroundService.init();
    } catch (e) {
      debugPrint('Background service init error: $e');
    }
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'chatpat',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: const AuthWrapper(),
      );
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});
  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    context.read<AuthProvider>().tryAutoLogin();
  }

  @override
  Widget build(BuildContext context) {
    final token = context.watch<AuthProvider>().token;
    return token != null ? const HomeScreen() : const LoginScreen();
  }
}
