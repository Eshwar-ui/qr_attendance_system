import 'dart:convert';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:logger/logger.dart';

class OfflineService {
  static final OfflineService _instance = OfflineService._internal();
  factory OfflineService() => _instance;
  OfflineService._internal();

  late Box _attendanceBox;
  late Box _classesBox;
  late Box _syncBox;
  final Logger _logger = Logger();
  
  bool _isOnline = true;
  bool get isOnline => _isOnline;

  Future<void> initialize() async {
    await Hive.initFlutter();
    
    _attendanceBox = await Hive.openBox('offline_attendance');
    _classesBox = await Hive.openBox('cached_classes');
    _syncBox = await Hive.openBox('pending_sync');
    
    // Monitor connectivity
    Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> result) {
      _isOnline = result != ConnectivityResult.none;
      if (_isOnline) {
        _syncPendingData();
      }
    });

    // Check initial connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    _isOnline = connectivityResult != ConnectivityResult.none;
  }

  // Cache attendance data for offline access
  Future<void> cacheAttendanceData(String studentId, Map<String, dynamic> data) async {
    await _attendanceBox.put(studentId, json.encode(data));
  }

  // Get cached attendance data
  Map<String, dynamic>? getCachedAttendanceData(String studentId) {
    final cachedData = _attendanceBox.get(studentId);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    return null;
  }

  // Cache class data
  Future<void> cacheClassData(String classId, Map<String, dynamic> classData) async {
    await _classesBox.put(classId, json.encode(classData));
  }

  // Get cached class data
  Map<String, dynamic>? getCachedClassData(String classId) {
    final cachedData = _classesBox.get(classId);
    if (cachedData != null) {
      return json.decode(cachedData);
    }
    return null;
  }

  // Store attendance marking for later sync
  Future<void> storeOfflineAttendance({
    required String studentId,
    required String classId,
    required String rollNumber,
    required DateTime timestamp,
    required Map<String, double> location,
  }) async {
    final attendanceData = {
      'studentId': studentId,
      'classId': classId,
      'rollNumber': rollNumber,
      'timestamp': timestamp.toIso8601String(),
      'location': location,
      'synced': false,
    };

    final key = '${studentId}_${classId}_${timestamp.millisecondsSinceEpoch}';
    await _syncBox.put(key, json.encode(attendanceData));
    
    _logger.i('Stored offline attendance: $key');
  }

  // Get all pending sync data
  List<Map<String, dynamic>> getPendingSyncData() {
    final pendingData = <Map<String, dynamic>>[];
    
    for (var key in _syncBox.keys) {
      final data = _syncBox.get(key);
      if (data != null) {
        final attendanceData = json.decode(data);
        if (!attendanceData['synced']) {
          attendanceData['syncKey'] = key;
          pendingData.add(attendanceData);
        }
      }
    }
    
    return pendingData;
  }

  // Mark data as synced
  Future<void> markAsSynced(String syncKey) async {
    final data = _syncBox.get(syncKey);
    if (data != null) {
      final attendanceData = json.decode(data);
      attendanceData['synced'] = true;
      await _syncBox.put(syncKey, json.encode(attendanceData));
    }
  }

  // Sync pending data when online
  Future<void> _syncPendingData() async {
    if (!_isOnline) return;
    
    final pendingData = getPendingSyncData();
    _logger.i('Syncing ${pendingData.length} pending attendance records');
    
    for (var data in pendingData) {
      try {
        // Here you would call your Firebase service to sync
        // await FirebaseService().syncAttendance(data);
        
        await markAsSynced(data['syncKey']);
        _logger.i('Synced attendance: ${data['syncKey']}');
      } catch (e) {
        _logger.e('Failed to sync ${data['syncKey']}: $e');
      }
    }
  }

  // Clear old cached data
  Future<void> clearOldCache({int maxDays = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: maxDays));
    
    final keysToRemove = <dynamic>[];
    
    for (var key in _syncBox.keys) {
      final data = _syncBox.get(key);
      if (data != null) {
        final attendanceData = json.decode(data);
        final timestamp = DateTime.parse(attendanceData['timestamp']);
        
        if (timestamp.isBefore(cutoffDate) && attendanceData['synced']) {
          keysToRemove.add(key);
        }
      }
    }
    
    for (var key in keysToRemove) {
      await _syncBox.delete(key);
    }
    
    _logger.i('Cleared ${keysToRemove.length} old cache entries');
  }

  // Get offline attendance count
  int getOfflineAttendanceCount() {
    return getPendingSyncData().length;
  }

  // Force sync
  Future<void> forcSync() async {
    if (_isOnline) {
      await _syncPendingData();
    }
  }
}
