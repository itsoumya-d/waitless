import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_providers.dart';
import 'notification_service.dart';

/// Data class for notification schedule
class NotificationSchedule {
  final String venueId;
  final String venueName;
  final int hour;
  final int minute;
  final List<int> daysOfWeek; // 1-7 (Monday-Sunday)
  final bool isEnabled;

  const NotificationSchedule({
    required this.venueId,
    required this.venueName,
    required this.hour,
    required this.minute,
    required this.daysOfWeek,
    this.isEnabled = true,
  });

  String get timeString {
    final h = hour > 12 ? hour - 12 : hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    return '${h == 0 ? 12 : h}:${minute.toString().padLeft(2, '0')} $period';
  }

  String get daysString {
    if (daysOfWeek.length == 7) return 'Every day';
    if (daysOfWeek.length == 5 && 
        daysOfWeek.contains(1) && daysOfWeek.contains(2) && 
        daysOfWeek.contains(3) && daysOfWeek.contains(4) && 
        daysOfWeek.contains(5)) {
      return 'Weekdays';
    }
    if (daysOfWeek.length == 2 && 
        daysOfWeek.contains(6) && daysOfWeek.contains(7)) {
      return 'Weekends';
    }
    
    final dayNames = ['M', 'T', 'W', 'Th', 'F', 'S', 'Su'];
    return daysOfWeek.map((d) => dayNames[d - 1]).join(', ');
  }

  Map<String, dynamic> toJson() => {
    'venueId': venueId,
    'venueName': venueName,
    'hour': hour,
    'minute': minute,
    'daysOfWeek': daysOfWeek,
    'isEnabled': isEnabled,
  };

  factory NotificationSchedule.fromJson(Map<String, dynamic> json) {
    return NotificationSchedule(
      venueId: json['venueId'] as String,
      venueName: json['venueName'] as String,
      hour: json['hour'] as int,
      minute: json['minute'] as int,
      daysOfWeek: (json['daysOfWeek'] as List).cast<int>(),
      isEnabled: json['isEnabled'] as bool? ?? true,
    );
  }

  NotificationSchedule copyWith({
    String? venueId,
    String? venueName,
    int? hour,
    int? minute,
    List<int>? daysOfWeek,
    bool? isEnabled,
  }) {
    return NotificationSchedule(
      venueId: venueId ?? this.venueId,
      venueName: venueName ?? this.venueName,
      hour: hour ?? this.hour,
      minute: minute ?? this.minute,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

/// Service for managing notification schedules
class NotificationSchedulingService {
  static const _schedulesKey = 'notification_schedules';
  static const _crowdThresholdKey = 'crowd_notification_threshold';
  
  final SharedPreferences _prefs;
  final NotificationService _notificationService;
  
  NotificationSchedulingService(this._prefs, this._notificationService);
  
  /// Get crowd threshold for notifications (0-4 for CrowdLevel index)
  int getCrowdThreshold() {
    return _prefs.getInt(_crowdThresholdKey) ?? 2; // Default: medium
  }
  
  /// Set crowd threshold
  Future<void> setCrowdThreshold(int threshold) async {
    await _prefs.setInt(_crowdThresholdKey, threshold);
    debugPrint('🔔 Crowd threshold set to $threshold');
  }
  
  /// Get all notification schedules
  List<NotificationSchedule> getSchedules() {
    final json = _prefs.getStringList(_schedulesKey) ?? [];
    return json.map((s) {
      try {
        final map = _parseJson(s);
        return NotificationSchedule.fromJson(map);
      } catch (e) {
        return null;
      }
    }).whereType<NotificationSchedule>().toList();
  }
  
  /// Add a notification schedule
  Future<void> addSchedule(NotificationSchedule schedule) async {
    final schedules = getSchedules();
    schedules.add(schedule);
    await _saveSchedules(schedules);
    
    // Subscribe to venue topic
    await _notificationService.subscribeToVenue(schedule.venueId);
    
    debugPrint('📅 Added schedule for ${schedule.venueName} at ${schedule.timeString}');
  }
  
  /// Update a schedule
  Future<void> updateSchedule(int index, NotificationSchedule schedule) async {
    final schedules = getSchedules();
    if (index >= 0 && index < schedules.length) {
      schedules[index] = schedule;
      await _saveSchedules(schedules);
      debugPrint('📅 Updated schedule for ${schedule.venueName}');
    }
  }
  
  /// Remove a schedule
  Future<void> removeSchedule(int index) async {
    final schedules = getSchedules();
    if (index >= 0 && index < schedules.length) {
      final removed = schedules.removeAt(index);
      await _saveSchedules(schedules);
      
      // Check if any other schedules use this venue
      if (!schedules.any((s) => s.venueId == removed.venueId)) {
        await _notificationService.unsubscribeFromVenue(removed.venueId);
      }
      
      debugPrint('🗑️ Removed schedule for ${removed.venueName}');
    }
  }
  
  /// Toggle schedule enabled state
  Future<void> toggleSchedule(int index) async {
    final schedules = getSchedules();
    if (index >= 0 && index < schedules.length) {
      schedules[index] = schedules[index].copyWith(
        isEnabled: !schedules[index].isEnabled,
      );
      await _saveSchedules(schedules);
    }
  }
  
  /// Clear all schedules
  Future<void> clearSchedules() async {
    final schedules = getSchedules();
    for (final schedule in schedules) {
      await _notificationService.unsubscribeFromVenue(schedule.venueId);
    }
    await _prefs.remove(_schedulesKey);
    debugPrint('🗑️ Cleared all notification schedules');
  }
  
  Future<void> _saveSchedules(List<NotificationSchedule> schedules) async {
    final json = schedules.map((s) => _encodeJson(s.toJson())).toList();
    await _prefs.setStringList(_schedulesKey, json);
  }
  
  String _encodeJson(Map<String, dynamic> json) {
    // Simple JSON encoding without importing dart:convert
    final parts = json.entries.map((e) {
      final value = e.value;
      if (value is String) {
        return '"${e.key}":"$value"';
      } else if (value is List) {
        return '"${e.key}":[${value.join(",")}]';
      } else {
        return '"${e.key}":$value';
      }
    });
    return '{${parts.join(",")}}';
  }
  
  Map<String, dynamic> _parseJson(String json) {
    // Simple JSON parsing
    final map = <String, dynamic>{};
    final content = json.substring(1, json.length - 1);
    
    // Parse venueId
    var match = RegExp(r'"venueId":"([^"]*)"').firstMatch(content);
    if (match != null) map['venueId'] = match.group(1);
    
    // Parse venueName
    match = RegExp(r'"venueName":"([^"]*)"').firstMatch(content);
    if (match != null) map['venueName'] = match.group(1);
    
    // Parse hour
    match = RegExp(r'"hour":(\d+)').firstMatch(content);
    if (match != null) map['hour'] = int.parse(match.group(1)!);
    
    // Parse minute
    match = RegExp(r'"minute":(\d+)').firstMatch(content);
    if (match != null) map['minute'] = int.parse(match.group(1)!);
    
    // Parse daysOfWeek
    match = RegExp(r'"daysOfWeek":\[([^\]]*)\]').firstMatch(content);
    if (match != null) {
      final days = match.group(1)!.split(',').map((d) => int.parse(d.trim())).toList();
      map['daysOfWeek'] = days;
    }
    
    // Parse isEnabled
    match = RegExp(r'"isEnabled":(true|false)').firstMatch(content);
    if (match != null) map['isEnabled'] = match.group(1) == 'true';
    
    return map;
  }
}

/// Provider for notification scheduling service
final notificationSchedulingProvider = Provider<NotificationSchedulingService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return NotificationSchedulingService(prefs, notificationService);
});

/// Provider for notification schedules
final notificationSchedulesProvider = StateNotifierProvider<NotificationSchedulesNotifier, List<NotificationSchedule>>((ref) {
  final service = ref.watch(notificationSchedulingProvider);
  return NotificationSchedulesNotifier(service);
});

/// StateNotifier for managing schedules reactively
class NotificationSchedulesNotifier extends StateNotifier<List<NotificationSchedule>> {
  final NotificationSchedulingService _service;
  
  NotificationSchedulesNotifier(this._service) : super(_service.getSchedules());
  
  Future<void> add(NotificationSchedule schedule) async {
    await _service.addSchedule(schedule);
    state = _service.getSchedules();
  }
  
  Future<void> update(int index, NotificationSchedule schedule) async {
    await _service.updateSchedule(index, schedule);
    state = _service.getSchedules();
  }
  
  Future<void> remove(int index) async {
    await _service.removeSchedule(index);
    state = _service.getSchedules();
  }
  
  Future<void> toggle(int index) async {
    await _service.toggleSchedule(index);
    state = _service.getSchedules();
  }
  
  void refresh() {
    state = _service.getSchedules();
  }
}

/// Provider for crowd notification threshold
final crowdThresholdProvider = StateProvider<int>((ref) {
  final service = ref.watch(notificationSchedulingProvider);
  return service.getCrowdThreshold();
});
