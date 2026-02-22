import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class NotificationPage extends StatefulWidget {
  const NotificationPage({super.key});

  @override
  State<NotificationPage> createState() => _NotificationPageState();
}

class _NotificationPageState extends State<NotificationPage> {
  final box = Hive.box("database");
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Refresh every 30 seconds so due-soon updates accurately
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  bool get _isDarkMode => box.get("darkMode", defaultValue: false) as bool;
  Color get _bgColor => _isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
  Color get _cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : CupertinoColors.white;
  Color get _textColor => _isDarkMode ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _subtextColor => _isDarkMode ? CupertinoColors.systemGrey : const Color(0xFF888888);

  List<dynamic> get _allTasks => List<dynamic>.from(box.get("todo", defaultValue: []));

  /// Returns null if the task has no time (should not appear in timed sections)
  String _getStatus(dynamic task) {
    final dateStr = task["date"];
    final timeStr = task["time"];
    // No time set → not trackable for overdue/due-soon
    if (timeStr == null || timeStr == '') return 'no-time';
    if (dateStr == null || dateStr == '') return 'no-time';
    try {
      DateTime taskDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      final parts = (timeStr as String).split(':');
      taskDate = DateTime(taskDate.year, taskDate.month, taskDate.day,
          int.parse(parts[0]), int.parse(parts[1]));
      final diff = taskDate.difference(DateTime.now());
      if (diff.isNegative) return 'overdue';
      if (diff.inSeconds <= 300) return 'due-soon';
      return 'upcoming';
    } catch (_) {
      return 'no-time';
    }
  }

  // Returns accurate remaining time label e.g. "Due in 4 min 22 sec"
  String _getDueSoonLabel(dynamic task) {
    final dateStr = task["date"];
    final timeStr = task["time"];
    if (dateStr == null || dateStr == '') return 'Due in ≤5 min';
    try {
      DateTime taskDate = DateFormat('yyyy-MM-dd').parse(dateStr);
      if (timeStr != null && timeStr != '') {
        final parts = (timeStr as String).split(':');
        taskDate = DateTime(taskDate.year, taskDate.month, taskDate.day,
            int.parse(parts[0]), int.parse(parts[1]));
      } else {
        return 'Due in ≤5 min';
      }
      final diff = taskDate.difference(DateTime.now());
      if (diff.isNegative) return 'Overdue';
      final mins = diff.inMinutes;
      final secs = diff.inSeconds % 60;
      if (mins > 0) return 'Due in ${mins}m ${secs}s';
      return 'Due in ${secs}s';
    } catch (_) {
      return 'Due in ≤5 min';
    }
  }

  String _formatDeadline(dynamic task) {
    final dateStr = task["date"];
    final timeStr = task["time"];
    if (dateStr == null || dateStr == '') return 'No deadline set';
    String result = '';
    try {
      final d = DateFormat('yyyy-MM-dd').parse(dateStr);
      result = DateFormat('MMM d, yyyy').format(d);
    } catch (_) {}
    if (timeStr != null && timeStr != '') {
      try {
        final parts = (timeStr as String).split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final ampm = h < 12 ? 'AM' : 'PM';
        final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final mm = m.toString().padLeft(2, '0');
        result += '  ·  $hh:$mm $ampm';
      } catch (_) {}
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final tasks = _allTasks.where((t) => t["isDone"] != true).toList();
        final overdue   = tasks.where((t) => _getStatus(t) == 'overdue').toList();
        final dueSoon   = tasks.where((t) => _getStatus(t) == 'due-soon').toList();
        final upcoming  = tasks.where((t) => _getStatus(t) == 'upcoming').toList();
        final noTime    = tasks.where((t) => _getStatus(t) == 'no-time').toList();
        final hasAlerts = overdue.isNotEmpty || dueSoon.isNotEmpty || upcoming.isNotEmpty;

        return CupertinoPageScaffold(
      backgroundColor: _bgColor,
      navigationBar: CupertinoNavigationBar(
        middle: Text('Notifications', style: TextStyle(color: _textColor)),
        backgroundColor: _bgColor.withValues(alpha: 0.95),
        border: Border(bottom: BorderSide(
            color: _isDarkMode ? Colors.white12 : Colors.black12, width: 0.5)),
      ),
      child: SafeArea(
        child: tasks.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.bell_slash, size: 56,
                        color: _subtextColor.withValues(alpha: 0.35)),
                    const SizedBox(height: 12),
                    Text('No active tasks',
                        style: TextStyle(color: _subtextColor, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text('Add tasks in the Tasks tab',
                        style: TextStyle(
                            color: _subtextColor.withValues(alpha: 0.6),
                            fontSize: 13)),
                  ],
                ),
              )
            : !hasAlerts && noTime.isNotEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(CupertinoIcons.clock_fill, size: 56,
                          color: _subtextColor.withValues(alpha: 0.35)),
                      const SizedBox(height: 14),
                      Text('No alerts yet',
                          style: TextStyle(
                              color: _textColor,
                              fontSize: 17,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(
                        'Your tasks don\'t have a time set.\nSet a time when adding a task so it appears here as Upcoming, Due Soon, or Overdue.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: _subtextColor,
                            fontSize: 13,
                            height: 1.5),
                      ),
                    ],
                  ),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  if (overdue.isNotEmpty) ...[
                    _SectionHeader(label: 'Overdue',
                        color: const Color(0xFFFF6B6B),
                        icon: CupertinoIcons.exclamationmark_circle_fill),
                    ...overdue.map((t) => _NotifCard(
                          task: t,
                          statusColor: const Color(0xFFFF6B6B),
                          statusLabel: 'Overdue',
                          deadline: _formatDeadline(t),
                          cardColor: _cardColor,
                          textColor: _textColor,
                          subtextColor: _subtextColor,
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (dueSoon.isNotEmpty) ...[
                    _SectionHeader(label: 'Due Soon',
                        color: const Color(0xFFFFB300),
                        icon: CupertinoIcons.clock_fill),
                    ...dueSoon.map((t) => _NotifCard(
                          task: t,
                          statusColor: const Color(0xFFFFB300),
                          statusLabel: _getDueSoonLabel(t),
                          deadline: _formatDeadline(t),
                          cardColor: _cardColor,
                          textColor: _textColor,
                          subtextColor: _subtextColor,
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _SectionHeader(label: 'Upcoming',
                        color: const Color(0xFF5B9CF6),
                        icon: CupertinoIcons.calendar_today),
                    ...upcoming.map((t) => _NotifCard(
                          task: t,
                          statusColor: const Color(0xFF5B9CF6),
                          statusLabel: 'Upcoming',
                          deadline: _formatDeadline(t),
                          cardColor: _cardColor,
                          textColor: _textColor,
                          subtextColor: _subtextColor,
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (noTime.isNotEmpty) ...[
                    _SectionHeader(
                        label: 'No Time Set',
                        color: _subtextColor,
                        icon: CupertinoIcons.clock),
                    // Info banner
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _subtextColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _subtextColor.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.info_circle, size: 16, color: _subtextColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'These tasks have no time set and won\'t trigger alerts. Edit the task and add a time to track them here.',
                              style: TextStyle(fontSize: 12, color: _subtextColor, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ...noTime.map((t) => _NotifCard(
                          task: t,
                          statusColor: _subtextColor,
                          statusLabel: 'No Time',
                          deadline: _formatDeadline(t),
                          cardColor: _cardColor,
                          textColor: _textColor,
                          subtextColor: _subtextColor,
                        )),
                  ],
                ],
              ),
      ),
    );
      }, // end ValueListenableBuilder builder
    );   // end ValueListenableBuilder
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _SectionHeader(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(label.toUpperCase(),
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 1.2)),
        ]),
      );
}

class _NotifCard extends StatelessWidget {
  final dynamic task;
  final String statusLabel, deadline;
  final Color statusColor, cardColor, textColor, subtextColor;

  const _NotifCard({
    required this.task,
    required this.statusLabel,
    required this.statusColor,
    required this.deadline,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withValues(alpha: 0.25), width: 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2))
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                  color: statusColor, borderRadius: BorderRadius.circular(4)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(task["task"],
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: textColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(deadline,
                      style: TextStyle(fontSize: 12, color: subtextColor)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(statusLabel,
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: statusColor)),
            ),
          ],
        ),
      ),
    );
  }
}
