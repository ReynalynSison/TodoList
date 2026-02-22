import 'package:flutter/cupertino.dart';
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

  final List<Widget> _pages = [
    const Errands(),
    const CalendarPage(),
    const NotificationPage(),
    const Archive(),
    const Settings(),
  ];

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: CupertinoColors.systemBackground,
        activeColor: const Color(0xFFE8945A),
        inactiveColor: CupertinoColors.systemGrey,
        border: const Border(top: BorderSide(color: Color(0xFFEEEEEE), width: 0.5)),
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
      tabBuilder: (context, index) {
        return _pages[index];
      },
    );
  }
}