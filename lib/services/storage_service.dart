import 'package:hive_flutter/hive_flutter.dart';
import '../models/scan_result.dart';
import '../core/exceptions/app_exceptions.dart';
import '../core/logging/app_logger.dart';
import '../core/constants/app_constants.dart';

class StorageService {
  static Box<ScanResult>? _scanBox;

  static Future<void> init() async {
    try {
      _scanBox = await Hive.openBox<ScanResult>(AppConstants.scanResultsBox);
      AppLogger.info('StorageService initialized', tag: 'StorageService');
    } catch (e) {
      AppLogger.error('Failed to initialize StorageService', error: e, tag: 'StorageService');
      throw StorageException('Failed to initialize storage: $e', originalError: e);
    }
  }

  static Future<void> saveScanResult(ScanResult result) async {
    try {
      await _scanBox?.put(result.id, result);
      AppLogger.storage('Save', result.id, success: true);
    } catch (e) {
      AppLogger.storage('Save', result.id, success: false);
      AppLogger.error('Failed to save scan result', error: e, tag: 'StorageService');
      throw StorageException('Failed to save scan result: $e', originalError: e);
    }
  }

  static List<ScanResult> getAllScanResults() {
    try {
      final results = _scanBox?.values.toList() ?? [];
      AppLogger.debug('Retrieved ${results.length} scan results', tag: 'StorageService');
      return results;
    } catch (e) {
      AppLogger.error('Failed to get all scan results', error: e, tag: 'StorageService');
      throw StorageException('Failed to get scan results: $e', originalError: e);
    }
  }

  static ScanResult? getScanResult(String id) {
    try {
      final result = _scanBox?.get(id);
      AppLogger.storage('Get', id, success: result != null);
      return result;
    } catch (e) {
      AppLogger.error('Failed to get scan result', error: e, tag: 'StorageService');
      throw StorageException('Failed to get scan result: $e', originalError: e);
    }
  }

  static Future<void> deleteScanResult(String id) async {
    try {
      await _scanBox?.delete(id);
      AppLogger.storage('Delete', id, success: true);
    } catch (e) {
      AppLogger.storage('Delete', id, success: false);
      AppLogger.error('Failed to delete scan result', error: e, tag: 'StorageService');
      throw StorageException('Failed to delete scan result: $e', originalError: e);
    }
  }

  static Future<void> clearAll() async {
    try {
      await _scanBox?.clear();
      AppLogger.storage('Clear All', 'all', success: true);
    } catch (e) {
      AppLogger.storage('Clear All', 'all', success: false);
      AppLogger.error('Failed to clear all scan results', error: e, tag: 'StorageService');
      throw StorageException('Failed to clear all: $e', originalError: e);
    }
  }
}
