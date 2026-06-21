import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _userCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _login() async {
    if (_userCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok   = await auth.login(
      _userCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    if (ok && context.mounted) {
      Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid username or password')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      body: Center(child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const SizedBox(height: 40),
          const Icon(Icons.chat_bubble, size: 90, color: Colors.white),
          const SizedBox(height: 12),
          const Text('ChatPat', style: TextStyle(
              color: Colors.white, fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: 2)),
          const Text('Chat with anyone, anywhere',
              style: TextStyle(color: Colors.white60, fontSize: 14)),
          const SizedBox(height: 48),
          _field(_userCtrl, 'Username', Icons.person),
          const SizedBox(height: 16),
          _field(_passCtrl, 'Password', Icons.lock, obscure: true),
          const SizedBox(height: 24),
          SizedBox(width: double.infinity, height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isLoading ? null : _login,
              child: isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('LOGIN',
                    style: TextStyle(fontSize: 16,
                        fontWeight: FontWeight.bold, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const RegisterScreen())),
            child: const Text("Don't have an account? Register",
                style: TextStyle(color: Colors.white70, fontSize: 14)),
          ),
        ]),
      )),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {bool obscure = false}) =>
    TextField(
      controller: c, obscureText: obscure,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white70),
        enabledBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white30)),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.white)),
      ),
    );
}