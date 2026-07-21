import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_result.dart';

class StorageService {
  static const String _scanResultsBox = 'scan_results';
  static Box<ScanResult>? _scanBox;

  static Future<void> init() async {
    _scanBox = await Hive.openBox<ScanResult>(_scanResultsBox);
  }

  static Future<void> saveScanResult(ScanResult result) async {
    await _scanBox?.put(result.id, result);
  }

  static List<ScanResult> getAllScanResults() {
    return _scanBox?.values.toList() ?? [];
  }

  static ScanResult? getScanResult(String id) {
    return _scanBox?.get(id);
  }

  static Future<void> deleteScanResult(String id) async {
    await _scanBox?.delete(id);
  }

  static Future<void> clearAll() async {
    await _scanBox?.clear();
  }
}
