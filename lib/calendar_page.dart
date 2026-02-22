import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  final box = Hive.box("database");
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

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

  List<dynamic> get _all =>
      List<dynamic>.from(box.get("todo", defaultValue: []));

  List<dynamic> _dayTasks(DateTime day) {
    final key = DateFormat('yyyy-MM-dd').format(day);
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _all.where((t) {
      final d = t["date"];
      if (d == null || d == '') return key == today;
      return d == key;
    }).toList();
  }

  String _formatTime(dynamic timeStr) {
    if (timeStr == null || timeStr == '') return '';
    try {
      final p = (timeStr as String).split(':');
      final h = int.parse(p[0]);
      final m = int.parse(p[1]);
      final ap = h < 12 ? 'AM' : 'PM';
      final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
      return '$hh:${m.toString().padLeft(2, '0')} $ap';
    } catch (_) {
      return '';
    }
  }


  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        final tasks = _dayTasks(_selectedDay);
        return CupertinoPageScaffold(
          backgroundColor: _bg,
          navigationBar: CupertinoNavigationBar(
            middle: Text('Calendar', style: TextStyle(color: _text)),
            backgroundColor: _bg.withValues(alpha: 0.95),
            border: Border(bottom: BorderSide(
                color: _isDark ? Colors.white12 : Colors.black12, width: 0.5)),
          ),
          child: SafeArea(
            child: Column(children: [
              // ── Calendar ─────────────────────────────────────
              Container(
                margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 12, offset: const Offset(0, 3))],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: TableCalendar(
                    firstDay: DateTime.utc(2020, 1, 1),
                    lastDay: DateTime.utc(2030, 12, 31),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
                    eventLoader: _dayTasks,
                    onDaySelected: (s, f) => setState(() {
                      _selectedDay = s;
                      _focusedDay = f;
                    }),
                    calendarStyle: CalendarStyle(
                      outsideDaysVisible: false,
                      todayDecoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.25),
                          shape: BoxShape.circle),
                      selectedDecoration:
                          BoxDecoration(color: _accent, shape: BoxShape.circle),
                      todayTextStyle: TextStyle(
                          color: _accent, fontWeight: FontWeight.bold),
                      selectedTextStyle: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold),
                      defaultTextStyle: TextStyle(color: _text),
                      weekendTextStyle: TextStyle(color: _text),
                      outsideTextStyle:
                          TextStyle(color: _sub.withValues(alpha: 0.4)),
                      markerDecoration:
                          BoxDecoration(color: _accent, shape: BoxShape.circle),
                      markersMaxCount: 3,
                    ),
                    headerStyle: HeaderStyle(
                      formatButtonVisible: false,
                      titleCentered: true,
                      titleTextStyle: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: _text),
                      leftChevronIcon: Icon(CupertinoIcons.chevron_left,
                          size: 18, color: _accent),
                      rightChevronIcon: Icon(CupertinoIcons.chevron_right,
                          size: 18, color: _accent),
                      headerPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    daysOfWeekStyle: DaysOfWeekStyle(
                      weekdayStyle: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _sub),
                      weekendStyle: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _sub),
                    ),
                    rowHeight: 44,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // ── Day header ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Text(
                    DateFormat('EEE, MMM d').format(_selectedDay),
                    style: TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: _text),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(
                      '${tasks.length} task${tasks.length == 1 ? '' : 's'}',
                      style: TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w600, color: _accent),
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
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 14),
                              child: Row(children: [
                                // left accent bar
                                Container(
                                  width: 4, height: 36,
                                  decoration: BoxDecoration(
                                    color: done
                                        ? _sub.withValues(alpha: 0.3)
                                        : _accent,
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
                                            : TextDecoration.none)),
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
            ]),  // Column
          ),    // SafeArea
        );  // CupertinoPageScaffold
      },    // builder
    );      // ValueListenableBuilder
  }
}
