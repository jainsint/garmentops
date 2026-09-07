import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../theme/app_theme.dart';
import '../order_progress_screen.dart';

class OrderChartCardWidget extends StatefulWidget {
  final OrderData order;

  const OrderChartCardWidget({required this.order, super.key});

  @override
  State<OrderChartCardWidget> createState() => _OrderChartCardWidgetState();
}

class _OrderChartCardWidgetState extends State<OrderChartCardWidget> {
  int _touchedIndex = -1;

  // Daily production data per order (mock realistic variance)
  List<double> get _dailyData {
    switch (widget.order.orderNo) {
      case 'ORD-001':
        return [185.0, 192.0, 178.0, 195.0, 188.0, 201.0, 165.0];
      case 'ORD-002':
        return [165.0, 0.0, 170.0, 158.0, 172.0, 0.0, 0.0];
      default:
        return [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0];
    }
  }

  List<String> get _dayLabels => [
    'Aug 27',
    'Aug 28',
    'Aug 29',
    'Sep 1',
    'Sep 2',
    'Sep 3',
    'Sep 4',
  ];

  double get _target => widget.order.dailyTarget.toDouble();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final data = _dailyData;
    final maxY = (data.reduce((a, b) => a > b ? a : b) + 50).ceilToDouble();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Production',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.onSurfaceLight,
                    ),
                  ),
                  Text(
                    'Target: ${widget.order.dailyTarget} pcs/day',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      color: AppTheme.mutedText,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.successContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.trending_up_rounded,
                      size: 12,
                      color: AppTheme.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      widget.order.orderNo == 'ORD-001' ? '+4.2%' : '+2.1%',
                      style: GoogleFonts.ibmPlexSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    tooltipBgColor: AppTheme.primary,
                    tooltipRoundedRadius: 8,
                    tooltipPadding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      return BarTooltipItem(
                        '${rod.toY.toInt()} pcs\n${_dayLabels[groupIndex]}',
                        GoogleFonts.ibmPlexSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                  touchCallback: (event, response) {
                    setState(() {
                      if (response == null ||
                          response.spot == null ||
                          !event.isInterestedForInteractions) {
                        _touchedIndex = -1;
                      } else {
                        _touchedIndex = response.spot!.touchedBarGroupIndex;
                      }
                    });
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 36,
                      interval: 50,
                      getTitlesWidget: (value, meta) => Text(
                        '${value.toInt()}',
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          color: AppTheme.mutedText,
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                      getTitlesWidget: (value, meta) {
                        final i = value.toInt();
                        if (i < 0 || i >= _dayLabels.length) {
                          return const SizedBox.shrink();
                        }
                        final parts = _dayLabels[i].split(' ');
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            parts.length > 1 ? parts[1] : parts[0],
                            style: GoogleFonts.ibmPlexSans(
                              fontSize: 10,
                              color: AppTheme.mutedText,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 50,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.outlineVariantLight,
                    strokeWidth: 1,
                    dashArray: [4, 4],
                  ),
                ),
                borderData: FlBorderData(show: false),
                extraLinesData: ExtraLinesData(
                  horizontalLines: [
                    HorizontalLine(
                      y: _target,
                      color: AppTheme.secondary.withAlpha(153),
                      strokeWidth: 1.5,
                      dashArray: [6, 4],
                      label: HorizontalLineLabel(
                        show: true,
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.only(right: 4, bottom: 4),
                        style: GoogleFonts.ibmPlexSans(
                          fontSize: 10,
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w600,
                        ),
                        labelResolver: (_) => 'Target',
                      ),
                    ),
                  ],
                ),
                barGroups: List.generate(data.length, (i) {
                  final isTouched = i == _touchedIndex;
                  final value = data[i];
                  final barColor = value == 0
                      ? AppTheme.outlineVariantLight
                      : value >= _target
                      ? AppTheme.success
                      : value >= _target * 0.85
                      ? AppTheme.primary
                      : AppTheme.warning;
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: value,
                        color: isTouched ? barColor : barColor.withAlpha(204),
                        width: isTouched ? 18 : 14,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: maxY,
                          color: AppTheme.surfaceVariantLight,
                        ),
                      ),
                    ],
                  );
                }),
              ),
              swapAnimationDuration: const Duration(milliseconds: 300),
              swapAnimationCurve: Curves.easeOutCubic,
            ),
          ),
        ],
      ),
    );
  }
}
