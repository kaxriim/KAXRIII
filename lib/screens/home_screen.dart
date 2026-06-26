import 'package:flutter/material';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/revenue_provider.dart';
import '../widgets/day_action_sheet.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    });
  }

  void _previousMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<RevenueProvider>(context);
    final unpaid = provider.unpaidBalance;
    final earned = provider.getEarnedThisMonth(_selectedMonth);
    final collected = provider.getCollectedThisMonth(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Freelance Revenue Tracker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildMetricCards(unpaid, earned, collected),
                  const SizedBox(height: 24.0),
                  _buildCalendarHeader(),
                  const SizedBox(height: 12.0),
                  _buildCalendarGrid(provider),
                  const SizedBox(height: 28.0),
                  _buildGoalProgress(provider),
                  const SizedBox(height: 28.0),
                  Text(
                    'Annual Earnings by Month (${_selectedMonth.year})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16.0),
                  _buildEarningsChart(provider),
                  const SizedBox(height: 20.0),
                ],
              ),
            ),
    );
  }

  Widget _buildMetricCards(double unpaid, double earned, double collected) {
    final currencyFormat = NumberFormat.simpleCurrency(decimalDigits: 0, name: 'DA ');
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            'Unpaid',
            currencyFormat.format(unpaid),
            Theme.of(context).colorScheme.primaryContainer,
            Theme.of(context).colorScheme.onPrimaryContainer,
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricCard(
            'Earned',
            currencyFormat.format(earned),
            Theme.of(context).colorScheme.secondaryContainer,
            Theme.of(context).colorScheme.onSecondaryContainer,
            Icons.add_chart,
          ),
        ),
        const SizedBox(width: 8.0),
        Expanded(
          child: _buildMetricCard(
            'Collected',
            currencyFormat.format(collected),
            Theme.of(context).colorScheme.tertiaryContainer,
            Theme.of(context).colorScheme.onTertiaryContainer,
            Icons.payments,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color bgColor, Color textColor, IconData icon) {
    return Card(
      elevation: 0,
      color: bgColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 12.0),
        child: Column(
          children: [
            Icon(icon, color: textColor.withOpacity(0.8), size: 20),
            const SizedBox(height: 8.0),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4.0),
            Text(
              value,
              style: TextStyle(
                fontSize: 15,
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarHeader() {
    final monthYearStr = DateFormat('MMMM yyyy').format(_selectedMonth);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          monthYearStr,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.chevron_left),
              onPressed: _previousMonth,
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: _nextMonth,
            ),
          ],
        )
      ],
    );
  }

  Widget _buildCalendarGrid(RevenueProvider provider) {
    final firstDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month, 1);
    final lastDayOfMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 0);
    final daysInMonth = lastDayOfMonth.day;
    final weekdayOffset = firstDayOfMonth.weekday;
    final totalCellsCount = daysInMonth + (weekdayOffset - 1);

    return Column(
      children: [
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
            return Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Text(
                    day,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            crossAxisSpacing: 6.0,
            mainAxisSpacing: 6.0,
            childAspectRatio: 0.95,
          ),
          itemCount: totalCellsCount,
          itemBuilder: (context, index) {
            final dayNumber = index - (weekdayOffset - 2);
            if (dayNumber <= 0 || dayNumber > daysInMonth) {
              return const SizedBox();
            }

            final currentDayDate = DateTime(_selectedMonth.year, _selectedMonth.month, dayNumber);
            final dateString = DateFormat('yyyy-MM-dd').format(currentDayDate);
            final workLog = provider.getWorkLog(dateString);
            final isPayday = provider.hasPayday(dateString);

            return _buildCalendarDayCell(currentDayDate, workLog, isPayday);
          },
        ),
      ],
    );
  }

  Widget _buildCalendarDayCell(DateTime date, dynamic workLog, bool isPayday) {
    final dayStr = date.day.toString();
    String shiftType = workLog?.shift ?? 'Off';
    double earnedAmount = workLog?.amount ?? 0.0;

    Color cellBgColor = Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
    Color textColor = Theme.of(context).colorScheme.onSurface;
    Border? customBorder;

    if (shiftType == 'Full Day') {
      cellBgColor = Colors.green.shade100;
      textColor = Colors.green.shade900;
    } else if (shiftType == 'Half Day') {
      cellBgColor = Colors.amber.shade100;
      textColor = Colors.amber.shade900;
    } else if (shiftType == 'Off' && workLog != null && earnedAmount == 0.0) {
      cellBgColor = Colors.grey.shade200;
      textColor = Colors.grey.shade600;
    }

    if (isPayday) {
      customBorder = Border.all(color: Colors.amber.shade700, width: 2.0);
    }

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(28.0)),
          ),
          builder: (context) => DayActionSheet(date: date),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: cellBgColor,
          borderRadius: BorderRadius.circular(8.0),
          border: customBorder ?? Border.all(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dayStr,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              if (earnedAmount > 0)
                Align(
                  alignment: Alignment.bottomRight,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 1.0),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '${(earnedAmount / 1000).toStringAsFixed(1)}k',
                      style: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              if (isPayday && earnedAmount <= 0)
                const Align(
                  alignment: Alignment.bottomRight,
                  child: Icon(
                    Icons.paid_outlined,
                    size: 14,
                    color: Colors.amber,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGoalProgress(RevenueProvider provider) {
    final yearMonthStr = DateFormat('yyyy-MM').format(_selectedMonth);
    final earned = provider.getEarnedThisMonth(_selectedMonth);
    final goalValue = provider.getGoalForMonth(yearMonthStr);
    double progress = goalValue > 0 ? (earned / goalValue) : 0.0;
    if (progress > 1.0) progress = 1.0;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Monthly Progress',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Earned: ${earned.toStringAsFixed(0)} DA',
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  'Goal: ${goalValue.toStringAsFixed(0)} DA',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildEarningsChart(RevenueProvider provider) {
    Map<int, double> earnings = provider.getAnnualEarningsByMonth(_selectedMonth.year);
    List<BarChartGroupData> barGroups = [];
    double maxVal = 0.0;
    for (int m = 1; m <= 12; m++) {
      double earned = earnings[m] ?? 0.0;
      if (earned > maxVal) maxVal = earned;
      barGroups.add(
        BarChartGroupData(
          x: m,
          barRods: [
            BarChartRodData(
              toY: earned,
              color: Theme.of(context).colorScheme.primary,
              width: 10,
              borderRadius: BorderRadius.circular(4.0),
              backDrawRodData: BackgroundBarChartRodData(
                show: true,
                toY: maxVal > 0 ? maxVal * 1.1 : 5000,
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              ),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxVal > 0 ? maxVal * 1.2 : 10000.0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceVariant,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                String monthName = DateFormat('MMM').format(DateTime(_selectedMonth.year, group.x));
                return BarTooltipItem(
                  '$monthName\n${rod.toY.toStringAsFixed(0)} DA',
                  TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontWeight: FontWeight.bold),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (double value, TitleMeta meta) {
                  const style = TextStyle(fontSize: 10, fontWeight: FontWeight.bold);
                  String monthStr = '';
                  switch (value.toInt()) {
                    case 1: monthStr = 'Jan'; break;
                    case 2: monthStr = 'Feb'; break;
                    case 3: monthStr = 'Mar'; break;
                    case 4: monthStr = 'Apr'; break;
                    case 5: monthStr = 'May'; break;
                    case 6: monthStr = 'Jun'; break;
                    case 7: monthStr = 'Jul'; break;
                    case 8: monthStr = 'Aug'; break;
                    case 9: monthStr = 'Sep'; break;
                    case 10: monthStr = 'Oct'; break;
                    case 11: monthStr = 'Nov'; break;
                    case 12: monthStr = 'Dec'; break;
                  }
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    child: Text(monthStr, style: style),
                  );
                },
                reservedSize: 22,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 45,
                getTitlesWidget: (double value, TitleMeta meta) {
                  return Text(
                    '${(value / 1000).toStringAsFixed(0)}k',
                    style: const TextStyle(fontSize: 9),
                  );
                },
              ),
            ),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4),
              strokeWidth: 1,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: barGroups,
        ),
      ),
    );
  }
}