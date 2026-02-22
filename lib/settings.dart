import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';
import 'main.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> {
  final box = Hive.box("database");
  final _auth = LocalAuthentication();

  bool get _isDarkMode => box.get("darkMode", defaultValue: false) as bool;
  Color get _bgColor => _isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
  Color get _cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : CupertinoColors.white;
  Color get _textColor => _isDarkMode ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _subtextColor => _isDarkMode ? CupertinoColors.systemGrey : const Color(0xFF888888);
  Color get _accentColor {
    final stored = box.get("fontColor");
    if (stored != null) {
      try { return Color(stored as int); } catch (_) {}
    }
    return const Color(0xFFE8945A);
  }

  final List<Map<String, dynamic>> _colorOptions = [
    {"label": "Orange", "color": const Color(0xFFE8945A)},
    {"label": "Coral", "color": const Color(0xFFFF6B6B)},
    {"label": "Purple", "color": const Color(0xFF9B5DE5)},
    {"label": "Blue", "color": const Color(0xFF5B9CF6)},
    {"label": "Green", "color": const Color(0xFF4CAF50)},
    {"label": "Pink", "color": const Color(0xFFE91E8C)},
    {"label": "Teal", "color": const Color(0xFF26C6DA)},
    {"label": "Gold", "color": const Color(0xFFFFB300)},
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        return CupertinoPageScaffold(
      backgroundColor: _bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Settings', style: TextStyle(color: _textColor)),
        backgroundColor: _bgColor.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(color: _isDarkMode ? Colors.white12 : Colors.black12, width: 0.5)),
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
          children: [
            // ── Profile Section ──────────────────────────
            _SectionLabel(label: 'Profile', textColor: _subtextColor),
            _SettingsCard(
              isDark: _isDarkMode,
              cardColor: _cardColor,
              children: [
                _SettingRow(
                  icon: CupertinoIcons.person_circle_fill,
                  iconColor: _accentColor,
                  title: 'Account',
                  subtitle: box.get("username") ?? '',
                  trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFF888888)),
                  textColor: _textColor,
                  subtextColor: _subtextColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Appearance ─────────────────────────────
            _SectionLabel(label: 'Appearance', textColor: _subtextColor),
            _SettingsCard(
              isDark: _isDarkMode,
              cardColor: _cardColor,
              children: [
                _SettingRow(
                  icon: CupertinoIcons.moon_fill,
                  iconColor: const Color(0xFF9B5DE5),
                  title: 'Dark Mode',
                  subtitle: _isDarkMode ? 'On' : 'Off',
                  trailing: CupertinoSwitch(
                    value: _isDarkMode,
                    activeTrackColor: _accentColor,
                    onChanged: (v) => setState(() => box.put("darkMode", v)),
                  ),
                  textColor: _textColor,
                  subtextColor: _subtextColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Font Color ────────────────────────────
            _SectionLabel(label: 'Task Color', textColor: _subtextColor),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardColor,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Pick an accent color for your tasks', style: TextStyle(fontSize: 13, color: _subtextColor)),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _colorOptions.map((opt) {
                      final color = opt["color"] as Color;
                      final isSelected = _accentColor.toARGB32() == color.toARGB32();
                      return GestureDetector(
                        onTap: () => setState(() => box.put("fontColor", color.toARGB32())),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? _textColor : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 8, offset: const Offset(0, 3))]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(CupertinoIcons.checkmark, color: Colors.white, size: 18)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Security ─────────────────────────────
            _SectionLabel(label: 'Security', textColor: _subtextColor),
            _SettingsCard(
              isDark: _isDarkMode,
              cardColor: _cardColor,
              children: [
                _SettingRow(
                  icon: Icons.fingerprint_rounded,
                  iconColor: const Color(0xFF4CAF50),
                  title: 'Biometrics',
                  subtitle: 'Face ID / Touch ID',
                  trailing: CupertinoSwitch(
                    value: box.get("biometrics", defaultValue: false) as bool,
                    activeTrackColor: _accentColor,
                    onChanged: (v) async {
                      if (v) {
                        // Check if device supports biometrics
                        final bool supported = await _auth.isDeviceSupported();
                        final bool canCheck = await _auth.canCheckBiometrics;
                        if (!supported || !canCheck) {
                          if (!mounted) return;
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Not Supported"),
                              content: const Text("This device does not support Face ID or Touch ID, or no biometrics are enrolled."),
                              actions: [
                                CupertinoDialogAction(
                                  child: const Text("OK"),
                                  onPressed: () => Navigator.pop(context),
                                ),
                              ],
                            ),
                          );
                          return;
                        }
                        // Do a test auth to confirm it works
                        try {
                          final bool ok = await _auth.authenticate(
                            localizedReason: 'Confirm your identity to enable biometrics.',
                            biometricOnly: true,
                          );
                          if (!mounted) return;
                          if (ok) {
                            box.put("biometrics", true);
                          } else {
                            showCupertinoDialog(
                              context: context,
                              builder: (_) => CupertinoAlertDialog(
                                title: const Text("Authentication Failed"),
                                content: const Text("Biometrics could not be verified. Please try again."),
                                actions: [
                                  CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context)),
                                ],
                              ),
                            );
                          }
                        } catch (e) {
                          if (!mounted) return;
                          showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Error"),
                              content: Text("$e"),
                              actions: [
                                CupertinoDialogAction(child: const Text("OK"), onPressed: () => Navigator.pop(context)),
                              ],
                            ),
                          );
                        }
                      } else {
                        box.put("biometrics", false);
                      }
                    },
                  ),
                  textColor: _textColor,
                  subtextColor: _subtextColor,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── Account Actions ───────────────────────
            _SectionLabel(label: 'Account', textColor: _subtextColor),
            _SettingsCard(
              isDark: _isDarkMode,
              cardColor: _cardColor,
              children: [
                // ── Sign Out ──────────────────────────
                GestureDetector(
                  onTap: () => showCupertinoDialog(
                    context: context,
                    builder: (_) => CupertinoAlertDialog(
                      title: const Text("Sign Out?"),
                      content: const Text("You'll need to log in again."),
                      actions: [
                        CupertinoDialogAction(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pushReplacement(context, CupertinoPageRoute(builder: (_) => const LoginPage()));
                          },
                          child: const Text("Sign Out"),
                        ),
                        CupertinoDialogAction(
                          isDestructiveAction: true,
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel"),
                        ),
                      ],
                    ),
                  ),
                  child: _SettingRow(
                    icon: CupertinoIcons.square_arrow_right,
                    iconColor: const Color(0xFFFF6B6B),
                    title: 'Sign Out',
                    subtitle: '',
                    trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: Color(0xFF888888)),
                    textColor: const Color(0xFFFF6B6B),
                    subtextColor: _subtextColor,
                  ),
                ),

              ],
            ),
          ],
        ),
      ),
    );
      }, // end ValueListenableBuilder builder
    );   // end ValueListenableBuilder
  }
}

// ── UI Helpers ────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color textColor;
  const _SectionLabel({required this.label, required this.textColor});

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(left: 4, bottom: 8),
    child: Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: textColor, letterSpacing: 1.2)),
  );
}

class _SettingsCard extends StatelessWidget {
  final bool isDark;
  final Color cardColor;
  final List<Widget> children;
  const _SettingsCard({required this.isDark, required this.cardColor, required this.children});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: cardColor,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: Column(children: children),
  );
}

class _SettingRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor, textColor, subtextColor;
  final String title, subtitle;
  final Widget trailing;

  const _SettingRow({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: iconColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: textColor)),
                if (subtitle.isNotEmpty)
                  Text(subtitle, style: TextStyle(fontSize: 12, color: subtextColor)),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }
}
