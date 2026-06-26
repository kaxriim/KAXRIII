import 'package:flutter/material';
import '../models/work_models.dart';
import '../services/storage_service.dart';

class RevenueProvider extends ChangeNotifier {
  final StorageService _storageService = StorageService();
  
  WorkData _data = WorkData.initial();
  bool _isLoading = true;

  WorkData get data => _data;
  bool get isLoading => _isLoading;

  RevenueProvider() {
    loadData();
  }

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();
    _data = await _storageService.readData();
    _isLoading = false;
    notifyListeners();
  }

  Future<void> saveData() async {
    await _storageService.writeData(_data);
    notifyListeners();
  }

  double get unpaidBalance {
    return _data.logs.fold(0.0, (sum, log) => sum + log.amount);
  }

  double getEarnedThisMonth(DateTime month) {
    double total = 0.0;
    for (var log in _data.logs) {
      if (log.type == 'work' && log.amount > 0) {
        try {
          DateTime logDate = DateTime.parse(log.date);
          if (logDate.year == month.year && logDate.month == month.month) {
            total += log.amount;
          }
        } catch (e) {
          // parse error
        }
      }
    }
    return total;
  }

  double getCollectedThisMonth(DateTime month) {
    double total = 0.0;
    for (var log in _data.logs) {
      if (log.type == 'payday') {
        try {
          DateTime logDate = DateTime.parse(log.date);
          if (logDate.year == month.year && logDate.month == month.month) {
            total += log.amount.abs();
          }
        } catch (e) {
          // parse error
        }
      }
    }
    return total;
  }

  WorkLog? getWorkLog(String dateString) {
    try {
      return _data.logs.firstWhere(
        (log) => log.date == dateString && log.type == 'work',
      );
    } catch (e) {
      return null;
    }
  }

  bool hasPayday(String dateString) {
    return _data.logs.any((log) => log.date == dateString && log.type == 'payday');
  }

  Future<void> saveWorkShift(String dateString, String shift) async {
    double amount = 0.0;
    if (shift == 'Full Day') {
      amount = _data.settings.fullDayRate;
    } else if (shift == 'Half Day') {
      amount = _data.settings.halfDayRate;
    }

    int index = _data.logs.indexWhere((log) => log.date == dateString && log.type == 'work');

    if (index >= 0) {
      if (shift == 'Off') {
        _data.logs[index] = WorkLog(
          date: dateString,
          shift: 'Off',
          amount: 0.0,
          type: 'work',
        );
      } else {
        _data.logs[index] = WorkLog(
          date: dateString,
          shift: shift,
          amount: amount,
          type: 'work',
        );
      }
    } else {
      _data.logs.add(WorkLog(
        date: dateString,
        shift: shift,
        amount: amount,
        type: 'work',
      ));
    }

    await saveData();
  }

  Future<void> markAsPayday(String dateString) async {
    double balanceBeforePayday = unpaidBalance;
    if (balanceBeforePayday <= 0) return;

    _data.logs.add(WorkLog(
      date: dateString,
      shift: 'Off',
      amount: -balanceBeforePayday,
      type: 'payday',
    ));

    await saveData();
  }

  Future<void> updateRates(double fullDay, double halfDay) async {
    _data.settings.fullDayRate = fullDay;
    _data.settings.halfDayRate = halfDay;
    await saveData();
  }

  Future<void> updateGoal(String yearMonth, double goalValue) async {
    _data.goal[yearMonth] = goalValue;
    await saveData();
  }

  double getGoalForMonth(String yearMonth) {
    return _data.goal[yearMonth] ?? 40000.0;
  }

  Future<void> factoryReset() async {
    _data = WorkData.initial();
    await _storageService.deleteData();
    notifyListeners();
  }

  Map<int, double> getAnnualEarningsByMonth(int year) {
    Map<int, double> monthlyEarnings = {};
    for (int m = 1; m <= 12; m++) {
      monthlyEarnings[m] = 0.0;
    }

    for (var log in _data.logs) {
      if (log.type == 'work' && log.amount > 0) {
        try {
          DateTime date = DateTime.parse(log.date);
          if (date.year == year) {
            monthlyEarnings[date.month] = (monthlyEarnings[date.month] ?? 0.0) + log.amount;
          }
        } catch (e) {}
      }
    }
    return monthlyEarnings;
  }
}