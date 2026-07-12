import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/task.dart';
import '../models/member.dart';
import '../models/progress_photo.dart';
import '../services/firebase_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('⚙️ Admin Panel'),
            bottom: TabBar(
              controller: _tab,
              indicatorColor: theme.colorScheme.primary,
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: Colors.white38,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: const [
                Tab(text: 'Tasks'),
                Tab(text: 'Profiles'),
                Tab(text: 'Weight History'),
                Tab(text: 'Progress Photos'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tab,
            children: [
              _TasksTab(provider: provider),
              const _ProfilesTab(),
              const _WeightHistoryTab(),
              const _ProgressPhotosTab(),
            ],
          ),
        );
      },
    );
  }
}

// ── Tasks Tab ─────────────────────────────────────────────────────────────────

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.provider});
  final AppProvider provider;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showTaskDialog(context, provider),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Task'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.25),
              ),
            ),
            child: const Row(
              children: [
                Icon(Icons.admin_panel_settings_rounded, color: Colors.white70, size: 18),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Changes sync to all members in real time.',
                    style: TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(),

          const SizedBox(height: 16),

          Text(
            'Daily Tasks (${provider.tasks.length})',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          if (provider.tasks.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('No tasks yet', style: TextStyle(color: Colors.white38)),
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
                  onEdit: () => _showTaskDialog(context, provider, task: task),
                  onDelete: () => _confirmDelete(context, provider, task),
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

          const SizedBox(height: 16),

          OutlinedButton.icon(
            onPressed: () => _confirmReset(context, provider),
            icon: const Icon(Icons.restore_rounded),
            label: const Text('Reset to Default Tasks'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orangeAccent,
              side: const BorderSide(color: Colors.orangeAccent),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  void _showTaskDialog(BuildContext context, AppProvider provider, {DailyTask? task}) {
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

  void _confirmDelete(BuildContext context, AppProvider provider, DailyTask task) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"?\nThis affects all members.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
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
        content: const Text('Replace all tasks with the Brotherhood defaults?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await provider.firebase.seedDefaultTasks();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}

// ── Profiles Tab ──────────────────────────────────────────────────────────────

class _ProfilesTab extends StatefulWidget {
  const _ProfilesTab();

  @override
  State<_ProfilesTab> createState() => _ProfilesTabState();
}

class _ProfilesTabState extends State<_ProfilesTab> {
  List<Map<String, dynamic>>? _profiles;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = FirebaseService();
    final profiles = await service.fetchAllProfiles().catchError((_) => <Map<String, dynamic>>[]);
    if (mounted) setState(() { _profiles = profiles; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final profiles = _profiles ?? [];

    if (profiles.isEmpty) {
      return const Center(
        child: Text('No profiles saved yet', style: TextStyle(color: Colors.white38)),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: profiles.asMap().entries.map((entry) {
        final data = entry.value;
        final memberId = data['memberId'] as String? ?? '';
        final member = Member.fromId(memberId);
        return _ProfileCard(data: data, member: member)
            .animate()
            .fadeIn(delay: (entry.key * 80).ms)
            .slideY(begin: 0.1);
      }).toList(),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.data, required this.member});
  final Map<String, dynamic> data;
  final Member? member;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final height = (data['heightCm'] as num?)?.toDouble() ?? 0;
    final weight = (data['weightKg'] as num?)?.toDouble() ?? 0;
    final age = (data['age'] as num?)?.toInt() ?? 0;
    final goal = data['goal'] as String? ?? '—';
    final bf = (data['bodyFatPercent'] as num?)?.toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(
                  member?.name[0] ?? '?',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                member?.name ?? data['memberId'] as String? ?? '?',
                style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
              if (member?.isAdmin == true) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondary.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Admin',
                    style: TextStyle(fontSize: 10, color: theme.colorScheme.secondary),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(label: 'Age', value: '$age yrs'),
              _StatChip(label: 'Height', value: '${height.toStringAsFixed(0)} cm'),
              _StatChip(label: 'Weight', value: '${weight.toStringAsFixed(1)} kg'),
              if (bf != null) _StatChip(label: 'Body Fat', value: '${bf.toStringAsFixed(1)}%'),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Goal: $goal',
            style: const TextStyle(fontSize: 13, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(fontSize: 10, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Weight History Tab ────────────────────────────────────────────────────────

class _WeightHistoryTab extends StatefulWidget {
  const _WeightHistoryTab();

  @override
  State<_WeightHistoryTab> createState() => _WeightHistoryTabState();
}

class _WeightHistoryTabState extends State<_WeightHistoryTab> {
  Map<String, List<Map<String, dynamic>>>? _history;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = FirebaseService();
    final result = <String, List<Map<String, dynamic>>>{};
    for (final member in Member.all) {
      result[member.id] = await service
          .fetchWeightHistory(member.id)
          .catchError((_) => <Map<String, dynamic>>[]);
    }
    if (mounted) setState(() { _history = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final history = _history ?? {};

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: Member.all.asMap().entries.map((entry) {
        final member = entry.value;
        final logs = history[member.id] ?? [];
        return _WeightCard(member: member, logs: logs)
            .animate()
            .fadeIn(delay: (entry.key * 100).ms);
      }).toList(),
    );
  }
}

class _WeightCard extends StatelessWidget {
  const _WeightCard({required this.member, required this.logs});
  final Member member;
  final List<Map<String, dynamic>> logs;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                child: Text(member.name[0],
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 10),
              Text(member.name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold)),
              const Spacer(),
              Text('${logs.length} logs',
                  style: const TextStyle(fontSize: 12, color: Colors.white38)),
            ],
          ),
          const SizedBox(height: 12),
          if (logs.isEmpty)
            const Text('No weight logs yet',
                style: TextStyle(color: Colors.white38, fontSize: 13))
          else
            ...logs.take(5).map((log) {
              final weight = (log['weightKg'] as num?)?.toDouble() ?? 0;
              final dateRaw = log['date'] as String? ?? '';
              final date = DateTime.tryParse(dateRaw);
              final dateStr = date != null
                  ? '${date.day}/${date.month}/${date.year}'
                  : dateRaw;
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white54)),
                    Text('${weight.toStringAsFixed(1)} kg',
                        style: const TextStyle(
                            fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
              );
            }),
          if (logs.length > 5)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('+${logs.length - 5} more',
                  style:
                      const TextStyle(fontSize: 12, color: Colors.white38)),
            ),
        ],
      ),
    );
  }
}

// ── Progress Photos Tab ────────────────────────────────────────────────────────

class _ProgressPhotosTab extends StatefulWidget {
  const _ProgressPhotosTab();

  @override
  State<_ProgressPhotosTab> createState() => _ProgressPhotosTabState();
}

class _ProgressPhotosTabState extends State<_ProgressPhotosTab> {
  Map<String, List<WeeklyProgressPhotos>>? _allPhotos;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = FirebaseService();
    final result = await service
        .fetchAllProgressPhotos()
        .catchError((_) => <String, List<WeeklyProgressPhotos>>{});
    if (mounted) setState(() { _allPhotos = result; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    final allPhotos = _allPhotos ?? {};
    final hasAny = allPhotos.values.any((list) => list.isNotEmpty);

    if (!hasAny) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('📸', style: TextStyle(fontSize: 48)),
            SizedBox(height: 16),
            Text('No progress photos yet',
                style: TextStyle(color: Colors.white38, fontSize: 15)),
            SizedBox(height: 6),
            Text('Members upload from the Tasks tab → 📸 icon',
                style: TextStyle(color: Colors.white24, fontSize: 12)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
      children: Member.all.map((member) {
        final photos = allPhotos[member.id] ?? [];
        if (photos.isEmpty) return const SizedBox.shrink();
        return _MemberPhotosCard(member: member, photoList: photos);
      }).toList(),
    );
  }
}

class _MemberPhotosCard extends StatefulWidget {
  const _MemberPhotosCard({required this.member, required this.photoList});
  final Member member;
  final List<WeeklyProgressPhotos> photoList;

  @override
  State<_MemberPhotosCard> createState() => _MemberPhotosCardState();
}

class _MemberPhotosCardState extends State<_MemberPhotosCard> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor:
                        theme.colorScheme.primary.withOpacity(0.2),
                    child: Text(widget.member.name[0],
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(widget.member.name,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  Text('${widget.photoList.length} weeks',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white38)),
                  const SizedBox(width: 8),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: Colors.white38,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            child: _expanded
                ? Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    child: Column(
                      children: widget.photoList.map((weekPhotos) {
                        final week = weekPhotos.weekNumber;
                        final urls = <String>[
                          if (weekPhotos.frontUrl != null) weekPhotos.frontUrl!,
                          if (weekPhotos.sideUrl != null) weekPhotos.sideUrl!,
                          if (weekPhotos.backUrl != null) weekPhotos.backUrl!,
                          if (weekPhotos.faceUrl != null) weekPhotos.faceUrl!,
                        ];
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Divider(color: Colors.white.withOpacity(0.06)),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                              child: Text(
                                'Week $week',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            SizedBox(
                              height: 100,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: urls.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (ctx, i) => ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    urls[i],
                                    width: 80,
                                    height: 100,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 80,
                                      color: Colors.white.withOpacity(0.05),
                                      child: const Icon(
                                          Icons.broken_image_outlined,
                                          color: Colors.white24),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Task admin card ───────────────────────────────────────────────────────────

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
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
        title: Text(task.title,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        subtitle: task.notificationTime != null
            ? Row(
                children: [
                  const Icon(Icons.alarm_rounded, size: 12, color: Colors.white38),
                  const SizedBox(width: 4),
                  Text(task.notificationTime!,
                      style: const TextStyle(fontSize: 12, color: Colors.white38)),
                  if (task.appliesTo != null && task.appliesTo!.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text('(${task.appliesTo!.join(', ')})',
                        style: const TextStyle(fontSize: 11, color: Colors.white24)),
                  ],
                ],
              )
            : task.appliesTo != null && task.appliesTo!.isNotEmpty
                ? Text('(${task.appliesTo!.join(', ')})',
                    style: const TextStyle(fontSize: 11, color: Colors.white24))
                : const Text('No reminder',
                    style: TextStyle(fontSize: 12, color: Colors.white24)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.drag_handle_rounded, color: Colors.white24, size: 20),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white54),
              onPressed: onEdit,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete_rounded, size: 18, color: Colors.redAccent),
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

// ── Task dialog ───────────────────────────────────────────────────────────────

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
    _timeCtrl = TextEditingController(text: widget.task?.notificationTime ?? '');
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

    final task = DailyTask(
      id: id,
      title: _titleCtrl.text.trim(),
      icon: _iconCtrl.text.trim().isEmpty ? '✅' : _iconCtrl.text.trim(),
      notificationTime: timeInput.isEmpty ? null : timeInput,
    );

    await widget.onSave(task);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
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
                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 12),
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
              labelText: 'Reminder Time (HH:mm, optional)',
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
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(widget.task == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
