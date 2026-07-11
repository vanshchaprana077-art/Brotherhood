import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/app_provider.dart';
import '../models/profile.dart';

/// Shown once, the first time a member opens the app after selecting their
/// identity. Saved permanently to Firestore (`profiles/<memberId>`).
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _heightCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _bodyFatCtrl = TextEditingController();
  final _ageCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _heightCtrl.dispose();
    _weightCtrl.dispose();
    _goalCtrl.dispose();
    _bodyFatCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final provider = context.read<AppProvider>();
    final member = provider.currentMember!;

    final profile = MemberProfile(
      memberId: member.id,
      heightCm: double.parse(_heightCtrl.text.trim()),
      weightKg: double.parse(_weightCtrl.text.trim()),
      goal: _goalCtrl.text.trim(),
      bodyFatPercent: _bodyFatCtrl.text.trim().isEmpty
          ? null
          : double.tryParse(_bodyFatCtrl.text.trim()),
      age: int.parse(_ageCtrl.text.trim()),
    );

    await provider.saveProfile(profile);
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final member = context.watch<AppProvider>().currentMember;

    return Scaffold(
      appBar: AppBar(title: const Text('Set Up Your Profile')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Welcome, ${member?.name ?? ''} 👋',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ).animate().fadeIn(),
              const SizedBox(height: 6),
              const Text(
                'Tell us a bit about yourself. This is saved permanently and helps track your progress.',
                style: TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 28),
              _field(_heightCtrl, 'Height (cm)', Icons.height_rounded,
                  keyboardType: TextInputType.number, required: true),
              const SizedBox(height: 16),
              _field(_weightCtrl, 'Weight (kg)', Icons.monitor_weight_outlined,
                  keyboardType: TextInputType.number, required: true),
              const SizedBox(height: 16),
              _field(_ageCtrl, 'Age', Icons.cake_outlined,
                  keyboardType: TextInputType.number, required: true),
              const SizedBox(height: 16),
              _field(_bodyFatCtrl, 'Body Fat % (optional)', Icons.percent_rounded,
                  keyboardType: TextInputType.number, required: false),
              const SizedBox(height: 16),
              _field(_goalCtrl, 'Your Goal', Icons.flag_rounded,
                  keyboardType: TextInputType.text, required: true, maxLines: 2),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save & Continue'),
                ),
              ).animate().fadeIn(delay: 300.ms),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
    bool required = true,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (v) {
        if (!required) return null;
        if (v == null || v.trim().isEmpty) return 'Required';
        if (keyboardType == TextInputType.number &&
            double.tryParse(v.trim()) == null) {
          return 'Enter a number';
        }
        return null;
      },
    );
  }
}
