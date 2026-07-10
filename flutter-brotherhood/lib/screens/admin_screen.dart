import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';

class AdminScreen extends StatelessWidget {
  const AdminScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('⚙️ Admin'),
            actions: [
              IconButton(
                icon: const Icon(Icons.add_rounded),
                onPressed: () => _showTaskDialog(context, provider),
                tooltip: 'Add Task',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            children: [
              // Info banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.admin_panel_settings_rounded,
                        color: Colors.white70),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Admin controls — changes sync to all members in real time.',
                        style: TextStyle(fontSize: 13, color: Colors.white70),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              const SizedBox(height: 20),

              Text(
                'Daily Tasks (${provider.tasks.length})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 12),

              if (provider.tasks.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      children: [
                        const Text('📋',
                            style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 12),
                        const Text('No tasks yet',
                            style: TextStyle(color: Colors.white54)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () =>
                              _showTaskDialog(context, provider),
                          icon: const Icon(Icons.add),
                          label: const Text('Add Task'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: provider.tasks.length,
                  itemBuilder: (context, i) {
                    final task = provider.tasks[i];
                    return _TaskAdminCard(
                      key: ValueKey(task.id),
                      task: task,
                      onEdit: () =>
                          _showTaskDialog(context, provider, task: task),
                      onDelete: () =>
                          _confirmDelete(context, provider, task),
                    );
                  },
                  onReorder: (oldIndex, newIndex) {
                    if (newIndex > oldIndex) newIndex--;
                    final tasks = List<DailyTask>.from(provider.tasks);
                    final item = tasks.removeAt(oldIndex);
                    tasks.insert(newIndex, item);
                    provider.firebase.reorderTasks(tasks);
                  },
                ),

              const SizedBox(height: 24),

              // Reset to defaults button
              OutlinedButton.icon(
                onPressed: () => _confirmReset(context, provider),
                icon: const Icon(Icons.restore_rounded),
                label: const Text('Reset to Default Tasks'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.orangeAccent,
                  side: const BorderSide(color: Colors.orangeAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ).animate().fadeIn(delay: 400.ms),
            ],
          ),
        );
      },
    );
  }

  void _showTaskDialog(BuildContext context, AppProvider provider,
      {DailyTask? task}) {
    showDialog(
      context: context,
      builder: (_) => _TaskDialog(
        task: task,
        onSave: (newTask) async {
          if (task == null) {
            await provider.addTask(newTask);
          } else {
            await provider.updateTask(newTask);
          }
        },
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppProvider provider, DailyTask task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content: Text(
            'Are you sure you want to delete "${task.title}"?\nThis will affect all members.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.deleteTask(task.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context, AppProvider provider) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reset Tasks'),
        content: const Text(
            'This will replace all tasks with the default Brotherhood tasks. Are you sure?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.firebase.seedDefaultTasks();
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

class _TaskAdminCard extends StatelessWidget {
  const _TaskAdminCard({
    super.key,
    required this.task,
    required this.onEdit,
    required this.onDelete,
  });

  final DailyTask task;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.07),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(task.icon, style: const TextStyle(fontSize: 20)),
          ),
        ),
        title: Text(
          task.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: task.notificationTime != null
            ? Row(
                children: [
                  const Icon(Icons.alarm_rounded,
                      size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(
                    task.notificationTime!,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.white38),
                  ),
                ],
              )
            : const Text(
                'No reminder',
                style: TextStyle(fontSize: 12, color: Colors.white24),
              ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle_rounded,
                color: Colors.white24, size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_rounded,
                  size: 18, color: Colors.white54),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon:
                  const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
              onPressed: onDelete,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({this.task, required this.onSave});

  final DailyTask? task;
  final Future<void> Function(DailyTask) onSave;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _iconCtrl;
  late final TextEditingController _timeCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task?.title ?? '');
    _iconCtrl = TextEditingController(text: widget.task?.icon ?? '✅');
    _timeCtrl =
        TextEditingController(text: widget.task?.notificationTime ?? '');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _iconCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_titleCtrl.text.trim().isEmpty) return;
    setState(() => _saving = true);

    final id = widget.task?.id ??
        _titleCtrl.text.trim().toLowerCase().replaceAll(' ', '_');
    final timeInput = _timeCtrl.text.trim();
    final time = timeInput.isEmpty ? null : timeInput;

    final task = DailyTask(
      id: id,
      title: _titleCtrl.text.trim(),
      icon: _iconCtrl.text.trim().isEmpty ? '✅' : _iconCtrl.text.trim(),
      notificationTime: time,
    );

    await widget.onSave(task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(widget.task == null ? 'Add Task' : 'Edit Task'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              SizedBox(
                width: 72,
                child: TextField(
                  controller: _iconCtrl,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 24),
                  decoration: const InputDecoration(
                    labelText: 'Icon',
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _titleCtrl,
                  decoration: const InputDecoration(labelText: 'Task Name'),
                  textCapitalization: TextCapitalization.words,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _timeCtrl,
            decoration: const InputDecoration(
              labelText: 'Reminder Time (HH:mm, leave empty for none)',
              prefixIcon: Icon(Icons.alarm_rounded),
            ),
            keyboardType: TextInputType.datetime,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.task == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
