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

  // Dynamic theme getters — signup page has no dark mode yet, but reads accent
  Color get _accent {
    final stored = box.get("fontColor");
    if (stored != null) { try { return Color(stored as int); } catch (_) {} }
    return const Color(0xFFE8945A);
  }
  bool get _isDark => box.get("darkMode", defaultValue: false) as bool;
  Color get _bg => _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
  Color get _textDark => _isDark ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _subtle => _isDark ? const Color(0xFF8E8E93) : const Color(0xFF888888);
  Color get _cardColor => _isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
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
                        Text('Do Your Things',
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Center(child: Text('Get started', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5))),
                  const SizedBox(height: 6),
                  Center(child: Text('Create a local account', style: TextStyle(fontSize: 15, color: _subtle))),
                  const SizedBox(height: 40),

                  AuthInputLabel(label: 'Username', textColor: _textDark),
                  AuthTextField(
                    controller: _username,
                    placeholder: 'Choose a username',
                    cardColor: _cardColor,
                    textColor: _textDark,
                    subtextColor: _subtle,
                    prefix: Icon(CupertinoIcons.person, size: 18, color: _subtle),
                  ),
                  const SizedBox(height: 16),

                  AuthInputLabel(label: 'Password', textColor: _textDark),
                  AuthTextField(
                    controller: _password,
                    placeholder: 'Create a password',
                    cardColor: _cardColor,
                    textColor: _textDark,
                    subtextColor: _subtle,
                    prefix: Icon(CupertinoIcons.padlock, size: 18, color: _subtle),
                    obscureText: hidePassword,
                    suffix: CupertinoButton(
                      padding: EdgeInsets.zero,
                      child: Icon(hidePassword ? CupertinoIcons.eye : CupertinoIcons.eye_slash, size: 18, color: _subtle),
                      onPressed: () => setState(() => hidePassword = !hidePassword),
                    ),
                  ),
                  const SizedBox(height: 28),

                  AuthPrimaryButton(
                    label: 'Create Account',
                    color: _accent,
                    onPressed: () {
                      if (_username.text.trim().isEmpty || _password.text.trim().isEmpty) {
                        showCupertinoDialog(
                          context: context,
                          builder: (_) => CupertinoAlertDialog(
                            title: const Text("Required"),
                            content: const Text("Please fill in all fields."),
                            actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context))],
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
                            actions: [CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context))],
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
      },
    );
  }
}

