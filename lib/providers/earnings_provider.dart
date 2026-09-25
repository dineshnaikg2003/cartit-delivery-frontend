import 'package:flutter/material.dart';
import '../widgets/earnings_chart_widget.dart';

class DailyEarningDetail {
  final String date;
  final int completedOrders;
  final double basePay;
  final double distanceBonus;
  final double peakSurge;
  final double tips;
  final double cashInHand;

  DailyEarningDetail({
    required this.date,
    required this.completedOrders,
    required this.basePay,
    required this.distanceBonus,
    required this.peakSurge,
    required this.tips,
    required this.cashInHand,
  });

  double get totalPayout => basePay + distanceBonus + peakSurge + tips;
}

class EarningsProvider extends ChangeNotifier {
  double _todayBasePay = 420.00;
  double _todayDistanceBonus = 180.00;
  final double _todaySurge = 90.00;
  double _todayTips = 65.00;
  double _cashInHand = 260.00; // COD collection currently held
  int _todayCompletedCount = 11;
  final double _weeklyGoal = 6000.00;
  double _weeklyEarned = 4850.00;
  double _walletBalance = 3450.00;

  double get todayTotalPayout =>
      _todayBasePay + _todayDistanceBonus + _todaySurge + _todayTips;
  double get todayBasePay => _todayBasePay;
  double get todayDistanceBonus => _todayDistanceBonus;
  double get todaySurge => _todaySurge;
  double get todayTips => _todayTips;
  double get cashInHand => _cashInHand;
  int get todayCompletedCount => _todayCompletedCount;
  double get weeklyGoal => _weeklyGoal;
  double get weeklyEarned => _weeklyEarned;
  double get walletBalance => _walletBalance;

  // Daily Incentive Milestone
  int get nextMilestoneOrders => 15;
  double get nextMilestoneBonus => 150.0;
  double get milestoneProgress =>
      (_todayCompletedCount / nextMilestoneOrders).clamp(0.0, 1.0);

  List<WeeklyEarningBar> get weeklyBarData => [
        WeeklyEarningBar(day: 'Mon', amount: 840, orders: 14),
        WeeklyEarningBar(day: 'Tue', amount: 720, orders: 12),
        WeeklyEarningBar(day: 'Wed', amount: 910, orders: 16),
        WeeklyEarningBar(day: 'Thu', amount: 650, orders: 10),
        WeeklyEarningBar(day: 'Fri', amount: 980, orders: 17),
        WeeklyEarningBar(day: 'Sat', amount: 1120, orders: 20),
        WeeklyEarningBar(
          day: 'Today',
          amount: todayTotalPayout,
          orders: _todayCompletedCount,
          isToday: true,
        ),
      ];

  List<DailyEarningDetail> get recentDays => [
        DailyEarningDetail(
          date: 'Today',
          completedOrders: _todayCompletedCount,
          basePay: _todayBasePay,
          distanceBonus: _todayDistanceBonus,
          peakSurge: _todaySurge,
          tips: _todayTips,
          cashInHand: _cashInHand,
        ),
        DailyEarningDetail(
          date: 'Yesterday (Sun)',
          completedOrders: 18,
          basePay: 720.00,
          distanceBonus: 310.00,
          peakSurge: 180.00,
          tips: 120.00,
          cashInHand: 0.00,
        ),
        DailyEarningDetail(
          date: 'Saturday (22 Aug)',
          completedOrders: 16,
          basePay: 640.00,
          distanceBonus: 260.00,
          peakSurge: 140.00,
          tips: 95.00,
          cashInHand: 0.00,
        ),
        DailyEarningDetail(
          date: 'Friday (21 Aug)',
          completedOrders: 14,
          basePay: 560.00,
          distanceBonus: 210.00,
          peakSurge: 120.00,
          tips: 80.00,
          cashInHand: 0.00,
        ),
      ];

  void addOrderEarning({required double earning, double tip = 0.0}) {
    _todayBasePay += 35.0;
    _todayDistanceBonus += (earning - 35.0).clamp(0.0, 999.0);
    _todayTips += tip;
    _todayCompletedCount += 1;
    _weeklyEarned += (earning + tip);
    _walletBalance += (earning + tip);
    notifyListeners();
  }

  void addCodCollection(double amount) {
    _cashInHand += amount;
    notifyListeners();
  }

  void depositCashInHand() {
    _cashInHand = 0.0;
    notifyListeners();
  }

  bool withdrawFunds(double amount) {
    if (amount > 0 && amount <= _walletBalance) {
      _walletBalance -= amount;
      notifyListeners();
      return true;
    }
    return false;
  }
}
