import 'package:dio/dio.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/weather_data.dart';
import '../core/constants/app_constants.dart';
import '../core/logging/app_logger.dart';

class WeatherService {
  static Box<WeatherData>? _weatherBox;
  static final Dio _dio = Dio();
  static bool _isOnline = true;

  static Future<void> init() async {
    try {
      _weatherBox = await Hive.openBox<WeatherData>('weather_data');
      AppLogger.info('WeatherService initialized', tag: 'WeatherService');
      
      // Initialize connectivity monitoring
      final connectivity = Connectivity();
      connectivity.onConnectivityChanged.listen((result) {
        _isOnline = result != ConnectivityResult.none;
        AppLogger.info('Weather connectivity changed: ${_isOnline ? "Online" : "Offline"}', tag: 'WeatherService');
      });
    } catch (e) {
      AppLogger.error('Failed to initialize WeatherService', error: e, tag: 'WeatherService');
    }
  }

  static Future<WeatherData?> getCurrentWeather() async {
    try {
      // Check if we have cached data less than 1 hour old
      final cached = _weatherBox?.get('current');
      if (cached != null) {
        final age = DateTime.now().difference(cached.timestamp);
        if (age.inMinutes < 60) {
          AppLogger.info('Using cached weather data (age: ${age.inMinutes} minutes)', tag: 'WeatherService');
          return cached;
        }
      }

      // Fetch fresh data if online
      if (_isOnline) {
        return await _fetchWeatherFromAPI();
      } else {
        // Return cached data even if old when offline
        if (cached != null) {
          AppLogger.info('Offline mode: using cached weather data', tag: 'WeatherService');
          return cached;
        }
        return null;
      }
    } catch (e) {
      AppLogger.error('Failed to get current weather', error: e, tag: 'WeatherService');
      // Return cached data as fallback
      return _weatherBox?.get('current');
    }
  }

  static Future<WeatherData?> _fetchWeatherFromAPI() async {
    try {
      // Get current location
      final position = await _getCurrentLocation();
      if (position == null) {
        AppLogger.warning('Unable to get current location', tag: 'WeatherService');
        return null;
      }

      // Fetch weather from Open-Meteo API (no API key required)
      final url = 'https://api.open-meteo.com/v1/forecast';
      final params = {
        'latitude': position.latitude,
        'longitude': position.longitude,
        'current': 'temperature_2m,relative_humidity_2m,precipitation',
        'timezone': 'auto',
      };

      final response = await _dio.get(url, queryParameters: params);
      
      if (response.statusCode == 200 && response.data != null) {
        final current = response.data['current'];
        final weatherData = WeatherData(
          temperature: (current['temperature_2m'] as num).toDouble(),
          humidity: (current['relative_humidity_2m'] as num).toDouble(),
          precipitation: (current['precipitation'] as num).toDouble(),
          isRaining: (current['precipitation'] as num) > 0,
          timestamp: DateTime.now(),
          locationName: 'Current Location',
        );

        // Cache the data
        await _weatherBox?.put('current', weatherData);
        AppLogger.info('Weather data fetched and cached', tag: 'WeatherService');
        
        return weatherData;
      }
      
      return null;
    } catch (e) {
      AppLogger.error('Failed to fetch weather from API', error: e, tag: 'WeatherService');
      return null;
    }
  }

  static Future<Position?> _getCurrentLocation() async {
    try {
      // Check location permissions
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        AppLogger.warning('Location services are disabled', tag: 'WeatherService');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          AppLogger.warning('Location permissions are denied', tag: 'WeatherService');
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        AppLogger.warning('Location permissions are permanently denied', tag: 'WeatherService');
        return null;
      }

      // Get current position
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
    } catch (e) {
      AppLogger.error('Failed to get current location', error: e, tag: 'WeatherService');
      return null;
    }
  }

  static DiseaseRisk calculateDiseaseRisk(WeatherData weather) {
    // Rule-based disease risk calculator
    // High humidity + recent/expected rain + moderate temperature → elevated fungal disease risk
    
    final humidity = weather.humidity;
    final isRaining = weather.isRaining;
    final temperature = weather.temperature;
    
    // Risk factors
    final highHumidity = humidity > 70; // High humidity favors fungal growth
    final moderateTemp = temperature >= 15 && temperature <= 30; // Optimal temp for fungal diseases
    final wetConditions = isRaining || weather.precipitation > 0;
    
    if (highHumidity && wetConditions && moderateTemp) {
      return DiseaseRisk.high;
    } else if ((highHumidity && moderateTemp) || (wetConditions && moderateTemp)) {
      return DiseaseRisk.moderate;
    } else if (highHumidity || wetConditions) {
      return DiseaseRisk.moderate;
    } else {
      return DiseaseRisk.low;
    }
  }

  static String getRiskReason(DiseaseRisk risk, WeatherData weather) {
    switch (risk) {
      case DiseaseRisk.high:
        return 'High humidity (${weather.humidity.toInt()}%) and rain create ideal conditions for fungal diseases';
      case DiseaseRisk.moderate:
        if (weather.humidity > 70) {
          return 'Elevated humidity (${weather.humidity.toInt()}%) may promote disease growth';
        } else if (weather.isRaining) {
          return 'Recent rain increases disease risk';
        } else {
          return 'Moderate conditions - monitor crops closely';
        }
      case DiseaseRisk.low:
        return 'Current conditions are not favorable for disease spread';
    }
  }
}

enum DiseaseRisk {
  low,
  moderate,
  high,
}
