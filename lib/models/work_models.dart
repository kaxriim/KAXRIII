import 'dart:convert';

class WorkLog {
  final String date; // YYYY-MM-DD
  final String shift; // "Full Day", "Half Day", "Off"
  final double amount; // Positive for work earnings, negative for payday reset
  final String type; // "work" or "payday"

  WorkLog({
    required this.date,
    required this.shift,
    required this.amount,
    required this.type,
  });

  factory WorkLog.fromJson(Map<String, dynamic> json) {
    return WorkLog(
      date: json['date'] as String,
      shift: json['shift'] as String,
      amount: (json['amount'] as num).toDouble(),
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'shift': shift,
      'amount': amount,
      'type': type,
    };
  }
}

class TrackerSettings {
  double fullDayRate;
  double halfDayRate;

  TrackerSettings({
    required this.fullDayRate,
    required this.halfDayRate,
  });

  factory TrackerSettings.fromJson(Map<String, dynamic> json) {
    return TrackerSettings(
      fullDayRate: (json['full_day_rate'] as num?)?.toDouble() ?? 2000.0,
      halfDayRate: (json['half_day_rate'] as num?)?.toDouble() ?? 1000.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'full_day_rate': fullDayRate,
      'half_day_rate': halfDayRate,
    };
  }
}

class WorkData {
  List<WorkLog> logs;
  TrackerSettings settings;
  Map<String, double> goal; // e.g. {"2025-06": 40000.0}

  WorkData({
    required this.logs,
    required this.settings,
    required this.goal,
  });

  factory WorkData.initial() {
    return WorkData(
      logs: [],
      settings: TrackerSettings(fullDayRate: 2000.0, halfDayRate: 1000.0),
      goal: {},
    );
  }

  factory WorkData.fromJson(Map<String, dynamic> json) {
    var logsList = json['logs'] as List? ?? [];
    List<WorkLog> loadedLogs = logsList.map((e) => WorkLog.fromJson(e as Map<String, dynamic>)).toList();
    
    TrackerSettings loadedSettings = json['settings'] != null 
        ? TrackerSettings.fromJson(json['settings'] as Map<String, dynamic>)
        : TrackerSettings(fullDayRate: 2000.0, halfDayRate: 1000.0);

    Map<String, double> loadedGoal = {};
    if (json['goal'] != null) {
      (json['goal'] as Map<String, dynamic>).forEach((key, value) {
        loadedGoal[key] = (value as num).toDouble();
      });
    }

    return WorkData(
      logs: loadedLogs,
      settings: loadedSettings,
      goal: loadedGoal,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logs': logs.map((e) => e.toJson()).toList(),
      'settings': settings.toJson(),
      'goal': goal,
    };
  }
}