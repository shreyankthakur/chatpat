import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb) {
    try { await NotificationService.init(); }
    catch (e) { debugPrint('Notification error: $e'); }
    try { await BackgroundService.init(); }
    catch (e) { debugPrint('Background error: $e'); }
  }
  runApp(ChangeNotifierProvider(
    create: (_) => AuthProvider(),
    child:  const MyApp(),
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
        title:                     'chatpat',
        debugShowCheckedModeBanner: false,
        theme:                     ThemeData(fontFamily: 'Roboto'),
        home:                      const AuthWrapper(),
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