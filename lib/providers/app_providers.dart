import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/scan_result.dart';

class HistoryProvider extends ChangeNotifier {
  List<ScanResult> _scanHistory = [];

  List<ScanResult> get scanHistory => _scanHistory;

  int get totalScans => _scanHistory.length;
  int get areaScans => _scanHistory.where((s) => s.isAreaScan).length;
  int get singleScans => _scanHistory.where((s) => !s.isAreaScan).length;

  int get healthyScans => _scanHistory.where((s) => (s.diseaseName?.toLowerCase() ?? '').contains('healthy')).length;
  int get diseasedScans => _scanHistory.where((s) => !(s.diseaseName?.toLowerCase() ?? '').contains('healthy')).length;

  ScanResult? get mostRecentScan => _scanHistory.isEmpty ? null : _scanHistory.first;

  double get averageConfidence {
    if (_scanHistory.isEmpty) return 0.0;
    final confidences = _scanHistory.map((s) => s.confidence ?? 0.0).toList();
    return confidences.reduce((a, b) => a + b) / confidences.length;
  }

  String? get mostCommonDisease {
    if (_scanHistory.isEmpty) return null;
    final diseases = _scanHistory
        .where((s) => s.diseaseName != null)
        .map((s) => s.diseaseName!)
        .toList();
    if (diseases.isEmpty) return null;
    
    final map = <String, int>{};
    for (final d in diseases) {
      map[d] = (map[d] ?? 0) + 1;
    }
    return map.entries.reduce((a, b) => a.value > b.value ? a : b).key;
  }

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _scanHistory = StorageService.getAllScanResults();
    _scanHistory.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    notifyListeners();
  }

  Future<void> refreshHistory() async {
    await _loadHistory();
  }

  Future<void> deleteScan(String id) async {
    await StorageService.deleteScanResult(id);
    await _loadHistory();
  }

  Future<void> clearAll() async {
    await StorageService.clearAll();
    await _loadHistory();
  }
}
