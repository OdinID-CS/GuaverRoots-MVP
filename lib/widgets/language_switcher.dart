import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/language_service.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context, listen: false);
    final currentLocale = languageService.currentLocale;
    final currentLangCode = currentLocale.languageCode;

    return PopupMenuButton<String>(
      icon: const Icon(Icons.language, color: Colors.white),
      onSelected: (String langCode) {
        languageService.changeLanguage(Locale(langCode));
        (context as Element).markNeedsBuild();
      },
      itemBuilder: (BuildContext context) {
        return LanguageService.supportedLocales.map((Locale locale) {
          final langName = LanguageService.languageNames[locale.languageCode] ?? locale.languageCode;
          final isSelected = locale.languageCode == currentLangCode;
          return PopupMenuItem<String>(
            value: locale.languageCode,
            child: Row(
              children: [
                if (isSelected)
                  const Icon(Icons.check, color: Colors.green, size: 20)
                else
                  const Icon(Icons.circle_outlined, color: Colors.grey, size: 20),
                const SizedBox(width: 12),
                Text(
                  langName,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                  ),
                ),
              ],
            ),
          );
        }).toList();
      },
    );
  }
}
