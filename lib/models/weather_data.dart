import 'package:hive/hive.dart';

part 'weather_data.g.dart';

@HiveType(typeId: 1)
class WeatherData extends HiveObject {
  @HiveField(0)
  final double temperature; // Celsius
  
  @HiveField(1)
  final double humidity; // Percentage (0-100)
  
  @HiveField(2)
  final double precipitation; // mm
  @HiveField(3)
  final bool isRaining; // Current precipitation > 0
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final String locationName;

  WeatherData({
    required this.temperature,
    required this.humidity,
    required this.precipitation,
    required this.isRaining,
    required this.timestamp,
    required this.locationName,
  });

  WeatherData copyWith({
    double? temperature,
    double? humidity,
    double? precipitation,
    bool? isRaining,
    DateTime? timestamp,
    String? locationName,
  }) {
    return WeatherData(
      temperature: temperature ?? this.temperature,
      humidity: humidity ?? this.humidity,
      precipitation: precipitation ?? this.precipitation,
      isRaining: isRaining ?? this.isRaining,
      timestamp: timestamp ?? this.timestamp,
      locationName: locationName ?? this.locationName,
    );
  }
}
