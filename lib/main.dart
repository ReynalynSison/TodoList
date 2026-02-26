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
          title: 'Planify',
          debugShowCheckedModeBanner: false,
          theme: CupertinoThemeData(primaryColor: accent),
          home: (box.get("username") != null) ? const LoginPage() : const SignupPage(),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Login Page
// ─────────────────────────────────────────────────────────────────────
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

  // Fixed brand color — never changes with user accent setting
  static const Color _accent = Color(0xFFE8945A);
  bool get _isDark => box.get("darkMode", defaultValue: false) as bool;
  Color get _bg => _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF2EDE8);
  Color get _textDark => _isDark ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _subtle => _isDark ? const Color(0xFF8E8E93) : const Color(0xFF888888);
  Color get _cardColor => _isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final screenWidth = MediaQuery.of(context).size.width;
        return Scaffold(
          backgroundColor: _bg,
          body: SingleChildScrollView(
            child: Column(
              children: [
                // ── Curved accent header ─────────────────────
                _buildHeader(screenWidth),

                // ── Body ─────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(28, 36, 28, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text('Welcome Back!',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text('Sign in to your account',
                          style: TextStyle(fontSize: 14, color: _subtle)),

                      const SizedBox(height: 32),

                      // Username field
                      AuthCard(
                        cardColor: _cardColor,
                        child: AuthTextField(
                          controller: _username,
                          placeholder: 'Username',
                          textColor: _textDark,
                          subtextColor: _subtle,
                          prefix: Icon(CupertinoIcons.person_fill,
                              size: 20, color: _subtle),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Password field
                      AuthCard(
                        cardColor: _cardColor,
                        child: AuthTextField(
                          controller: _password,
                          placeholder: 'Password',
                          textColor: _textDark,
                          subtextColor: _subtle,
                          prefix: Icon(CupertinoIcons.lock_fill,
                              size: 20, color: _subtle),
                          obscureText: hidePassword,
                          suffix: GestureDetector(
                            onTap: () => setState(() => hidePassword = !hidePassword),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 14),
                              child: Icon(
                                  hidePassword
                                      ? CupertinoIcons.eye
                                      : CupertinoIcons.eye_slash,
                                  size: 20,
                                  color: _subtle),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Sign In button
                      AuthPrimaryButton(
                        label: 'Sign In',
                        color: _accent,
                        onPressed: () {
                          if (_username.text.trim() == box.get("username") &&
                              _password.text.trim() == box.get("password")) {
                            Navigator.pushReplacement(context,
                                CupertinoPageRoute(builder: (_) => const Homepage()));
                          } else {
                            setState(() => msg = "Invalid username or password");
                          }
                        },
                      ),

                      // Error message
                      if (msg.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(CupertinoIcons.exclamationmark_circle,
                                  color: Color(0xFFFF6B6B), size: 16),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(msg,
                                    style: const TextStyle(
                                        color: Color(0xFFFF6B6B), fontSize: 13),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 32),

                      // Reset data
                      CupertinoButton(
                        padding: EdgeInsets.zero,
                        child: Text('Reset all data',
                            style: TextStyle(
                                color: const Color(0xFFFF6B6B).withValues(alpha: 0.8),
                                fontSize: 14)),
                        onPressed: () async {
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
                                    Navigator.pushReplacement(
                                        context,
                                        CupertinoPageRoute(
                                            builder: (_) => const SignupPage()));
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

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(double screenWidth) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // Accent wave panel
        ClipPath(
          clipper: _WaveClipper(),
          child: Container(
            width: screenWidth,
            height: 280,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_accent, _accent.withValues(alpha: 0.82)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
        ),
        // Logo + name centered inside the panel
        SizedBox(
          height: 255,
          width: screenWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              // Circle logo badge
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: _PlanifyIcon(size: 38, color: _accent),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Planify',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5),
              ),
              const SizedBox(height: 4),
              Text(
                'Plan smarter. Live better.',
                style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.85),
                    letterSpacing: 0.2),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Wave clipper for the header
// ─────────────────────────────────────────────────────────────────────
class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 50);
    path.quadraticBezierTo(
        size.width / 2, size.height + 30, size.width, size.height - 50);
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_WaveClipper old) => false;
}

// ─────────────────────────────────────────────────────────────────────
// Planify icon (calendar + check)
// ─────────────────────────────────────────────────────────────────────
class _PlanifyIcon extends StatelessWidget {
  final double size;
  final Color color;
  const _PlanifyIcon({required this.size, required this.color});
  @override
  Widget build(BuildContext context) => Icon(
        CupertinoIcons.calendar_today,
        size: size,
        color: color,
      );
}

// ─────────────────────────────────────────────────────────────────────
// Shared Auth Widgets
// ─────────────────────────────────────────────────────────────────────

/// Individual rounded white card wrapping a single field
class AuthCard extends StatelessWidget {
  final Widget child;
  final Color cardColor;
  const AuthCard({super.key, required this.child, required this.cardColor});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 3)),
        ],
      ),
      child: child,
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String placeholder;
  final Widget? prefix, suffix;
  final bool obscureText;
  final Color textColor, subtextColor;
  const AuthTextField({
    super.key,
    required this.controller,
    required this.placeholder,
    required this.textColor,
    required this.subtextColor,
    this.prefix,
    this.suffix,
    this.obscureText = false,
  });
  @override
  Widget build(BuildContext context) {
    return CupertinoTextField(
      controller: controller,
      placeholder: placeholder,
      placeholderStyle: TextStyle(color: subtextColor, fontSize: 16),
      style: TextStyle(color: textColor, fontSize: 16),
      prefix: prefix != null
          ? Padding(padding: const EdgeInsets.only(left: 16), child: prefix)
          : null,
      suffix: suffix,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
      decoration: const BoxDecoration(color: Colors.transparent),
      obscureText: obscureText,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;
  const AuthPrimaryButton(
      {super.key,
      required this.label,
      required this.color,
      required this.onPressed});
  @override
  Widget build(BuildContext context) => SizedBox(
        width: double.infinity,
        child: CupertinoButton(
          color: color,
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.symmetric(vertical: 17),
          onPressed: onPressed,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3)),
        ),
      );
}

// Keep AuthInputLabel for any remaining references
class AuthInputLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const AuthInputLabel(
      {super.key, required this.label, required this.textColor});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 8),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: textColor)),
      );
}