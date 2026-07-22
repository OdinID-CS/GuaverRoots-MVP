import 'package:hive/hive.dart';

part 'scan_result.g.dart';

@HiveType(typeId: 0)
class ScanResult extends HiveObject {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String imagePath;
  
  @HiveField(2)
  final DateTime timestamp;
  
  @HiveField(3)
  final String? diseaseName;
  
  @HiveField(4)
  final double? confidence;
  
  @HiveField(5)
  final String? severity;
  
  @HiveField(6)
  final String? treatment;
  
  @HiveField(7)
  final String? urgency;
  
  @HiveField(8)
  final bool isAreaScan;
  
  @HiveField(9)
  final List<String>? areaScanImages;
  
  @HiveField(10)
  final String? notes;
  
  @HiveField(11)
  final String? description;

  ScanResult({
    required this.id,
    required this.imagePath,
    required this.timestamp,
    this.diseaseName,
    this.confidence,
    this.severity,
    this.treatment,
    this.urgency,
    this.isAreaScan = false,
    this.areaScanImages,
    this.notes,
    this.description,
  });

  ScanResult copyWith({
    String? id,
    String? imagePath,
    DateTime? timestamp,
    String? diseaseName,
    double? confidence,
    String? severity,
    String? treatment,
    String? urgency,
    bool? isAreaScan,
    List<String>? areaScanImages,
    String? notes,
    String? description,
  }) {
    return ScanResult(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      timestamp: timestamp ?? this.timestamp,
      diseaseName: diseaseName ?? this.diseaseName,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      treatment: treatment ?? this.treatment,
      urgency: urgency ?? this.urgency,
      isAreaScan: isAreaScan ?? this.isAreaScan,
      areaScanImages: areaScanImages ?? this.areaScanImages,
      notes: notes ?? this.notes,
      description: description ?? this.description,
    );
  }

  factory ScanResult.fromJson(Map<String, dynamic> json) {
    return ScanResult(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: json['image_path'] ?? '',
      timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
      diseaseName: json['disease_name'],
      confidence: json['confidence']?.toDouble(),
      severity: json['severity'],
      treatment: json['treatment'],
      urgency: json['urgency'],
      isAreaScan: json['is_area_scan'] ?? false,
      areaScanImages: json['area_scan_images'] != null 
          ? List<String>.from(json['area_scan_images']) 
          : null,
      notes: json['notes'],
      description: json['description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'image_path': imagePath,
      'timestamp': timestamp.toIso8601String(),
      'disease_name': diseaseName,
      'confidence': confidence,
      'severity': severity,
      'treatment': treatment,
      'urgency': urgency,
      'is_area_scan': isAreaScan,
      'area_scan_images': areaScanImages,
      'notes': notes,
      'description': description,
    };
  }
}
