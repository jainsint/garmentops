import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/app_theme.dart';
import '../../../core/ist_utils.dart';

class HomeWeekCalendarWidget extends StatefulWidget {
  const HomeWeekCalendarWidget({super.key});

  @override
  State<HomeWeekCalendarWidget> createState() => _HomeWeekCalendarWidgetState();
}

class _HomeWeekCalendarWidgetState extends State<HomeWeekCalendarWidget> {
  late int _selectedDay;
  late List<_DayData> _days;

  @override
  void initState() {
    super.initState();
    // Use IST "today" for the date strip
    final now = ISTUtils.today();
    _selectedDay = now.day;
    final strip = ISTUtils.weekStrip();
    _days = strip.map((d) {
      return _DayData(
        abbr: ISTUtils.dayAbbr(d.weekday),
        date: d.day,
        isToday: d.day == now.day && d.month == now.month && d.year == now.year,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: _days.map((day) {
          final isSelected = day.date == _selectedDay;
          return GestureDetector(
            onTap: () => setState(() => _selectedDay = day.date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOutCubic,
              width: 44,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    day.abbr,
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? Colors.white70 : AppTheme.mutedText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.date}',
                    style: GoogleFonts.ibmPlexSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isSelected
                          ? Colors.white
                          : AppTheme.onSurfaceLight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    isSelected
                        ? Icons.factory_rounded
                        : day.isToday
                        ? Icons.circle
                        : Icons.circle_outlined,
                    size: isSelected ? 14 : 6,
                    color: isSelected
                        ? Colors.white
                        : day.isToday
                        ? AppTheme.secondary
                        : AppTheme.outlineLight,
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _DayData {
  final String abbr;
  final int date;
  final bool isToday;
  const _DayData({
    required this.abbr,
    required this.date,
    required this.isToday,
  });
}
