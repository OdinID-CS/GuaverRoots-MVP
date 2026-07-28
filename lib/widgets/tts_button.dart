import 'package:flutter/material.dart';
import '../core/constants/app_constants.dart';
import '../services/tts_service.dart';

class TtsButton extends StatefulWidget {
  final String text;
  final String languageCode;

  const TtsButton({
    super.key,
    required this.text,
    required this.languageCode,
  });

  @override
  State<TtsButton> createState() => _TtsButtonState();
}

class _TtsButtonState extends State<TtsButton> {
  @override
  Widget build(BuildContext context) {
    final ttsService = TtsService();
    final bool isCurrentlyPlaying = ttsService.isSpeaking && ttsService.currentLanguage == widget.languageCode;

    return IconButton(
      icon: Icon(
        isCurrentlyPlaying ? Icons.stop : Icons.volume_up,
        color: Color(AppColors.forestGreen),
      ),
      onPressed: () async {
        if (isCurrentlyPlaying) {
          await ttsService.stop();
        } else {
          await ttsService.speak(widget.text, widget.languageCode);
        }
      },
    );
  }
}
