import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'homepage.dart';
import 'signup.dart';
import 'notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox("database");
  await NotificationService.instance.init();
  await NotificationService.instance.requestPermissions();
  runApp(const MyApp());
}
class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _State();
}
class _State extends State<MyApp> {
  final box = Hive.box("database");

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final stored = box.get("fontColor");
        Color accent = const Color(0xFFE8945A);
        if (stored != null) {
          try { accent = Color(stored as int); } catch (_) {}
        }
        return CupertinoApp(
          title: 'todolist',
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(primaryColor: accent),
          home: (box.get("username") != null) ? const LoginPage() : const SignupPage(),
        );
      },
    );
  }
}
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}
class _LoginPageState extends State<LoginPage> {
  String msg = "";
  bool hidePassword = true;
  final box = Hive.box("database");
  final TextEditingController _username = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final LocalAuthentication auth = LocalAuthentication();

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
                    Text(
                      'Do Your Things',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 28),
              Center(child: Text('Welcome back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: _textDark, letterSpacing: -0.5))),
              const SizedBox(height: 6),
              Center(child: Text('Sign in to continue', style: TextStyle(fontSize: 15, color: _subtle))),
              const SizedBox(height: 40),
              AuthInputLabel(label: 'Username', textColor: _textDark),
              AuthTextField(
                controller: _username,
                placeholder: 'Enter your username',
                cardColor: _cardColor,
                textColor: _textDark,
                subtextColor: _subtle,
                prefix: Icon(CupertinoIcons.person, size: 18, color: _subtle),
              ),
              const SizedBox(height: 16),
              AuthInputLabel(label: 'Password', textColor: _textDark),
              AuthTextField(
                controller: _password,
                placeholder: 'Enter your password',
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
                label: 'Sign In',
                color: _accent,
                onPressed: () {
                  if (_username.text.trim() == box.get("username") &&
                      _password.text.trim() == box.get("password")) {
                    Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const Homepage()));
                  } else {
                    setState(() => msg = "Invalid username or password");
                  }
                },
              ),
              if (box.get("biometrics", defaultValue: false) as bool) ...[
                const SizedBox(height: 16),
                Center(
                  child: CupertinoButton(
                    child: Column(
                      children: [
                        Icon(Icons.fingerprint_rounded, size: 44, color: _accent),
                        const SizedBox(height: 4),
                        Text('Use Biometrics', style: TextStyle(fontSize: 13, color: _subtle)),
                      ],
                    ),
                    onPressed: () async {
                      try {
                        final bool ok = await auth.authenticate(
                          localizedReason: 'Login to your account',
                          biometricOnly: true,
                        );
                        if (ok) {
                          if (!mounted) return;
                          // ignore: use_build_context_synchronously
                          Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const Homepage()));
                        }
                      } catch (e) {
                        setState(() => msg = "Auth Error: $e");
                      }
                    },
                  ),
                ),
              ],
              if (msg.isNotEmpty) ...[
                const SizedBox(height: 12),
                Center(child: Text(msg, style: const TextStyle(color: Color(0xFFFF6B6B), fontSize: 14), textAlign: TextAlign.center)),
              ],
              const SizedBox(height: 24),
              Center(
                child: CupertinoButton(
                  padding: EdgeInsets.zero,
                  child: const Text('Reset all data', style: TextStyle(color: Color(0xFFFF6B6B), fontSize: 13)),
                  onPressed: () async {
                    final biometricsOn = box.get("biometrics", defaultValue: false) as bool;
                    if (biometricsOn) {
                      try {
                        final bool ok = await auth.authenticate(
                          localizedReason: 'Authenticate to reset all data',
                          biometricOnly: true,
                        );
                        if (!ok) return;
                      } catch (e) {
                        setState(() => msg = "Auth Error: $e");
                        return;
                      }
                    }
                    if (!mounted) return;
                    showCupertinoDialog(
                      // ignore: use_build_context_synchronously
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Delete all data?"),
                        content: const Text("This cannot be undone."),
                        actions: [
                          CupertinoDialogAction(
                            isDestructiveAction: true,
                            onPressed: () {
                              box.clear();
                              Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const SignupPage()));
                            },
                            child: const Text("Delete"),
                          ),
                          CupertinoDialogAction(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancel"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
      }, // end ValueListenableBuilder
    );
  }
}
class AuthInputLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const AuthInputLabel({super.key, required this.label, required this.textColor});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 6),
    child: Text(label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textColor)),
  );
}
class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Widget? prefix, suffix;
  final bool obscureText;
  final Color cardColor, textColor, subtextColor;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    this.prefix,
    this.suffix,
    this.obscureText = false,
  });
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: CupertinoTextField(
        controller: controller,
        placeholder: placeholder,
        placeholderStyle: TextStyle(color: subtextColor, fontSize: 15),
        style: TextStyle(color: textColor, fontSize: 15),
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
class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const AuthPrimaryButton({super.key, required this.label, required this.color, required this.onPressed});
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
