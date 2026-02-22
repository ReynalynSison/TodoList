import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final box = Hive.box("database");
  DateTime _focusedMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  bool get _isDark => box.get("darkMode", defaultValue: false) as bool;
  Color get _bg => _isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
  Color get _card => _isDark ? const Color(0xFF2C2C2E) : CupertinoColors.white;
  Color get _text => _isDark ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _sub => _isDark ? CupertinoColors.systemGrey : const Color(0xFF888888);
  Color get _accent {
    final s = box.get("fontColor");
    if (s != null) { try { return Color(s as int); } catch (_) {} }
    return const Color(0xFFE8945A);
  }

  List<dynamic> get _all => List<dynamic>.from(box.get("todo", defaultValue: []));

  List<dynamic> _dayTasks(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _all.where((t) {
      final d = t["date"];
      if (d == null || d == '') return key == today;
      return d == key;
    }).toList();
  }

  bool _hasTask(DateTime day) => _dayTasks(day).isNotEmpty;

  String _formatTime(dynamic timeStr) {
    if (timeStr == null || timeStr == '') return '';
    try {
      final p = (timeStr as String).split(':');
      final h = int.parse(p[0]);
      final m = int.parse(p[1]);
      final ap = h < 12 ? 'AM' : 'PM';
      final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hh:${m.toString().padLeft(2, '0')} $ap';
    } catch (_) { return ''; }
  }

  // Returns all days to display in the grid (including padding from prev/next month)
  List<DateTime?> _buildCalendarDays() {
    final firstOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    // weekday: Mon=1 … Sun=7, we want Mon as first col (index 0)
    final startPad = (firstOfMonth.weekday - 1) % 7;
    final total = startPad + daysInMonth;
    final rows = (total / 7).ceil();
    final cells = rows * 7;
    final days = <DateTime?>[];
    for (int i = 0; i < cells; i++) {
      final dayNum = i - startPad + 1;
      if (dayNum < 1 || dayNum > daysInMonth) {
        days.add(null);
      } else {
        days.add(DateTime(_focusedMonth.year, _focusedMonth.month, dayNum));
      }
    }
    return days;
  }

  void _prevMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1));

  void _nextMonth() => setState(() =>
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1));

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final tasks = _dayTasks(_selectedDay);
        final calDays = _buildCalendarDays();
        final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
        const weekLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

        return CupertinoPageScaffold(
          backgroundColor: _bg,
          navigationBar: CupertinoNavigationBar(
            middle: Text('Calendar', style: TextStyle(color: _text)),
            backgroundColor: _bg.withValues(alpha: 0.95),
            border: Border(bottom: BorderSide(
                color: _isDark ? Colors.white12 : Colors.black12, width: 0.5)),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // ── Month Calendar Card ──────────────────────────
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 12, offset: const Offset(0, 3))],
                  ),
                  child: Column(
                    children: [
                      // Month header with nav arrows
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 36,
                            onPressed: _prevMonth,
                            child: Icon(CupertinoIcons.chevron_left, size: 18, color: _accent),
                          ),
                          Text(
                            DateFormat('MMMM yyyy').format(_focusedMonth),
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _text),
                          ),
                          CupertinoButton(
                            padding: EdgeInsets.zero,
                            minSize: 36,
                            onPressed: _nextMonth,
                            child: Icon(CupertinoIcons.chevron_right, size: 18, color: _accent),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Week day labels
                      Row(
                        children: weekLabels.map((label) => Expanded(
                          child: Center(
                            child: Text(label,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _sub)),
                          ),
                        )).toList(),
                      ),
                      const SizedBox(height: 6),
                      // Day grid
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 7,
                          mainAxisSpacing: 4,
                          crossAxisSpacing: 0,
                          childAspectRatio: 1,
                        ),
                        itemCount: calDays.length,
                        itemBuilder: (ctx, i) {
                          final day = calDays[i];
                          if (day == null) return const SizedBox.shrink();
                          final isSelected = day == _selectedDay;
                          final isToday = day == today;
                          final hasTask = _hasTask(day);
                          return GestureDetector(
                            onTap: () => setState(() => _selectedDay = day),
                            child: Container(
                              margin: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? _accent
                                    : isToday
                                        ? _accent.withValues(alpha: 0.15)
                                        : Colors.transparent,
                                shape: BoxShape.circle,
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: isToday || isSelected ? FontWeight.bold : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.white
                                          : isToday
                                              ? _accent
                                              : _text,
                                    ),
                                  ),
                                  if (hasTask)
                                    Container(
                                      width: 4, height: 4,
                                      margin: const EdgeInsets.only(top: 1),
                                      decoration: BoxDecoration(
                                        color: isSelected ? Colors.white : _accent,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ── Day header ───────────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(children: [
                    Text(
                      DateFormat('EEE, MMM d').format(_selectedDay),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _text),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _accent),
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),

                // ── Task list ────────────────────────────────────
                Expanded(
                  child: tasks.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          Icon(CupertinoIcons.calendar_badge_plus,
                              size: 48, color: _sub.withValues(alpha: 0.35)),
                          const SizedBox(height: 10),
                          Text('No tasks on this day',
                              style: TextStyle(color: _sub, fontSize: 15)),
                        ]))
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: tasks.length,
                          itemBuilder: (context, i) {
                            final t = tasks[i];
                            final done = t["isDone"] == true;
                            final time = _formatTime(t["time"]);
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _card,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 8, offset: const Offset(0, 2))],
                                ),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                child: Row(children: [
                                  Container(
                                    width: 4, height: 36,
                                    decoration: BoxDecoration(
                                      color: done ? _sub.withValues(alpha: 0.3) : _accent,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(t["task"], style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w500,
                                          color: done ? _sub : _text,
                                          decoration: done
                                              ? TextDecoration.lineThrough
                                              : TextDecoration.none,
                                          decorationColor: _sub)),
                                      if (time.isNotEmpty) ...[
                                        const SizedBox(height: 2),
                                        Row(children: [
                                          Icon(CupertinoIcons.clock, size: 11,
                                              color: _accent.withValues(alpha: 0.8)),
                                          const SizedBox(width: 3),
                                          Text(time, style: TextStyle(fontSize: 11,
                                              color: _accent.withValues(alpha: 0.8))),
                                        ]),
                                      ],
                                    ],
                                  )),
                                ]),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
