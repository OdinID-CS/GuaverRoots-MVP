import 'dart:ui';
import 'package:flutter/material.dart';

class LanguageService {
  static final LanguageService _instance = LanguageService._internal();
  factory LanguageService() => _instance;
  LanguageService._internal();

  static const List<Locale> supportedLocales = [
    Locale('en'),
    Locale('tw'),
    Locale('ga'),
    Locale('ew'),
    Locale('ha'),
    Locale('da'),
  ];

  static const Map<String, String> languageNames = {
    'en': 'English',
    'tw': 'Twi',
    'ga': 'Ga',
    'ew': 'Ewe',
    'ha': 'Hausa',
    'da': 'Dagbani',
  };

  Locale _currentLocale = const Locale('en');

  Locale get currentLocale => _currentLocale;

  void changeLanguage(Locale locale) {
    _currentLocale = locale;
  }
}
