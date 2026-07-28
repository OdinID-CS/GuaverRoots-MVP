import 'package:hive_flutter/hive_flutter.dart';
import '../core/logging/app_logger.dart';
import '../models/scan_result.dart';

class FeedbackEntry {
  final String id;
  final String scanResultId;
  final bool isCorrect;
  final String? correctDisease;
  final String? userNotes;
  final DateTime timestamp;

  FeedbackEntry({
    required this.id,
    required this.scanResultId,
    required this.isCorrect,
    this.correctDisease,
    this.userNotes,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'scan_result_id': scanResultId,
    'is_correct': isCorrect,
    'correct_disease': correctDisease,
    'user_notes': userNotes,
    'timestamp': timestamp.toIso8601String(),
  };

  factory FeedbackEntry.fromJson(Map<String, dynamic> json) => FeedbackEntry(
    id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
    scanResultId: json['scan_result_id'] ?? '',
    isCorrect: json['is_correct'] ?? true,
    correctDisease: json['correct_disease'],
    userNotes: json['user_notes'],
    timestamp: DateTime.parse(json['timestamp'] ?? DateTime.now().toIso8601String()),
  );
}

class FarmProfile {
  final String location;
  final int totalScans;
  final int correctPredictions;
  final int incorrectPredictions;
  final Map<String, int> diseaseCounts;
  final Map<String, double> confidenceByDisease;

  FarmProfile({
    required this.location,
    required this.totalScans,
    required this.correctPredictions,
    required this.incorrectPredictions,
    required this.diseaseCounts,
    required this.confidenceByDisease,
  });

  double get accuracy => totalScans > 0 ? correctPredictions / totalScans : 0.0;
}

class FeedbackService {
  static const String _boxName = 'feedback_box';

  static Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox(_boxName);
    }
    AppLogger.info('FeedbackService initialized');
  }

  static Box _box() => Hive.box(_boxName);

  static Future<void> submitFeedback({
    required String scanResultId,
    required bool isCorrect,
    String? correctDisease,
    String? userNotes,
  }) async {
    final entry = FeedbackEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      scanResultId: scanResultId,
      isCorrect: isCorrect,
      correctDisease: correctDisease,
      userNotes: userNotes,
      timestamp: DateTime.now(),
    );

    await _box().put(entry.id, entry.toJson());
    AppLogger.info('Feedback submitted for scan $scanResultId: $isCorrect');
  }

  static List<FeedbackEntry> getAllFeedback() {
    final entries = <FeedbackEntry>[];
    for (final value in _box().values) {
      if (value is Map) {
        entries.add(FeedbackEntry.fromJson(Map<String, dynamic>.from(value)));
      }
    }
    entries.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return entries;
  }

  static FarmProfile buildFarmProfile(String location, List<ScanResult> scans) {
    final diseaseCounts = <String, int>{};
    final confidenceByDisease = <String, List<double>>{};
    int correct = 0;
    int incorrect = 0;

    final feedback = getAllFeedback();
    final feedbackByScan = {for (final f in feedback) f.scanResultId: f};

    for (final scan in scans) {
      if (scan.location != location) continue;
      final disease = scan.diseaseName ?? 'Unknown';
      diseaseCounts[disease] = (diseaseCounts[disease] ?? 0) + 1;

      if (scan.confidence != null) {
        confidenceByDisease.putIfAbsent(disease, () => []).add(scan.confidence!);
      }

      final fb = feedbackByScan[scan.id];
      if (fb != null) {
        if (fb.isCorrect) {
          correct++;
        } else {
          incorrect++;
        }
      }
    }

    final avgConfidence = <String, double>{};
    for (final entry in confidenceByDisease.entries) {
      final values = entry.value;
      avgConfidence[entry.key] = values.isNotEmpty ? values.reduce((a, b) => a + b) / values.length : 0.0;
    }

    return FarmProfile(
      location: location,
      totalScans: scans.length,
      correctPredictions: correct,
      incorrectPredictions: incorrect,
      diseaseCounts: diseaseCounts,
      confidenceByDisease: avgConfidence,
    );
  }

  static Future<void> clearAll() async {
    await _box().clear();
    AppLogger.info('All feedback cleared');
  }
}
