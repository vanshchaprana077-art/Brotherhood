import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/progress_photo.dart';

class WeeklyProgressScreen extends StatefulWidget {
  const WeeklyProgressScreen({super.key});

  @override
  State<WeeklyProgressScreen> createState() => _WeeklyProgressScreenState();
}

class _WeeklyProgressScreenState extends State<WeeklyProgressScreen> {
  WeeklyProgressPhotos? _photos;
  bool _loading = true;
  final Map<ProgressPhotoType, bool> _uploading = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<AppProvider>();
    final member = provider.currentMember;
    if (member == null) return;

    final week = provider.currentWeekNumber;
    final photos = await provider.firebase
        .fetchProgressWeek(member.id, week)
        .catchError((_) => null);
    if (mounted) setState(() { _photos = photos; _loading = false; });
  }

  Future<void> _pick(ProgressPhotoType type) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (file == null || !mounted) return;

    setState(() => _uploading[type] = true);

    try {
      final provider = context.read<AppProvider>();
      final member = provider.currentMember!;
      final week = provider.currentWeekNumber;

      final url = await provider.firebase.uploadProgressPhoto(
        memberId: member.id,
        weekNumber: week,
        type: type,
        file: File(file.path),
      );

      setState(() {
        _photos = (_photos ??
                WeeklyProgressPhotos(
                    memberId: member.id, weekNumber: week))
            .copyWith(
          frontUrl: type == ProgressPhotoType.front ? url : null,
          sideUrl: type == ProgressPhotoType.side ? url : null,
          backUrl: type == ProgressPhotoType.back ? url : null,
          faceUrl: type == ProgressPhotoType.face ? url : null,
        );
        _uploading[type] = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${type.label} photo uploaded ✓'),
            backgroundColor: Colors.greenAccent.withOpacity(0.8),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploading[type] = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: $e'),
            backgroundColor: Colors.redAccent.withOpacity(0.8),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    final member = provider.currentMember;
    final week = provider.currentWeekNumber;
    final theme = Theme.of(context);
    final color = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('📸 Weekly Progress')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : member == null
              ? const Center(child: Text('Not signed in'))
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  children: [
                    // Week banner
                    Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            color.withOpacity(0.2),
                            color.withOpacity(0.05),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('📅',
                                  style: TextStyle(fontSize: 28)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      week > 0
                                          ? 'Week $week Progress'
                                          : 'Challenge Not Started',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Upload your 4 progress photos',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_photos != null && _photos!.isComplete)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.greenAccent
                                        .withOpacity(0.15),
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: Colors.greenAccent
                                            .withOpacity(0.4)),
                                  ),
                                  child: const Text(
                                    '✓ Complete',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.greenAccent,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (week > 0) ...[
                            const SizedBox(height: 12),
                            _ProgressBar(photos: _photos),
                          ],
                        ],
                      ),
                    ).animate().fadeIn(),

                    const SizedBox(height: 20),

                    const Text(
                      'Photos',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 12),

                    // 2x2 grid of photo slots
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.85,
                      children: ProgressPhotoType.values.map((type) {
                        final url = _urlForType(type);
                        return _PhotoSlot(
                          type: type,
                          url: url,
                          uploading: _uploading[type] ?? false,
                          onTap: week > 0 ? () => _pick(type) : null,
                        )
                            .animate()
                            .fadeIn(
                                delay: (200 +
                                        ProgressPhotoType.values.indexOf(type) *
                                            80)
                                    .ms)
                            .scale(begin: const Offset(0.95, 0.95));
                      }).toList(),
                    ),

                    const SizedBox(height: 20),

                    // Info card
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: Colors.white.withOpacity(0.07)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: Colors.white38),
                          SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Photos are private. Only the admin can view everyone\'s progress.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white38,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
    );
  }

  String? _urlForType(ProgressPhotoType type) {
    if (_photos == null) return null;
    switch (type) {
      case ProgressPhotoType.front:
        return _photos!.frontUrl;
      case ProgressPhotoType.side:
        return _photos!.sideUrl;
      case ProgressPhotoType.back:
        return _photos!.backUrl;
      case ProgressPhotoType.face:
        return _photos!.faceUrl;
    }
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.photos});
  final WeeklyProgressPhotos? photos;

  @override
  Widget build(BuildContext context) {
    final uploaded = photos == null
        ? 0
        : ProgressPhotoType.values.where((t) {
            switch (t) {
              case ProgressPhotoType.front:
                return photos!.frontUrl != null;
              case ProgressPhotoType.side:
                return photos!.sideUrl != null;
              case ProgressPhotoType.back:
                return photos!.backUrl != null;
              case ProgressPhotoType.face:
                return photos!.faceUrl != null;
            }
          }).length;
    final pct = uploaded / 4;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$uploaded/4 uploaded',
              style: const TextStyle(fontSize: 12, color: Colors.white54),
            ),
            Text(
              '${(pct * 100).toStringAsFixed(0)}%',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.white70),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 6,
            backgroundColor: Colors.white.withOpacity(0.1),
            valueColor: AlwaysStoppedAnimation(
              pct >= 1.0 ? Colors.greenAccent : Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}

class _PhotoSlot extends StatelessWidget {
  const _PhotoSlot({
    required this.type,
    required this.url,
    required this.uploading,
    required this.onTap,
  });

  final ProgressPhotoType type;
  final String? url;
  final bool uploading;
  final VoidCallback? onTap;

  static const _icons = {
    ProgressPhotoType.front: Icons.person_outline_rounded,
    ProgressPhotoType.side: Icons.accessibility_new_rounded,
    ProgressPhotoType.back: Icons.flip_rounded,
    ProgressPhotoType.face: Icons.face_outlined,
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasPhoto = url != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: hasPhoto
                ? Colors.greenAccent.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
          image: (hasPhoto && !uploading)
              ? DecorationImage(
                  image: NetworkImage(url!),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: hasPhoto && !uploading
                ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  )
                : null,
          ),
          child: uploading
              ? const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Column(
                  mainAxisAlignment: hasPhoto
                      ? MainAxisAlignment.end
                      : MainAxisAlignment.center,
                  children: [
                    if (!hasPhoto) ...[
                      Icon(
                        _icons[type] ?? Icons.camera_alt_outlined,
                        color: Colors.white24,
                        size: 36,
                      ),
                      const SizedBox(height: 10),
                    ],
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            type.label,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: hasPhoto
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                          Icon(
                            hasPhoto
                                ? Icons.check_circle_rounded
                                : (onTap != null
                                    ? Icons.add_circle_outline_rounded
                                    : Icons.lock_outline_rounded),
                            size: 18,
                            color: hasPhoto
                                ? Colors.greenAccent
                                : (onTap != null
                                    ? theme.colorScheme.primary
                                    : Colors.white24),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
