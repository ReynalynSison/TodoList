import 'package:flutter/cupertino.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'errands.dart';
import 'settings.dart';
import 'archive.dart';
import 'calendar_page.dart';
import 'notification_page.dart';

class Homepage extends StatefulWidget {
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  final box = Hive.box("database");

  final List<Widget> _pages = [
    const Errands(),
    const CalendarPage(),
    const NotificationPage(),
    const Archive(),
    const Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final isDark = box.get("darkMode", defaultValue: false) as bool;
        final stored = box.get("fontColor");
        Color accent = const Color(0xFFE8945A);
        if (stored != null) {
          try { accent = Color(stored as int); } catch (_) {}
        }

        final bgColor = isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
        final borderColor = isDark ? const Color(0xFF3A3A3C) : const Color(0xFFEEEEEE);
        final inactiveColor = isDark ? const Color(0xFF8E8E93) : CupertinoColors.systemGrey;

        return CupertinoTabScaffold(
          tabBar: CupertinoTabBar(
            backgroundColor: bgColor,
            activeColor: accent,
            inactiveColor: inactiveColor,
            border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.checkmark_square),
                label: 'Tasks',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.calendar),
                label: 'Calendar',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.bell),
                label: 'Alerts',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.archivebox),
                label: 'Archive',
              ),
              BottomNavigationBarItem(
                icon: Icon(CupertinoIcons.settings),
                label: 'Settings',
              ),
            ],
          ),
          tabBuilder: (context, index) => _pages[index],
        );
      },
    );
  }
}