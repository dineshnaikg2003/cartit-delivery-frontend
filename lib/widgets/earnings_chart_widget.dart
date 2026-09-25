import 'package:flutter/material.dart';
import '../app/app_colors.dart';

class WeeklyEarningBar {
  final String day;
  final double amount;
  final int orders;
  final bool isToday;

  WeeklyEarningBar({
    required this.day,
    required this.amount,
    required this.orders,
    this.isToday = false,
  });
}

class EarningsChartWidget extends StatefulWidget {
  final List<WeeklyEarningBar> weeklyData;
  final double maxGoal;

  const EarningsChartWidget({
    super.key,
    required this.weeklyData,
    this.maxGoal = 1200.0,
  });

  @override
  State<EarningsChartWidget> createState() => _EarningsChartWidgetState();
}

class _EarningsChartWidgetState extends State<EarningsChartWidget> {
  int? _selectedBarIndex;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final maxVal = widget.weeklyData.fold<double>(
      widget.maxGoal,
      (max, e) => e.amount > max ? e.amount : max,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkCardBorder : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Weekly Performance',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.darkTitle : AppColors.title,
                ),
              ),
              if (_selectedBarIndex != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${widget.weeklyData[_selectedBarIndex!].orders} Orders • ₹${widget.weeklyData[_selectedBarIndex!].amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                )
              else
                Text(
                  'Tap bar for details',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkSubtitle : AppColors.subtitle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 140,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(widget.weeklyData.length, (index) {
                final item = widget.weeklyData[index];
                final double normalizedHeight = (item.amount / maxVal).clamp(0.08, 1.0);
                final bool isSelected = _selectedBarIndex == index;

                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBarIndex = isSelected ? null : index;
                      });
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (isSelected || item.isToday)
                          Text(
                            '₹${item.amount.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: item.isToday
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTitle : AppColors.title),
                            ),
                          )
                        else
                          const SizedBox(height: 12),
                        const SizedBox(height: 4),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          height: 90 * normalizedHeight,
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: item.isToday
                                  ? [AppColors.primary, AppColors.primaryDark]
                                  : isSelected
                                      ? [AppColors.secondary, AppColors.secondaryDark]
                                      : isDark
                                          ? [const Color(0xFF1F382B), const Color(0xFF14261D)]
                                          : [const Color(0xFFE2E8F0), const Color(0xFFCBD5E1)],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: item.isToday
                                  ? AppColors.primary
                                  : isSelected
                                      ? AppColors.secondary
                                      : Colors.transparent,
                              width: 1.2,
                            ),
                            boxShadow: item.isToday
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          item.day,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: item.isToday ? FontWeight.bold : FontWeight.w500,
                            color: item.isToday
                                ? AppColors.primary
                                : (isDark ? AppColors.darkSubtitle : AppColors.subtitle),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}
