import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../models/leave.dart';

class PremiumLeaveCalendar extends StatefulWidget {
  final List<Leave> leaves;
  final Function(DateTime selectedDate, Leave? leave)? onDateTap;
  final Function(DateTime fromDate, DateTime toDate)? onApplyLeaveRange;

  const PremiumLeaveCalendar({
    super.key,
    required this.leaves,
    this.onDateTap,
    this.onApplyLeaveRange,
  });

  @override
  State<PremiumLeaveCalendar> createState() => _PremiumLeaveCalendarState();
}

class _PremiumLeaveCalendarState extends State<PremiumLeaveCalendar> {
  late DateTime _focusedMonth;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _focusedMonth = DateTime.now();
    _selectedDate = DateTime.now();
  }

  void _previousMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    setState(() {
      _focusedMonth = DateTime(_focusedMonth.year, _focusedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    setState(() {
      _focusedMonth = DateTime.now();
      _selectedDate = DateTime.now();
    });
  }

  /// Checks if [date] falls within a leave record range
  Leave? _getLeaveForDate(DateTime date) {
    final target = DateTime(date.year, date.month, date.day);
    for (final leave in widget.leaves) {
      try {
        final startDt = DateTime.parse(leave.fromDate);
        final endDt = DateTime.parse(leave.toDate);
        final start = DateTime(startDt.year, startDt.month, startDt.day);
        final end = DateTime(endDt.year, endDt.month, endDt.day);

        if ((target.isAfter(start) || target.isAtSameMomentAs(start)) &&
            (target.isBefore(end) || target.isAtSameMomentAs(end))) {
          return leave;
        }
      } catch (_) {}
    }
    return null;
  }

  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'APPROVED':
        return const Color(0xFF10B981); // Emerald Green
      case 'PENDING':
        return const Color(0xFFF59E0B); // Amber
      case 'REJECTED':
        return const Color(0xFFEF4444); // Red
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysInMonth = DateUtils.getDaysInMonth(_focusedMonth.year, _focusedMonth.month);
    final firstDayOfMonth = DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final firstWeekday = firstDayOfMonth.weekday; // 1 = Monday, 7 = Sunday

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final selectedLeave = _selectedDate != null ? _getLeaveForDate(_selectedDate!) : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Calendar Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFF0F172A),
              borderRadius: BorderRadius.vertical(top: Radius.circular(19)),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Text(
                  DateFormat('MMMM yyyy').format(_focusedMonth),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    letterSpacing: -0.2,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: _goToToday,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Today',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: Colors.white),
                  onPressed: _previousMonth,
                  tooltip: 'Previous Month',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: Colors.white),
                  onPressed: _nextMonth,
                  tooltip: 'Next Month',
                  constraints: const BoxConstraints(),
                  padding: const EdgeInsets.all(4),
                ),
              ],
            ),
          ),

          // Status Legend Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            color: const Color(0xFFF8FAFC),
            child: Wrap(
              spacing: 16,
              runSpacing: 6,
              children: [
                _buildLegendItem('Approved', const Color(0xFF10B981)),
                _buildLegendItem('Pending', const Color(0xFFF59E0B)),
                _buildLegendItem('Rejected', const Color(0xFFEF4444)),
                _buildLegendItem('Selected', const Color(0xFF4F46E5)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),

          // Weekday Labels
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'].map((day) {
                final isWeekend = day == 'SAT' || day == 'SUN';
                return Expanded(
                  child: Center(
                    child: Text(
                      day,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isWeekend ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // Days Grid
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 42, // 6 rows of 7 days
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 1.1,
              ),
              itemBuilder: (context, index) {
                final dayOffset = index - (firstWeekday - 1);
                if (dayOffset < 0 || dayOffset >= daysInMonth) {
                  return const SizedBox.shrink();
                }

                final dayNumber = dayOffset + 1;
                final currentDate = DateTime(_focusedMonth.year, _focusedMonth.month, dayNumber);
                final isToday = currentDate.isAtSameMomentAs(today);
                final isSelected = _selectedDate != null &&
                    currentDate.year == _selectedDate!.year &&
                    currentDate.month == _selectedDate!.month &&
                    currentDate.day == _selectedDate!.day;

                final leave = _getLeaveForDate(currentDate);

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = currentDate;
                    });
                    if (widget.onDateTap != null) {
                      widget.onDateTap!(currentDate, leave);
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF4F46E5).withValues(alpha: 0.12)
                          : (leave != null
                              ? _getStatusColor(leave.status).withValues(alpha: 0.08)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF4F46E5)
                            : (isToday
                                ? const Color(0xFF38BDF8)
                                : (leave != null
                                    ? _getStatusColor(leave.status).withValues(alpha: 0.4)
                                    : Colors.transparent)),
                        width: isSelected || isToday ? 1.8 : 1.0,
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '$dayNumber',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: (isToday || isSelected || leave != null)
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? const Color(0xFF4F46E5)
                                    : (isToday
                                        ? const Color(0xFF0284C7)
                                        : (leave != null
                                            ? _getStatusColor(leave.status)
                                            : const Color(0xFF1E293B))),
                              ),
                            ),
                            if (leave != null) ...[
                              const SizedBox(height: 2),
                              Container(
                                width: 6,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: _getStatusColor(leave.status),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Selected Date Info Footer
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFFF8FAFC),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(19)),
                border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
              ),
              child: selectedLeave != null
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _getStatusColor(selectedLeave.status).withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            selectedLeave.status == 'APPROVED'
                                ? Icons.check_circle_outline
                                : (selectedLeave.status == 'REJECTED'
                                    ? Icons.cancel_outlined
                                    : Icons.hourglass_empty_rounded),
                            color: _getStatusColor(selectedLeave.status),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    selectedLeave.type.replaceAll('_', ' '),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Color(0xFF0F172A),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(selectedLeave.status).withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      selectedLeave.status,
                                      style: TextStyle(
                                        color: _getStatusColor(selectedLeave.status),
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${selectedLeave.fromDate} → ${selectedLeave.toDate} • Reason: ${selectedLeave.reason}',
                                style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Color(0xFF64748B), size: 18),
                            const SizedBox(width: 8),
                            Text(
                              'Selected: ${DateFormat('EEE, MMM d, yyyy').format(_selectedDate!)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF334155),
                              ),
                            ),
                          ],
                        ),
                        if (widget.onApplyLeaveRange != null)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: VelocityColors.primaryRed,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              elevation: 0,
                            ),
                            icon: const Icon(Icons.add_rounded, size: 16),
                            label: const Text('Apply Leave', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            onPressed: () {
                              widget.onApplyLeaveRange!(_selectedDate!, _selectedDate!);
                            },
                          ),
                      ],
                    ),
            ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }
}
