import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../models/scan_result.dart';
import '../services/feedback_service.dart';
import '../l10n/app_localizations.dart';

class FeedbackDialog extends StatefulWidget {
  final ScanResult scanResult;

  const FeedbackDialog({super.key, required this.scanResult});

  @override
  State<FeedbackDialog> createState() => _FeedbackDialogState();
}

class _FeedbackDialogState extends State<FeedbackDialog> {
  bool? _isCorrect;
  final TextEditingController _notesController = TextEditingController();
  bool _submitted = false;

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return const SizedBox.shrink();

    if (_submitted) {
      return AlertDialog(
        title: Text(loc.get('feedback_thanks')),
        content: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(loc.get('feedback_submit')),
          ),
        ],
      );
    }

    return AlertDialog(
      title: Text(loc.get('feedback_title')),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _FeedbackOption(
                  label: loc.get('feedback_correct'),
                  icon: Icons.thumb_up,
                  selected: _isCorrect == true,
                  onTap: () => setState(() => _isCorrect = true),
                ),
                _FeedbackOption(
                  label: loc.get('feedback_incorrect'),
                  icon: Icons.thumb_down,
                  selected: _isCorrect == false,
                  onTap: () => setState(() => _isCorrect = false),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: loc.get('feedback_notes'),
                border: const OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(loc.get('remove')),
        ),
        ElevatedButton(
          onPressed: _isCorrect == null
              ? null
              : () async {
                  await FeedbackService.submitFeedback(
                    scanResultId: widget.scanResult.id,
                    isCorrect: _isCorrect!,
                    correctDisease: _isCorrect == false ? widget.scanResult.diseaseName : null,
                    userNotes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
                  );
                  if (mounted) {
                    setState(() => _submitted = true);
                  }
                },
          child: Text(loc.get('feedback_submit')),
        ),
      ],
    );
  }
}

class _FeedbackOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _FeedbackOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Color(AppColors.forestGreen).withValues(alpha: 0.1) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? Color(AppColors.forestGreen) : Colors.grey[300]!,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: selected ? Color(AppColors.forestGreen) : Colors.grey,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
                color: selected ? Color(AppColors.forestGreen) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
