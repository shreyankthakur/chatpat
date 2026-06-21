import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _userCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl = TextEditingController();

  Future<void> _register() async {
    if (_userCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill username, phone, and password')));
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
      _userCtrl.text.trim(),
      _phoneCtrl.text.trim(),
      _passCtrl.text.trim(),
    );
    if (ok && context.mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Registration failed. Username may already exist.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: const Color(0xFFB71C1C),
      appBar: AppBar(
        backgroundColor: const Color(0xFFB71C1C),
        iconTheme: const IconThemeData(color: Colors.white),
        title:
            const Text('Create Account', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
          child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(children: [
          const Icon(Icons.person_add, size: 80, color: Colors.white),
          const SizedBox(height: 8),
          const Text('ChatPat',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          _field(_userCtrl, 'Username', Icons.person),
          const SizedBox(height: 16),
          _field(_phoneCtrl, 'Phone Number', Icons.phone,
              type: TextInputType.phone),
          const SizedBox(height: 16),
          _field(_passCtrl, 'Password', Icons.lock, obscure: true),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE53935),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              onPressed: isLoading ? null : _register,
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('REGISTER',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white)),
            ),
          ),
        ]),
      )),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
          {bool obscure = false, TextInputType type = TextInputType.text}) =>
      TextField(
        controller: c,
        obscureText: obscure,
        keyboardType: type,
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
