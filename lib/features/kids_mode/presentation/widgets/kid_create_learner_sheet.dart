import 'package:flutter/material.dart';
import '../../kids_visual_theme.dart';
import 'kids_playful_button.dart';

class KidCreateLearnerSheet extends StatefulWidget {
  const KidCreateLearnerSheet({
    super.key,
    required this.onCreate,
    required this.existingAvatar,
  });

  final void Function({
    required String name,
    required String pin,
    required String avatar,
    required String educationTrack,
    required int standard,
  }) onCreate;
  final String existingAvatar;

  @override
  State<KidCreateLearnerSheet> createState() => _KidCreateLearnerSheetState();
}

class _KidCreateLearnerSheetState extends State<KidCreateLearnerSheet> {
  final _nameCtrl = TextEditingController();
  final _pinCtrl = TextEditingController();
  late String _avatar;
  String _track = 'primary';
  int? _standard;

  @override
  void initState() {
    super.initState();
    _avatar = widget.existingAvatar;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 48,
                  height: 5,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 24),
              const Text('Create Learner',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: KidsVisualTheme.ink,
                      letterSpacing: -0.5)),
              const SizedBox(height: 24),
              const Text('Pick an avatar',
                  style: TextStyle(
                      fontWeight: FontWeight.w800, color: KidsVisualTheme.ink)),
              const SizedBox(height: 12),
              SizedBox(
                height: 64,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    '🦊',
                    '🐰',
                    '🐯',
                    '🐧',
                    '🐻',
                    '🐸',
                    '🐶',
                    '🐱',
                    '🐼',
                    '🦁',
                    '🐨'
                  ]
                      .map((a) => GestureDetector(
                            onTap: () => setState(() => _avatar = a),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 12),
                              width: 64,
                              decoration: BoxDecoration(
                                color: _avatar == a
                                    ? KidsVisualTheme.trailGreen
                                    : Colors.grey.shade100,
                                shape: BoxShape.circle,
                                border: Border.all(
                                    color: _avatar == a
                                        ? KidsVisualTheme.trailGreen
                                        : Colors.transparent,
                                    width: 2),
                                boxShadow: _avatar == a
                                    ? KidsVisualTheme.chunkyShadow(
                                        KidsVisualTheme.trailGreen,
                                        dy: 3)
                                    : null,
                              ),
                              child: Center(
                                  child: Text(a,
                                      style: const TextStyle(fontSize: 32))),
                            ),
                          ))
                      .toList(),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: 'Child\'s name',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                textCapitalization: TextCapitalization.words,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _track,
                      decoration: InputDecoration(
                        labelText: 'Track',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      items: const [
                        DropdownMenuItem(
                            value: 'primary', child: Text('Primary')),
                        DropdownMenuItem(
                            value: 'ecd', child: Text('ECD (Infant)')),
                      ],
                      onChanged: (v) => setState(() => _track = v ?? 'primary'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _standard ?? 1,
                      decoration: InputDecoration(
                        labelText: 'Standard',
                        filled: true,
                        fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none),
                      ),
                      items: List.generate(
                          8,
                          (i) => DropdownMenuItem(
                              value: i + 1, child: Text('Std ${i + 1}'))),
                      onChanged: (v) => setState(() => _standard = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pinCtrl,
                decoration: InputDecoration(
                  labelText: '4-digit PIN',
                  helperText: 'Your child uses this to sign in',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none),
                ),
                keyboardType: TextInputType.number,
                maxLength: 4,
              ),
              const SizedBox(height: 24),
              KidsPlayfulPrimaryButton(
                label: 'Add Learner',
                onTap: () {
                  if (_nameCtrl.text.trim().isEmpty ||
                      _pinCtrl.text.length != 4) return;
                  widget.onCreate(
                    name: _nameCtrl.text.trim(),
                    pin: _pinCtrl.text,
                    avatar: _avatar,
                    educationTrack: _track,
                    standard: _standard ?? 1,
                  );
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
