import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';
import 'notification_service.dart';

class Errands extends StatefulWidget {
  const Errands({super.key});

  @override
  State<Errands> createState() => _ErrandsState();
}

class _ErrandsState extends State<Errands> {
  final box = Hive.box("database");
  List<dynamic> todo = [];
  List<dynamic> archive = [];
  DateTime _selectedDay = DateTime.now();
  bool _showAll = false;
  final ScrollController _weekScrollController = ScrollController();

  // Add task fields
  final TextEditingController _taskController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
    // Auto-scroll to today after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToToday());
  }

  // Each day cell is 52px wide + 8px margin (4 each side) = 60px per item
  static const double _dayCellWidth = 60.0;

  void _scrollToToday() {
    final today = DateTime.now();
    final todayIndex = _weekDays.indexWhere((d) =>
    d.year == today.year && d.month == today.month && d.day == today.day);
    if (todayIndex < 0 || !_weekScrollController.hasClients) return;
    // Scroll so today is centered in the viewport
    final screenWidth = _weekScrollController.position.viewportDimension;
    final offset = (_dayCellWidth * todayIndex) - (screenWidth / 2) + (_dayCellWidth / 2);
    _weekScrollController.animateTo(
      offset.clamp(0.0, _weekScrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOut,
    );
  }

  void _loadData() {
    setState(() {
      todo = List<dynamic>.from(box.get("todo", defaultValue: []));
      archive = List<dynamic>.from(box.get("archive", defaultValue: []));
    });
  }

  List<dynamic> get _todayTasks {
    final selected = DateFormat('yyyy-MM-dd').format(_selectedDay);
    return todo.where((t) {
      final d = t["date"];
      if (d == null || d == "") return DateFormat('yyyy-MM-dd').format(DateTime.now()) == selected;
      return d == selected;
    }).toList();
  }


  String get _username => box.get("username", defaultValue: "there") ?? "there";

  // Show only today and the past 5 days (6 days total), no future days
  List<DateTime> get _weekDays {
    final today = DateTime.now();
    return List.generate(6, (i) => today.subtract(Duration(days: 5 - i)));
  }

  Color get _accentColor {
    final stored = box.get("fontColor");
    if (stored != null) {
      try { return Color(stored as int); } catch (_) {}
    }
    return const Color(0xFFE8945A);
  }

  bool get _isDarkMode => box.get("darkMode", defaultValue: false) as bool;

  Color get _bgColor => _isDarkMode ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);
  Color get _cardColor => _isDarkMode ? const Color(0xFF2C2C2E) : CupertinoColors.white;
  Color get _textColor => _isDarkMode ? CupertinoColors.white : const Color(0xFF1A1A2E);
  Color get _subtextColor => _isDarkMode ? CupertinoColors.systemGrey : const Color(0xFF888888);

  void _showToast(BuildContext context, String message, {Color iconColor = const Color(0xFFFFB300), IconData icon = CupertinoIcons.clock_fill}) {
    final overlay = Overlay.of(context);
    final entry = OverlayEntry(
      builder: (_) => Positioned(
        bottom: 100,
        left: 24,
        right: 24,
        child: _ToastWidget(message: message, iconColor: iconColor, icon: icon),
      ),
    );
    overlay.insert(entry);
    Future.delayed(const Duration(seconds: 3), () => entry.remove());
  }

  void _openAddSheet() {
    _taskController.clear();

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => _AddTaskSheet(
        accentColor: _accentColor,
        isDark: _isDarkMode,
        cardColor: _cardColor,
        textColor: _textColor,
        subtextColor: _subtextColor,
        onSave: (task, date, time) {
          if (task.trim().isEmpty) return;
          final dateStr = date != null ? DateFormat('yyyy-MM-dd').format(date) : DateFormat('yyyy-MM-dd').format(DateTime.now());
          final timeStr = time != null ? '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}' : null;
          setState(() {
            todo.add({
              "task": task.trim(),
              "isDone": false,
              "date": dateStr,
              "time": timeStr,
            });
            box.put("todo", todo);
          });
          if (time != null && date != null) {
            // Schedule device notification
            final scheduledTime = DateTime(
              date.year, date.month, date.day, time.hour, time.minute,
            );
            final id = NotificationService.taskId(task.trim(), dateStr);
            NotificationService.instance.scheduleTaskNotificationWithReminder(
              id: id,
              taskName: task.trim(),
              scheduledTime: scheduledTime,
            );
            _showToast(context, 'Task added to Alerts!',
                iconColor: const Color(0xFF4CAF50), icon: CupertinoIcons.bell_fill);
          } else {
            _showToast(context, 'No time set — task won\'t appear in Alerts',
                iconColor: const Color(0xFFFFB300), icon: CupertinoIcons.clock_fill);
          }
        },
      ),
    );
  }

  void _archiveTask(int globalIndex) {
    final task = todo[globalIndex];
    // Cancel notification
    final id = NotificationService.taskId(
        task["task"] ?? '', task["date"] ?? '');
    NotificationService.instance.cancelTaskNotification(id);
    setState(() {
      archive.add(task);
      todo.removeAt(globalIndex);
      box.put("todo", todo);
      box.put("archive", archive);
    });
  }

  void _deleteTask(int globalIndex) {
    final task = todo[globalIndex];
    // Cancel notification
    final id = NotificationService.taskId(
        task["task"] ?? '', task["date"] ?? '');
    NotificationService.instance.cancelTaskNotification(id);
    setState(() {
      todo.removeAt(globalIndex);
      box.put("todo", todo);
    });
  }

  void _toggleDone(int globalIndex) {
    setState(() {
      todo[globalIndex]["isDone"] = !todo[globalIndex]["isDone"];
      box.put("todo", todo);
    });
  }

  int _globalIndex(dynamic task) => todo.indexOf(task);

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        todo = List<dynamic>.from(box.get("todo", defaultValue: []));
        archive = List<dynamic>.from(box.get("archive", defaultValue: []));
        final tasks = _showAll ? todo : _todayTasks;
        final totalTasks = todo.length;
        return _buildScaffold(context, tasks, totalTasks);
      },
    );
  }

  Widget _buildScaffold(BuildContext context, List<dynamic> tasks, int totalTasks) {
    return CupertinoPageScaffold(
      backgroundColor: _bgColor,
      child: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ──────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hi, $_username!',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: _textColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$totalTasks task${totalTasks == 1 ? '' : 's'} total',
                        style: TextStyle(fontSize: 15, color: _subtextColor),
                      ),
                      const SizedBox(height: 14),
                      // ── Today / All toggle ──────────────────
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _showAll = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: !_showAll ? _accentColor : _accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Today',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: !_showAll ? Colors.white : _accentColor,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => setState(() => _showAll = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                              decoration: BoxDecoration(
                                color: _showAll ? _accentColor : _accentColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'All  ($totalTasks)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _showAll ? Colors.white : _accentColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ── Weekly Calendar Strip ───────────────────────
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    controller: _weekScrollController,
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _weekDays.length,
                    itemBuilder: (context, i) {
                      final day = _weekDays[i];
                      final isSelected = DateFormat('yyyy-MM-dd').format(day) ==
                          DateFormat('yyyy-MM-dd').format(_selectedDay);
                      final isToday = DateFormat('yyyy-MM-dd').format(day) ==
                          DateFormat('yyyy-MM-dd').format(DateTime.now());
                      final isPast = day.isBefore(DateTime(
                          DateTime.now().year, DateTime.now().month, DateTime.now().day));
                      final dayTasks = todo.where((t) {
                        final d = t["date"];
                        if (d == null || d == "") return isToday;
                        return d == DateFormat('yyyy-MM-dd').format(day);
                      }).length;

                      return GestureDetector(
                        onTap: isToday ? () => setState(() => _selectedDay = day) : null,
                        child: Opacity(
                          opacity: isPast ? 0.45 : 1.0,
                          child: Container(
                            width: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? _accentColor : _cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: isSelected
                                  ? [BoxShadow(color: _accentColor.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4))]
                                  : [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 6, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  DateFormat('EEE').format(day).toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: isSelected ? Colors.white70 : _subtextColor,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${day.day}',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : _textColor,
                                  ),
                                ),
                                if (dayTasks > 0)
                                  Container(
                                    margin: const EdgeInsets.only(top: 3),
                                    width: 5,
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : _accentColor,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 20),

                // ── Section Title ──────────────────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Text(
                    _showAll ? 'All Tasks' : DateFormat('MMMM d, yyyy').format(_selectedDay),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _textColor,
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // ── Task List ──────────────────────────────────
                Expanded(
                  child: tasks.isEmpty
                      ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.checkmark_seal, size: 54, color: _subtextColor.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text(
                          _showAll ? 'No tasks yet' : 'No tasks for this day',
                          style: TextStyle(color: _subtextColor, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                      : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 120),
                    itemCount: tasks.length,
                    itemBuilder: (context, i) {
                      final task = tasks[i];
                      final gIdx = _globalIndex(task);
                      return _TaskCard(
                        task: task,
                        accentColor: _accentColor,
                        cardColor: _cardColor,
                        textColor: _textColor,
                        subtextColor: _subtextColor,
                        isDark: _isDarkMode,
                        onToggle: () => _toggleDone(gIdx),
                        onArchive: () => _archiveTask(gIdx),
                        onDelete: () => _deleteTask(gIdx),
                      );
                    },
                  ),
                ),
              ],
            ),
            // ── Floating Add Button ──────────────────────
            Positioned(
              bottom: 24,
              right: 24,
              child: FloatingAddButton(
                color: _accentColor,
                onPressed: _openAddSheet,
              ),
            ),
          ],
        ),
      ),
    );
  } // end _buildScaffold

  @override
  void dispose() {
    _taskController.dispose();
    _weekScrollController.dispose();
    super.dispose();
  }
}

// ── Task Card ──────────────────────────────────────────────────────────────────
class _TaskCard extends StatelessWidget {
  final dynamic task;
  final Color accentColor, cardColor, textColor, subtextColor;
  final bool isDark;
  final VoidCallback onToggle, onArchive, onDelete;

  const _TaskCard({
    required this.task,
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
    required this.onToggle,
    required this.onArchive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDone = task["isDone"] == true;
    final timeStr = task["time"];
    final dateStr = task["date"];

    String subtitle = '';
    if (dateStr != null && dateStr != '') {
      try {
        final d = DateFormat('yyyy-MM-dd').parse(dateStr);
        subtitle = DateFormat('MMM d').format(d);
      } catch (_) {}
    }
    if (timeStr != null && timeStr != '') {
      try {
        final parts = (timeStr as String).split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final ampm = h < 12 ? 'AM' : 'PM';
        final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final mm = m.toString().padLeft(2, '0');
        subtitle += subtitle.isNotEmpty ? '  ·  $hh:$mm $ampm' : '$hh:$mm $ampm';
      } catch (_) {}
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Slidable(
        key: ValueKey('${task["task"]}_${task["date"]}'),
        endActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.48,
          children: [
            CustomSlidableAction(
              onPressed: (_) => showCupertinoDialog(
                context: context,
                builder: (_) => CupertinoAlertDialog(
                  title: const Text("Move to Archive?"),
                  content: Text('"${task["task"]}" will be moved to your archive.'),
                  actions: [
                    CupertinoDialogAction(
                      onPressed: () { Navigator.pop(context); onArchive(); },
                      child: const Text("Archive"),
                    ),
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFF5B9CF6),
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.archivebox, size: 22),
                  SizedBox(height: 4),
                  Text('Archive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
            CustomSlidableAction(
              onPressed: (_) => showCupertinoDialog(
                context: context,
                builder: (_) => CupertinoAlertDialog(
                  title: const Text("Delete task?"),
                  content: Text('"${task["task"]}"'),
                  actions: [
                    CupertinoDialogAction(
                      isDestructiveAction: true,
                      onPressed: () { Navigator.pop(context); onDelete(); },
                      child: const Text("Delete"),
                    ),
                    CupertinoDialogAction(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ],
                ),
              ),
              backgroundColor: const Color(0xFFFF6B6B),
              foregroundColor: Colors.white,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.delete, size: 22),
                  SizedBox(height: 4),
                  Text('Delete', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onToggle,
          child: Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isDone ? accentColor : Colors.transparent,
                    border: Border.all(
                      color: isDone ? accentColor : (isDark ? Colors.grey.shade600 : Colors.grey.shade300),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: isDone
                      ? const Icon(CupertinoIcons.checkmark, size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task["task"],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: isDone ? (isDark ? Colors.grey.shade600 : Colors.grey.shade400) : textColor,
                          decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                          decorationColor: isDark ? Colors.grey.shade600 : Colors.grey.shade400,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle,
                          style: TextStyle(fontSize: 12, color: accentColor.withValues(alpha: 0.85)),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Add Task Bottom Sheet ──────────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final Color accentColor, cardColor, textColor, subtextColor;
  final bool isDark;
  final void Function(String task, DateTime? date, TimeOfDay? time) onSave;

  const _AddTaskSheet({
    required this.accentColor,
    required this.cardColor,
    required this.textColor,
    required this.subtextColor,
    required this.isDark,
    required this.onSave,
  });

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _ctrl = TextEditingController();
  DateTime? _date;
  TimeOfDay? _time;

  // Helper: build picker popup with proper text styling
  Widget _pickerShell({required Widget child}) {
    return CupertinoTheme(
      data: CupertinoThemeData(
        brightness: widget.isDark ? Brightness.dark : Brightness.light,
        textTheme: CupertinoTextThemeData(
          dateTimePickerTextStyle: TextStyle(
            fontSize: 20,
            color: widget.isDark ? CupertinoColors.white : const Color(0xFF1A1A2E),
          ),
          pickerTextStyle: TextStyle(
            fontSize: 20,
            color: widget.isDark ? CupertinoColors.white : const Color(0xFF1A1A2E),
          ),
        ),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontSize: 16,
          color: widget.isDark ? CupertinoColors.white : const Color(0xFF1A1A2E),
          decoration: TextDecoration.none,
        ),
        child: Container(
          height: 320,
          color: widget.isDark ? const Color(0xFF2C2C2E) : CupertinoColors.systemBackground,
          child: child,
        ),
      ),
    );
  }

  void _pickDate() {
    final today = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
    final minDate = DateTime(today.year - 1, today.month, today.day);
    final maxDate = DateTime(today.year + 5, today.month, today.day);
    // Use stored date if valid, else today
    DateTime tempDate = (_date != null && !_date!.isBefore(minDate)) ? _date! : today;

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => _pickerShell(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('Cancel',
                        style: TextStyle(color: widget.isDark ? CupertinoColors.white : CupertinoColors.activeBlue)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: Text('Done',
                        style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      setState(() => _date = tempDate);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.date,
                  initialDateTime: tempDate,
                  minimumDate: minDate,
                  maximumDate: maxDate,
                  onDateTimeChanged: (d) => setModalState(() => tempDate = d),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _pickTime() {
    final now = DateTime.now();
    // Use stored time if set, else current time — no seconds/ms
    final initial = _time != null
        ? DateTime(now.year, now.month, now.day, _time!.hour, _time!.minute)
        : DateTime(now.year, now.month, now.day, now.hour, now.minute);
    TimeOfDay tempTime = TimeOfDay(hour: initial.hour, minute: initial.minute);

    showCupertinoModalPopup(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => _pickerShell(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CupertinoButton(
                    child: Text('Cancel',
                        style: TextStyle(color: widget.isDark ? CupertinoColors.white : CupertinoColors.activeBlue)),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                  CupertinoButton(
                    child: Text('Done',
                        style: TextStyle(color: widget.accentColor, fontWeight: FontWeight.w600)),
                    onPressed: () {
                      setState(() => _time = tempTime);
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initial,
                  onDateTimeChanged: (d) => setModalState(() {
                    tempTime = TimeOfDay(hour: d.hour, minute: d.minute);
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate() {
    if (_date == null) return 'Set Date';
    return DateFormat('EEE, MMM d').format(_date!);
  }

  String _formatTime() {
    if (_time == null) return 'Set Time';
    final h = _time!.hour;
    final m = _time!.minute;
    final ampm = h < 12 ? 'AM' : 'PM';
    final hh = h == 0 ? 12 : (h > 12 ? h - 12 : h);
    final mm = m.toString().padLeft(2, '0');
    return '$hh:$mm $ampm';
  }

  @override
  Widget build(BuildContext context) {
    final bg = widget.isDark ? const Color(0xFF1C1C1E) : const Color(0xFFF5F0EB);

    return DefaultTextStyle(
      style: TextStyle(
        color: widget.textColor,
        fontSize: 15,
        decoration: TextDecoration.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
          top: 12,
          left: 24,
          right: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.grey.shade600 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'New Task',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: widget.textColor,
                decoration: TextDecoration.none,
              ),
            ),
            const SizedBox(height: 16),

            // Task input
            Container(
              decoration: BoxDecoration(
                color: widget.cardColor,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2)),
                ],
              ),
              child: CupertinoTextField(
                controller: _ctrl,
                placeholder: 'What do you need to do?',
                placeholderStyle: TextStyle(color: widget.subtextColor),
                style: TextStyle(color: widget.textColor, fontSize: 16),
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(color: Colors.transparent),
                maxLines: 3,
                minLines: 1,
              ),
            ),

            const SizedBox(height: 12),

            // Date & Time chips
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _date != null ? widget.accentColor.withValues(alpha: 0.12) : widget.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _date != null ? widget.accentColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.calendar, size: 18,
                              color: _date != null ? widget.accentColor : widget.subtextColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatDate(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: _date != null ? widget.accentColor : widget.subtextColor,
                                fontWeight: _date != null ? FontWeight.w600 : FontWeight.normal,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _pickTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: _time != null ? widget.accentColor.withValues(alpha: 0.12) : widget.cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: _time != null ? widget.accentColor : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(CupertinoIcons.clock, size: 18,
                              color: _time != null ? widget.accentColor : widget.subtextColor),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              _formatTime(),
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 14,
                                color: _time != null ? widget.accentColor : widget.subtextColor,
                                fontWeight: _time != null ? FontWeight.w600 : FontWeight.normal,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              child: CupertinoButton(
                padding: const EdgeInsets.symmetric(vertical: 16),
                borderRadius: BorderRadius.circular(16),
                color: widget.accentColor,
                onPressed: () {
                  if (_ctrl.text.trim().isEmpty) {
                    showCupertinoDialog(
                      context: context,
                      builder: (_) => CupertinoAlertDialog(
                        title: const Text("Task Required"),
                        content: const Text("Please enter a task before saving."),
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
                  widget.onSave(_ctrl.text, _date, _time);
                  Navigator.pop(context);
                },
                child: const Text(
                  'Save Task',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}

// ── Toast Widget ──────────────────────────────────────────────────────────────
class _ToastWidget extends StatefulWidget {
  final String message;
  final Color iconColor;
  final IconData icon;
  const _ToastWidget({
    required this.message,
    this.iconColor = const Color(0xFFFFB300),
    this.icon = CupertinoIcons.clock_fill,
  });
  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) _ctrl.reverse();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(_anim),
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(widget.icon, color: widget.iconColor, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.message,
                    style: const TextStyle(color: Colors.white, fontSize: 13, decoration: TextDecoration.none, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── FloatingAddButton (exported for use in Errands) ───────────────────────────
class FloatingAddButton extends StatelessWidget {
  final Color color;
  final VoidCallback onPressed;

  const FloatingAddButton({super.key, required this.color, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.4),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(CupertinoIcons.add, color: Colors.white, size: 28),
      ),
    );
  }
}