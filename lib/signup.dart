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
                      Text('Create Account',
                          style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _textDark,
                              letterSpacing: -0.3)),
                      const SizedBox(height: 6),
                      Text('Join Planify and stay organized',
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
                            onTap: () =>
                                setState(() => hidePassword = !hidePassword),
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

                      // Get Started button
                      AuthPrimaryButton(
                        label: 'Get Started',
                        color: _accent,
                        onPressed: () {
                          if (_username.text.trim().isEmpty ||
                              _password.text.trim().isEmpty) {
                            showCupertinoDialog(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                title: const Text("Required"),
                                content:
                                    const Text("Please fill in all fields."),
                                actions: [
                                  CupertinoDialogAction(
                                      child: const Text("OK"),
                                      onPressed: () => Navigator.pop(context))
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
                                content: const Text(
                                    "Password must be at least 6 characters."),
                                actions: [
                                  CupertinoDialogAction(
                                      child: const Text("OK"),
                                      onPressed: () => Navigator.pop(context))
                                ],
                              ),
                            );
                            return;
                          }
                          box.put("username", _username.text.trim());
                          box.put("password", _password.text.trim());
                          box.put("biometrics", false);
                          _password.clear();
                          Navigator.pushReplacement(
                              context,
                              CupertinoPageRoute(
                                  builder: (_) => const LoginPage()));
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
        SizedBox(
          height: 255,
          width: screenWidth,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
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
                      child: Icon(CupertinoIcons.calendar_today,
                          size: 38, color: _accent),
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