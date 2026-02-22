import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'main.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final box = Hive.box("database");
  bool hidePassword = true;
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();

  static const _accent = Color(0xFFE8945A);
  static const _bg = Color(0xFFF5F0EB);
  static const _textDark = Color(0xFF1A1A2E);
  static const _subtle = Color(0xFF888888);

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: _bg,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // App icon + name
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: _accent,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: _accent.withValues(alpha: 0.35), blurRadius: 20, offset: const Offset(0, 8))],
                      ),
                      child: const Icon(CupertinoIcons.checkmark_square_fill, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Do Your Things',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: _textDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              const Center(
                child: Text('Get started', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5)),
              ),
              const SizedBox(height: 6),
              const Center(
                child: Text('Create a local account', style: TextStyle(fontSize: 15, color: _subtle)),
              ),
              const SizedBox(height: 40),

              _InputLabel(label: 'Username'),
              _TextField(
                controller: _username,
                placeholder: 'Choose a username',
                prefix: const Icon(CupertinoIcons.person, size: 18, color: _subtle),
              ),
              const SizedBox(height: 16),

              _InputLabel(label: 'Password'),
              _TextField(
                controller: _password,
                placeholder: 'Create a password',
                prefix: const Icon(CupertinoIcons.padlock, size: 18, color: _subtle),
                obscureText: hidePassword,
                suffix: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 18, color: _subtle),
                  onPressed: () => setState(() => hidePassword = !hidePassword),
                ),
              ),
              const SizedBox(height: 28),

              _PrimaryButton(
                label: 'Create Account',
                color: _accent,
                onPressed: () {
                  if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Required"),
                        content: const Text("Please fill in all fields."),
                        actions: [
                          CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    );
                    return;
                  }
                  if (_password.text.trim().length < 6) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Password Too Short"),
                        content: const Text("Password must be at least 6 characters."),
                        actions: [
                          CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context)),
                        ],
                      ),
                    );
                    return;
                  }
                  box.put("username", _username.text.trim());
                  box.put("password", _password.text.trim());
                  box.put("biometrics", false);
                  _password.clear();
                  Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const LoginPage()));
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable Widgets (same as in main.dart) ───────────────────────────────────

class _InputLabel extends StatelessWidget {
  final String label;
  const _InputLabel({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
  );
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Widget? prefix, suffix;
  final bool obscureText;

  const _TextField({
    required this.controller,
    required this.placeholder,
    this.prefix,
    this.suffix,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: CupertinoColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: const TextStyle(color: Color(0xFF888888), fontSize: 15),
        style: const TextStyle(color: Color(0xFF1A1A2E), fontSize: 15),
        prefix: prefix != null
            ? Padding(padding: const EdgeInsets.only(left: 14), child: prefix)
            : null,
        suffix: suffix != null
            ? Padding(padding: const EdgeInsets.only(right: 10), child: suffix)
            : null,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: const BoxDecoration(color: Colors.transparent),
        obscureText: obscureText,
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _PrimaryButton({required this.label, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: CupertinoButton(
      color: color,
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.symmetric(vertical: 16),
      onPressed: onPressed,
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
    ),
  );
}
