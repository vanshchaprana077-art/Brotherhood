import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';
import '../models/member.dart';
import '../models/progress_photo.dart';
import '../constants.dart';
import '../services/firebase_service.dart';
import 'weekly_progress_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  List<Map<String, dynamic>> _weightHistory = [];
  List<WeeklyProgressPhotos> _progressPhotos = [];
  bool _loadingExtra = true;

  @override
  void initState() {
    super.initState();
    _loadExtra();
  }

  Future<void> _loadExtra() async {
    final provider = context.read<AppProvider>();
    final memberId = provider.currentMember?.id;
    if (memberId == null) {
      if (mounted) setState(() => _loadingExtra = false);
      return;
    }
    final service = FirebaseService();

    List<Map<String, dynamic>> weights = [];
    List<WeeklyProgressPhotos> photos = [];

    try {
      weights = await service.fetchWeightHistory(memberId);
    } catch (_) {}

    try {
      photos = await service.fetchAllProgressForMember(memberId);
    } catch (_) {}

    if (mounted) {
      setState(() {
        _weightHistory = weights;
        _progressPhotos = photos;
        _loadingExtra = false;
      });
    }
  }

  Future<void> _showEditDialog(BuildContext context, AppProvider provider) async {
    final profile = provider.profile;
    final member = provider.currentMember;
    if (member == null) return;

    await showDialog(
      context: context,
      builder: (_) => _EditProfileDialog(
        profile: profile,
        member: member,
        onSave: (updated) async {
          await provider.updateProfile(updated);
          // Reload weight history after weight update
          _loadExtra();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, _) {
        final member = provider.currentMember;
        if (member == null) return const SizedBox();

        final profile = provider.profile;
        final streak = provider.streaks[member.id];
        final completions = provider.todayCompletions;
        final percent = provider.todaysPercent;
        final score = provider.completedCount(completions);
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_rounded),
                tooltip: 'Edit Profile',
                onPressed: () => _showEditDialog(context, provider),
              ),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () async {
              await provider.refresh();
              await _loadExtra();
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
              children: [
                // ── Header ────────────────────────────────────────────────
                _ProfileHeader(member: member, profile: profile)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideY(begin: -0.1),

                const SizedBox(height: 20),

                // ── Today's stats ─────────────────────────────────────────
                _SectionLabel(label: "Today's Progress"),
                const SizedBox(height: 10),
                _TodayStatsRow(
                  percent: percent,
                  score: score,
                  total: provider.taskCountFor(member.id),
                  theme: theme,
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 20),

                // ── Streak stats ──────────────────────────────────────────
                _SectionLabel(label: 'Streak & Challenge'),
                const SizedBox(height: 10),
                _StreakStatsRow(streak: streak, theme: theme)
                    .animate()
                    .fadeIn(delay: 180.ms),

                const SizedBox(height: 20),

                // ── Challenge info ────────────────────────────────────────
                _ChallengeInfoCard(provider: provider, theme: theme)
                    .animate()
                    .fadeIn(delay: 260.ms),

                const SizedBox(height: 20),

                // ── Body stats (from profile) ─────────────────────────────
                if (profile != null) ...[
                  _SectionLabel(label: 'Body Stats'),
                  const SizedBox(height: 10),
                  _BodyStatsCard(profile: profile, theme: theme)
                      .animate()
                      .fadeIn(delay: 340.ms),
                  const SizedBox(height: 20),
                ],

                // ── Goal ─────────────────────────────────────────────────
                if (profile != null && profile.goal.isNotEmpty) ...[
                  _SectionLabel(label: 'My Goal'),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.18)),
                    ),
                    child: Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 22)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            profile.goal,
                            style: const TextStyle(
                                fontSize: 14, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 380.ms),
                  const SizedBox(height: 20),
                ],

                if (profile == null) ...[
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.orangeAccent.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: Colors.orangeAccent.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 20)),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text(
                            'Profile not set up yet. Tap ✏️ to fill in your details.',
                            style: TextStyle(
                                fontSize: 13, color: Colors.white70),
                          ),
                        ),
                        TextButton(
                          onPressed: () => _showEditDialog(context, provider),
                          child: const Text('Set Up'),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),
                ],

                // ── Weight history ────────────────────────────────────────
                if (!_loadingExtra && _weightHistory.isNotEmpty) ...[
                  _SectionLabel(label: 'Weight History'),
                  const SizedBox(height: 10),
                  _WeightHistoryCard(logs: _weightHistory, theme: theme)
                      .animate()
                      .fadeIn(delay: 400.ms),
                  const SizedBox(height: 20),
                ],

                // ── Progress photos ───────────────────────────────────────
                _SectionLabel(label: 'Progress Photos'),
                const SizedBox(height: 10),
                if (_loadingExtra)
                  const Center(
                      child: Padding(
                          padding: EdgeInsets.all(16),
                          child: CircularProgressIndicator()))
                else if (_progressPhotos.isEmpty)
                  _EmptyPhotosCard(
                    onUpload: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const WeeklyProgressScreen()),
                    ),
                  ).animate().fadeIn(delay: 440.ms)
                else
                  _ProgressPhotosList(photos: _progressPhotos, theme: theme)
                      .animate()
                      .fadeIn(delay: 440.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }
}

// ── Profile header ────────────────────────────────────────────────────────────

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.member, required this.profile});
  final Member member;
  final MemberProfile? profile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.2), theme.colorScheme.secondary.withOpacity(0.07)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Row(
        children: [
          // Avatar circle
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [color, theme.colorScheme.secondary],
              ),
            ),
            child: Center(
              child: Text(
                member.name[0],
                style: const TextStyle(
                    fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: member.isAdmin
                            ? theme.colorScheme.secondary.withOpacity(0.2)
                            : color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        member.isAdmin ? '⚙️ Admin' : '🏋️ Member',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: member.isAdmin
                              ? theme.colorScheme.secondary
                              : color,
                        ),
                      ),
                    ),
                  ],
                ),
                if (profile != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    '${profile!.age} yrs · ${profile!.heightCm.toStringAsFixed(0)} cm · ${profile!.weightKg.toStringAsFixed(1)} kg',
                    style: const TextStyle(
                        fontSize: 12, color: Colors.white54),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Today's stats row ─────────────────────────────────────────────────────────

class _TodayStatsRow extends StatelessWidget {
  const _TodayStatsRow({
    required this.percent,
    required this.score,
    required this.total,
    required this.theme,
  });
  final double percent;
  final int score;
  final int total;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '✅',
            label: 'Completed',
            value: '$score / $total tasks',
            color: Colors.greenAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '📊',
            label: "Today's %",
            value: '${(percent * 100).toStringAsFixed(0)}%',
            color: percent >= 1.0
                ? Colors.greenAccent
                : percent >= 0.5
                    ? Colors.orangeAccent
                    : theme.colorScheme.primary,
          ),
        ),
      ],
    );
  }
}

// ── Streak stats row ──────────────────────────────────────────────────────────

class _StreakStatsRow extends StatelessWidget {
  const _StreakStatsRow({required this.streak, required this.theme});
  final dynamic streak;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final current = streak?.current ?? 0;
    final longest = streak?.longest ?? 0;
    final missed = streak?.missedDays ?? 0;

    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: '🔥',
            label: 'Current Streak',
            value: '$current day${current == 1 ? '' : 's'}',
            color: Colors.deepOrangeAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '🏆',
            label: 'Longest Streak',
            value: '$longest day${longest == 1 ? '' : 's'}',
            color: Colors.amberAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: '❌',
            label: 'Missed Days',
            value: '$missed',
            color: Colors.redAccent,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final String icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
                fontSize: 15, fontWeight: FontWeight.bold, color: color),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Colors.white38),
          ),
        ],
      ),
    );
  }
}

// ── Challenge info ────────────────────────────────────────────────────────────

class _ChallengeInfoCard extends StatelessWidget {
  const _ChallengeInfoCard({required this.provider, required this.theme});
  final AppProvider provider;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final startFmt = DateFormat('d MMM yyyy').format(AppConstants.challengeStart);
    final day = provider.currentDayNumber;
    final remaining = provider.daysRemaining;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          _InfoRow(
            icon: '📅',
            label: 'Challenge Started',
            value: startFmt,
          ),
          const Divider(color: Colors.white12, height: 20),
          _InfoRow(
            icon: '📆',
            label: provider.challengeStarted ? 'Current Day' : 'Starts In',
            value: provider.challengeStarted ? 'Day $day of 100' : '$remaining days',
          ),
          const Divider(color: Colors.white12, height: 20),
          _InfoRow(
            icon: '⏳',
            label: 'Days Remaining',
            value: '$remaining',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final String icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(icon, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(fontSize: 13, color: Colors.white54)),
        const Spacer(),
        Text(value,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

// ── Body stats ────────────────────────────────────────────────────────────────

class _BodyStatsCard extends StatelessWidget {
  const _BodyStatsCard({required this.profile, required this.theme});
  final MemberProfile profile;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _BodyChip(label: 'Age', value: '${profile.age} yrs'),
          _BodyChip(
              label: 'Height',
              value: '${profile.heightCm.toStringAsFixed(0)} cm'),
          _BodyChip(
              label: 'Weight',
              value: '${profile.weightKg.toStringAsFixed(1)} kg'),
          if (profile.bodyFatPercent != null)
            _BodyChip(
                label: 'Body Fat',
                value: '${profile.bodyFatPercent!.toStringAsFixed(1)}%'),
        ],
      ),
    );
  }
}

class _BodyChip extends StatelessWidget {
  const _BodyChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.bold)),
          Text(label,
              style: const TextStyle(fontSize: 11, color: Colors.white38)),
        ],
      ),
    );
  }
}

// ── Weight history ────────────────────────────────────────────────────────────

class _WeightHistoryCard extends StatelessWidget {
  const _WeightHistoryCard({required this.logs, required this.theme});
  final List<Map<String, dynamic>> logs;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: logs.take(8).toList().asMap().entries.map((entry) {
          final i = entry.key;
          final log = entry.value;
          final weight = (log['weightKg'] as num?)?.toDouble() ?? 0;
          final dateRaw = log['date'] as String? ?? '';
          final date = DateTime.tryParse(dateRaw);
          final dateStr = date != null
              ? DateFormat('d MMM yyyy').format(date)
              : dateRaw;

          return Column(
            children: [
              if (i > 0) const Divider(color: Colors.white12, height: 1),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Text('⚖️', style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Text(dateStr,
                        style: const TextStyle(
                            fontSize: 13, color: Colors.white54)),
                    const Spacer(),
                    Text(
                      '${weight.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Progress photos ───────────────────────────────────────────────────────────

class _EmptyPhotosCard extends StatelessWidget {
  const _EmptyPhotosCard({required this.onUpload});
  final VoidCallback onUpload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
      ),
      child: Column(
        children: [
          const Text('📸', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 10),
          const Text('No progress photos yet',
              style: TextStyle(color: Colors.white38, fontSize: 14)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onUpload,
            icon: const Icon(Icons.camera_alt_rounded, size: 16),
            label: const Text('Upload Photos'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressPhotosList extends StatelessWidget {
  const _ProgressPhotosList({required this.photos, required this.theme});
  final List<WeeklyProgressPhotos> photos;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: photos.map((week) {
        final urls = <String>[
          if (week.frontUrl != null) week.frontUrl!,
          if (week.sideUrl != null) week.sideUrl!,
          if (week.backUrl != null) week.backUrl!,
          if (week.faceUrl != null) week.faceUrl!,
        ];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A2E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.07)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Week ${week.weekNumber}',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary),
                ),
              ),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  itemCount: urls.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
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
                        child: const Icon(Icons.broken_image_outlined,
                            color: Colors.white24),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ── Edit profile dialog ───────────────────────────────────────────────────────

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({
    required this.profile,
    required this.member,
    required this.onSave,
  });

  final MemberProfile? profile;
  final Member member;
  final Future<void> Function(MemberProfile) onSave;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _heightCtrl;
  late final TextEditingController _weightCtrl;
  late final TextEditingController _ageCtrl;
  late final TextEditingController _bfCtrl;
  late final TextEditingController _goalCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.profile;
    _heightCtrl = TextEditingController(
        text: p != null ? p.heightCm.toStringAsFixed(0) : '');
    _weightCtrl = TextEditingController(
        text: p != null ? p.weightKg.toStringAsFixed(1) : '');
    _ageCtrl = TextEditingController(
        text: p != null ? p.age.toString() : '');
    _bfCtrl = TextEditingController(
        text: p?.bodyFatPercent?.toStringAsFixed(1) ?? '');
    _goalCtrl = TextEditingController(text: p?.goal ?? '');
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _ageCtrl.dispose();
    _bfCtrl.dispose();
    _goalCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final height = double.tryParse(_heightCtrl.text.trim());
    final weight = double.tryParse(_weightCtrl.text.trim());
    final age = int.tryParse(_ageCtrl.text.trim());

    if (height == null || weight == null || age == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in Height, Weight, and Age')),
      );
      return;
    }

    setState(() => _saving = true);
    final updated = MemberProfile(
      memberId: widget.member.id,
      heightCm: height,
      weightKg: weight,
      age: age,
      bodyFatPercent: double.tryParse(_bfCtrl.text.trim()),
      goal: _goalCtrl.text.trim(),
    );
    await widget.onSave(updated);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text('Edit Profile — ${widget.member.name}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _field(_heightCtrl, 'Height (cm)', TextInputType.number),
            const SizedBox(height: 12),
            _field(_weightCtrl, 'Weight (kg)', TextInputType.number),
            const SizedBox(height: 12),
            _field(_ageCtrl, 'Age', TextInputType.number),
            const SizedBox(height: 12),
            _field(_bfCtrl, 'Body Fat % (optional)', TextInputType.number),
            const SizedBox(height: 12),
            _field(_goalCtrl, 'Your Goal', TextInputType.text, maxLines: 2),
          ],
        ),
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
              : const Text('Save'),
        ),
      ],
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    TextInputType type, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label),
    );
  }
}
