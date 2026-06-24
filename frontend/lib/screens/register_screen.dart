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
  final _userCtrl  = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool _obscure    = true;

  static const _purple     = Color(0xFF7C4DFF);
  static const _purpleDark = Color(0xFF512DA8);
  static const _bg         = Color(0xFFF5F3FF);

  Future<void> _register() async {
    if (_userCtrl.text.isEmpty ||
        _phoneCtrl.text.isEmpty ||
        _passCtrl.text.isEmpty) {
      _snack('Please fill all fields', _purpleDark);
      return;
    }
    final auth = context.read<AuthProvider>();
    final ok   = await auth.register(
        _userCtrl.text.trim(),
        _phoneCtrl.text.trim(),
        _passCtrl.text.trim());
    if (!context.mounted) return;
    if (ok) {
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const HomeScreen()));
    } else {
      _snack(auth.errorMessage ?? 'Registration failed.', Colors.redAccent);
    }
  }

  void _snack(String msg, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content:         Text(msg),
      backgroundColor: color,
      behavior:        SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(32, 50, 32, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                    colors: [_purpleDark, _purple],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight),
                borderRadius: BorderRadius.only(
                    bottomLeft:  Radius.circular(40),
                    bottomRight: Radius.circular(40)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12)),
                      child: const Icon(Icons.arrow_back_rounded,
                          color: Colors.white, size: 20),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    width: 60, height: 60,
                    decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.person_add_rounded,
                        color: Colors.white, size: 32),
                  ),
                  const SizedBox(height: 16),
                  const Text('Create Account',
                      style: TextStyle(color: Colors.white, fontSize: 32,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  const Text('Join chatpat today 🎉',
                      style: TextStyle(color: Colors.white70, fontSize: 15)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 36, 24, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Sign Up',
                      style: TextStyle(fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A1A2E))),
                  const SizedBox(height: 6),
                  const Text('Fill in your details to get started',
                      style: TextStyle(color: Colors.grey, fontSize: 13)),
                  const SizedBox(height: 28),
                  _field(controller: _userCtrl, label: 'Username',
                      icon: Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _field(controller: _phoneCtrl, label: 'Phone Number',
                      icon: Icons.phone_outlined,
                      type: TextInputType.phone),
                  const SizedBox(height: 16),
                  _field(controller: _passCtrl, label: 'Password',
                      icon: Icons.lock_outline_rounded,
                      obscure: _obscure,
                      suffix: IconButton(
                        icon: Icon(_obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                            color: _purple),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      )),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _purple,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16))),
                      onPressed: isLoading ? null : _register,
                      child: isLoading
                          ? const SizedBox(width: 24, height: 24,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5))
                          : const Text('Create Account',
                              style: TextStyle(fontSize: 16,
                                  fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    const Text('Already have an account? ',
                        style: TextStyle(color: Colors.grey)),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Sign In',
                          style: TextStyle(color: _purple,
                              fontWeight: FontWeight.bold)),
                    ),
                  ]),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String   label,
    required IconData icon,
    bool    obscure = false,
    Widget? suffix,
    TextInputType type = TextInputType.text,
  }) =>
      TextField(
        controller:   controller,
        obscureText:  obscure,
        keyboardType: type,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText:  label,
          labelStyle: const TextStyle(color: Colors.grey),
          prefixIcon: Icon(icon, color: _purple, size: 22),
          suffixIcon: suffix,
          filled:     true,
          fillColor:  Colors.white,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: _purple, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 16),
        ),
      );
}