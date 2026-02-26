import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:intl/intl.dart';

class Archive extends StatefulWidget {
  const Archive({super.key});

  @override
  State<Archive> createState() => _ArchiveState();
}

class _ArchiveState extends State<Archive> {
  final box = Hive.box("database");
  List<dynamic> archive = [];

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

  @override
  void initState() {
    super.initState();
    archive = List<dynamic>.from(box.get("archive", defaultValue: []));
  }

  void _restoreTask(int index) {
    final restoredItem = archive[index];
    final updatedTodo = List<dynamic>.from(box.get("todo", defaultValue: []));
    setState(() => archive.removeAt(index));
    updatedTodo.add(restoredItem);
    box.put("todo", updatedTodo);
    box.put("archive", archive);
  }

  void _deleteForever(int index) {
    setState(() {
      archive.removeAt(index);
      box.put("archive", archive);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: box.listenable(),
      builder: (context, box, _) {
        archive = List<dynamic>.from(box.get("archive", defaultValue: []));
        return CupertinoPageScaffold(
          backgroundColor: _bgColor,
          navigationBar: CupertinoNavigationBar(
            middle: Text('Archive', style: TextStyle(color: _textColor)),
            backgroundColor: _bgColor.withValues(alpha: 0.95),
            border: Border(bottom: BorderSide(color: _isDarkMode ? Colors.white12 : Colors.black12, width: 0.5)),
          ),
          child: SafeArea(
            child: archive.isEmpty
                ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.archivebox, size: 60, color: _subtextColor.withValues(alpha: 0.35)),
                  const SizedBox(height: 14),
                  Text('Nothing archived yet', style: TextStyle(fontSize: 17, color: _subtextColor)),
                  const SizedBox(height: 6),
                  Text('Swipe left on a task to archive it', style: TextStyle(fontSize: 13, color: _subtextColor.withValues(alpha: 0.7))),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              itemCount: archive.length,
              itemBuilder: (context, index) {
                final item = archive[index];
                final isDone = item["isDone"] == true;
                final dateStr = item["date"] ?? '';
                final timeStr = item["time"] ?? '';

                String subtitle = '';
                if (dateStr.isNotEmpty) {
                  try {
                    final d = DateFormat('yyyy-MM-dd').parse(dateStr);
                    subtitle = DateFormat('MMM d, yyyy').format(d);
                  } catch (_) {}
                }
                if (timeStr.isNotEmpty) {
                  try {
                    final parts = timeStr.split(':');
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
                    key: ValueKey('arch_${item["task"]}_$index'),
                    endActionPane: ActionPane(
                      motion: const BehindMotion(),
                      extentRatio: 0.52,
                      children: [
                        CustomSlidableAction(
                          onPressed: (_) => _restoreTask(index),
                          backgroundColor: const Color(0xFF4CAF50),
                          foregroundColor: Colors.white,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(16),
                            bottomLeft: Radius.circular(16),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(CupertinoIcons.arrow_uturn_left, size: 22),
                              SizedBox(height: 4),
                              Text('Restore', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                        CustomSlidableAction(
                          onPressed: (_) => showCupertinoDialog(
                            context: context,
                            builder: (_) => CupertinoAlertDialog(
                              title: const Text("Delete permanently?"),
                              content: Text('"${item["task"]}"'),
                              actions: [
                                CupertinoDialogAction(
                                  isDestructiveAction: true,
                                  onPressed: () { Navigator.pop(context); _deleteForever(index); },
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
                      onTap: () {
                        setState(() {
                          archive[index]["isDone"] = !archive[index]["isDone"];
                          box.put("archive", archive);
                        });
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: _cardColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: _isDarkMode ? 0.2 : 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: isDone ? _accentColor.withValues(alpha: 0.5) : Colors.transparent,
                                border: Border.all(
                                  color: isDone ? _accentColor.withValues(alpha: 0.5) : (_isDarkMode ? Colors.grey.shade600 : Colors.grey.shade300),
                                  width: 2,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: isDone
                                  ? Icon(CupertinoIcons.checkmark, size: 14, color: Colors.white.withValues(alpha: 0.7))
                                  : null,
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item["task"],
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                      color: _subtextColor,
                                      decoration: isDone ? TextDecoration.lineThrough : TextDecoration.none,
                                    ),
                                  ),
                                  if (subtitle.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(subtitle, style: TextStyle(fontSize: 12, color: _accentColor.withValues(alpha: 0.6))),
                                  ],
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _subtextColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('Archived', style: TextStyle(fontSize: 10, color: _subtextColor, fontWeight: FontWeight.w500)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      }, // end ValueListenableBuilder builder
    );   // end ValueListenableBuilder
  }
}