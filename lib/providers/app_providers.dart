import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import '../models/scan_result.dart';

class HistoryProvider extends ChangeNotifier {
  List<ScanResult> _scanHistory = [];

  List<ScanResult> get scanHistory => _scanHistory;

  HistoryProvider() {
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _scanHistory = StorageService.getAllScanResults();
    // Sort by timestamp descending
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
