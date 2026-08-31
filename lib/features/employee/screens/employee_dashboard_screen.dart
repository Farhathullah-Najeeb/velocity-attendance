import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user.dart';
import '../../attendance/services/attendance_service.dart';
import '../../leaves/services/leave_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../admin/services/settings_service.dart';
import '../../../models/leave.dart';
import '../../../models/holiday.dart';
import '../../../models/attendance.dart';
import '../../shared/widgets/leave_balance_cards.dart';

final employeeLeaveBalanceProvider = FutureProvider.autoDispose
    .family<LeaveBalance, String>((ref, employeeId) {
      return ref.watch(leaveServiceProvider).getLeaveBalance(employeeId);
    });

final todayAttendanceProvider = FutureProvider.autoDispose
    .family<Attendance?, String>((ref, employeeId) async {
      try {
        final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
        final service = ref.watch(attendanceServiceProvider);
        final history = await service.getHistory(
          employeeId,
          startDate: today,
          endDate: today,
        );
        if (history.isNotEmpty) {
          return history.first;
        }
      } catch (_) {}
      return null;
    });

final employeeMonthlyReportProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>, String>((ref, employeeId) {
      return ref
          .watch(attendanceServiceProvider)
          .getMonthlyReport(employeeId: employeeId);
    });

final upcomingHolidaysListProvider = FutureProvider.autoDispose<List<Holiday>>((
  ref,
) async {
  try {
    final holidays = await ref.watch(settingsServiceProvider).getHolidays();
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final futureHolidays = holidays
        .where((h) => h.date.compareTo(todayStr) >= 0)
        .toList();
    futureHolidays.sort((a, b) => a.date.compareTo(b.date));
    return futureHolidays;
  } catch (_) {
    return [];
  }
});

@RoutePage()
class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() =>
      _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState
    extends ConsumerState<EmployeeDashboardScreen> {
  bool _isLoading = false;
  bool _isWfh = false;
  String? _locationLabel;
  late Stream<DateTime> _timeStream;
  bool _isLocationLoading = true;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).asBroadcastStream();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchCurrentLocationSilently();
    });
  }

  Future<void> _fetchCurrentLocationSilently() async {
    setState(() => _isLocationLoading = true);
    try {
      final pos = await _determinePosition();
      if (!mounted) return;
      await _reverseGeocode(pos);
    } catch (e) {
      debugPrint('Silent location check: $e');
    } finally {
      if (mounted) setState(() => _isLocationLoading = false);
    }
  }

  Future<void> _reverseGeocode(Position pos) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        final p = placemarks.first;
        final name = p.name ?? p.street ?? p.subLocality ?? p.locality ?? '';
        if (name.isNotEmpty) {
          setState(() {
            _locationLabel = name;
          });
        }
      }
    } catch (e) {
      debugPrint('Reverse geocode error: $e');
    }
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied.');
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 100,
      ),
    ).timeout(const Duration(seconds: 10));
  }

  void _handleCheckIn() async {
    setState(() => _isLoading = true);
    try {
      final position = await _determinePosition();
      final lat = position.latitude;
      final lng = position.longitude;

      await ref
          .read(attendanceServiceProvider)
          .checkIn(lat, lng, _locationLabel ?? "Current Location", _isWfh);

      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.invalidate(todayAttendanceProvider(user.id));
      }

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '✅ Check-in successful at ${DateFormat('hh:mm a').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCheckOut() async {
    setState(() => _isLoading = true);
    try {
      final position = await _determinePosition();
      final lat = position.latitude;
      final lng = position.longitude;

      await ref
          .read(attendanceServiceProvider)
          .checkOut(lat, lng, _locationLabel ?? "Current Location");

      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.invalidate(todayAttendanceProvider(user.id));
      }

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          '✅ Check-out successful at ${DateFormat('hh:mm a').format(DateTime.now())}',
        );
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty || timeStr == '--:--') {
      return '--:--';
    }
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat('hh:mm a').format(dt);
    } catch (_) {
      return timeStr;
    }
  }

  String _calcDuration(Attendance? att) {
    if (att == null) return '0h 0m';
    if (att.formattedWorkTime != null) return att.formattedWorkTime!;
    if (att.workDurationMinutes != null && att.workDurationMinutes! > 0) {
      final h = att.workDurationMinutes! ~/ 60;
      final m = att.workDurationMinutes! % 60;
      return '${h}h ${m}m';
    }
    final inTime = att.checkInTime;
    final outTime = att.checkOutTime;
    if (outTime != null) {
      try {
        final inDt = DateTime.parse(inTime).toLocal();
        final outDt = DateTime.parse(outTime).toLocal();
        final diff = outDt.difference(inDt);
        final h = diff.inHours;
        final m = diff.inMinutes % 60;
        return '${h}h ${m}m';
      } catch (_) {}
    }
    return '0h 0m';
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final employeeId = user?.id ?? '';
    final isDesktop = kIsWeb && MediaQuery.of(context).size.width > 950;

    final attendanceAsync = ref.watch(todayAttendanceProvider(employeeId));
    final reportAsync = ref.watch(employeeMonthlyReportProvider(employeeId));

    return Container(
      color: VelocityColors.background,
      child: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(todayAttendanceProvider(employeeId));
          ref.invalidate(employeeLeaveBalanceProvider(employeeId));
          ref.invalidate(employeeMonthlyReportProvider(employeeId));
          ref.invalidate(upcomingHolidaysListProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Dark Navy Greeting Card
              _buildGreetingBanner(
                user,
                attendanceAsync.asData?.value,
                isDesktop,
              ),
              const SizedBox(height: 24),

              // 2. Main Dashboard Grid / Stack
              if (isDesktop)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Left Column: Attendance Console
                    SizedBox(
                      width: 400,
                      child: _buildAttendanceConsole(
                        attendanceAsync.asData?.value,
                      ),
                    ),
                    const SizedBox(width: 24),
                    // Right Column: Leave Balances + Quick Actions + Upcoming Holidays
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildLeaveBalances(
                            employeeId,
                            reportAsync.asData?.value,
                          ),
                          const SizedBox(height: 24),
                          _buildQuickActionsHub(),
                          const SizedBox(height: 24),
                          _buildUpcomingHolidaysBulletin(),
                        ],
                      ),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildAttendanceConsole(attendanceAsync.asData?.value),
                    const SizedBox(height: 24),
                    _buildLeaveBalances(employeeId, reportAsync.asData?.value),
                    const SizedBox(height: 24),
                    _buildQuickActionsHub(),
                    const SizedBox(height: 24),
                    _buildUpcomingHolidaysBulletin(),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP GREETING BANNER (DARK NAVY)
  // ===========================================================================
  Widget _buildGreetingBanner(
    User? user,
    Attendance? attendance,
    bool isDesktop,
  ) {
    final userName = user?.name ?? 'Employee';
    final dept = (user?.department ?? 'IT').toLowerCase();
    final employeeId = user?.employeeId ?? 'EMP001';

    final isCheckedIn = attendance != null;
    final isCheckedOut = attendance?.checkOutTime != null;

    final String sessionStatusText = isCheckedOut
        ? 'Completed ✓'
        : isCheckedIn
        ? 'In Session ●'
        : 'Not Checked In';

    final Color sessionStatusColor = isCheckedOut
        ? const Color(0xFFA78BFA)
        : isCheckedIn
        ? const Color(0xFF34D399)
        : const Color(0xFFF87171);

    final Color sessionStatusBg = isCheckedOut
        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
        : isCheckedIn
        ? const Color(0xFF10B981).withValues(alpha: 0.15)
        : const Color(0xFFEF4444).withValues(alpha: 0.15);

    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? '☀️ GOOD MORNING'
        : hour < 17
        ? '🌤️ GOOD AFTERNOON'
        : '🌙 GOOD EVENING';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF334155), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 22),
      child: Row(
        children: [
          // Avatar with gradient ring
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFF97316)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'E',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          // Greeting + Name + Pills
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          shadows: [
                            Shadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        employeeId,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Dept pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.business_center_outlined,
                            size: 14,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dept,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Session Status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: sessionStatusBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: sessionStatusColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: sessionStatusColor,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: sessionStatusColor.withValues(
                                    alpha: 0.5,
                                  ),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            sessionStatusText,
                            style: TextStyle(
                              color: sessionStatusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (isDesktop) ...[
            // Date & Live Time Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE53935).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.calendar_today_outlined,
                      size: 18,
                      color: Color(0xFFE53935),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('EEEE, d MMM yyyy').format(DateTime.now()),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      StreamBuilder<DateTime>(
                        stream: _timeStream,
                        builder: (context, snapshot) {
                          final t = snapshot.data ?? DateTime.now();
                          return Row(
                            children: [
                              Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF34D399),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('hh:mm:ss a').format(t),
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // My Requests Button
            ElevatedButton.icon(
              onPressed: () {
                context.router.push(const EmployeeRequestsRoute());
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE53935),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 4,
                shadowColor: const Color(0xFFE53935).withValues(alpha: 0.3),
              ),
              icon: const Icon(Icons.description_outlined, size: 18),
              label: const Text(
                'My Requests',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. ATTENDANCE CONSOLE CARD
  // ===========================================================================
  Widget _buildAttendanceConsole(Attendance? attendance) {
    final isCheckedIn = attendance != null;
    final isCheckedOut = attendance?.checkOutTime != null;

    final inTimeStr = _formatTime(attendance?.checkInTime);
    final outTimeStr = _formatTime(attendance?.checkOutTime);
    final durationStr = _calcDuration(attendance);

    final statusText = isCheckedOut
        ? 'COMPLETED ✓'
        : isCheckedIn
        ? 'ACTIVE ●'
        : 'NOT STARTED';

    final statusColor = isCheckedOut
        ? VelocityColors.purple
        : isCheckedIn
        ? VelocityColors.success
        : VelocityColors.danger;

    final statusBg = isCheckedOut
        ? VelocityColors.purpleBg
        : isCheckedIn
        ? VelocityColors.successBg
        : VelocityColors.dangerBg;

    final locationText = _locationLabel != null && _locationLabel!.isNotEmpty
        ? _locationLabel!
        : 'AGS Transact Technologies Pvt Ltd, Govt ...';

    return Container(
      decoration: BoxDecoration(
        color: VelocityColors.baseWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VelocityColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row: ATTENDANCE CONSOLE + Status Pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: VelocityColors.primaryRedLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: VelocityColors.primaryRed,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ATTENDANCE CONSOLE',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: VelocityColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: statusColor.withValues(alpha: 0.3),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: statusColor.withValues(alpha: 0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Clock Icon with gradient
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1F0), Color(0xFFFFE4E3)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withValues(alpha: 0.15),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(
              Icons.access_time_filled,
              color: VelocityColors.primaryRed,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),

          // Big Digital Clock
          StreamBuilder<DateTime>(
            stream: _timeStream,
            builder: (context, snapshot) {
              final t = snapshot.data ?? DateTime.now();
              return Column(
                children: [
                  Text(
                    DateFormat('hh:mm:ss').format(t),
                    style: const TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                      shadows: [Shadow(color: Colors.black, blurRadius: 8)],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    DateFormat('a').format(t),
                    style: const TextStyle(
                      color: VelocityColors.textMuted,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),

          // Location Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [VelocityColors.surfaceAlt, VelocityColors.baseWhite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: VelocityColors.border),
            ),
            child: Row(
              children: [
                if (_isLocationLoading)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: VelocityColors.primaryRed,
                    ),
                  )
                else
                  const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: VelocityColors.primaryRed,
                  ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    locationText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: VelocityColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: VelocityColors.primaryRedLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      color: VelocityColors.primaryRed,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // WFH switch if not checked in
          if (!isCheckedIn && !isCheckedOut) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [VelocityColors.surfaceAlt, VelocityColors.baseWhite],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: VelocityColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.home_work_outlined,
                      color: Color(0xFF3B82F6),
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Work From Home (WFH)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color: VelocityColors.textPrimary,
                      ),
                    ),
                  ),
                  Transform.scale(
                    scale: 0.8,
                    child: Switch.adaptive(
                      value: _isWfh,
                      activeTrackColor: VelocityColors.primaryRed,
                      onChanged: (val) => setState(() => _isWfh = val),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Main Action Button
          if (isCheckedOut)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [const Color(0xFFF0FDF4), const Color(0xFFE8F5E9)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF16A34A),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Today's Session Completed Successfully ✓",
                    style: TextStyle(
                      color: Color(0xFF16A34A),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            )
          else
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : isCheckedIn
                    ? _handleCheckOut
                    : _handleCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isCheckedIn
                                ? Icons.logout_rounded
                                : Icons.login_rounded,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isCheckedIn ? 'CHECK OUT NOW' : 'CHECK IN NOW',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          const SizedBox(height: 20),

          // TODAY'S LOG TIMINGS BOX
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [VelocityColors.surfaceAlt, VelocityColors.baseWhite],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: VelocityColors.border),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: VelocityColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "TODAY'S LOG TIMINGS",
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: VelocityColors.textSubtle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: VelocityColors.baseWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VelocityColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHECK IN',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: VelocityColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.login_rounded,
                                  size: 14,
                                  color: Color(0xFF16A34A),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  inTimeStr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: VelocityColors.baseWhite,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: VelocityColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'CHECK OUT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: VelocityColors.textMuted,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.logout_rounded,
                                  size: 14,
                                  color: Color(0xFFDC2626),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  outTimeStr,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFDC2626),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: const [
                          Icon(
                            Icons.timer_outlined,
                            size: 16,
                            color: VelocityColors.textSubtle,
                          ),
                          SizedBox(width: 8),
                          Text(
                            'Logged Duration:',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: VelocityColors.textSubtle,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE53935).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          durationStr,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: VelocityColors.primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 3. LEAVE BALANCES (4 CARDS)
  // ===========================================================================
  Widget _buildLeaveBalances(String employeeId, Map<String, dynamic>? report) {
    final balanceAsync = ref.watch(employeeLeaveBalanceProvider(employeeId));
    final daysLogged = report?['daysPresent'] as int? ?? 3;

    return balanceAsync.when(
      data: (balance) => LeaveBalanceCards(
        balance: balance,
        forceDesktop: true,
        daysLoggedThisMonth: daysLogged,
      ),
      loading: () => Container(
        height: 120,
        decoration: BoxDecoration(
          color: VelocityColors.baseWhite,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: VelocityColors.border),
        ),
        child: const Center(
          child: CircularProgressIndicator(color: VelocityColors.primaryRed),
        ),
      ),
      error: (e, s) => const SizedBox.shrink(),
    );
  }

  // ===========================================================================
  // 4. QUICK ACTIONS HUB (3 CARDS)
  // ===========================================================================
  Widget _buildQuickActionsHub() {
    return Container(
      decoration: BoxDecoration(
        color: VelocityColors.baseWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VelocityColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.trending_up_rounded,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Quick Actions Hub',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: VelocityColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: VelocityColors.successBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '3 ACTIONS',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: VelocityColors.success,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                _QuickActionTile(
                  icon: Icons.description_outlined,
                  iconColor: VelocityColors.primaryRed,
                  iconBg: VelocityColors.dangerBg,
                  title: 'Unified Requests',
                  subtitle:
                      'Submit and track Overtime, WFH, Regularization, and Leave requests',
                  badge: '0 pending',
                  onTap: () =>
                      context.router.push(const EmployeeRequestsRoute()),
                ),
                _QuickActionTile(
                  icon: Icons.beach_access_rounded,
                  iconColor: Colors.white,
                  iconBg: VelocityColors.primaryRed,
                  title: 'Apply for Leave',
                  subtitle:
                      'Submit Casual, Sick, or Compensatory leave applications',
                  isActive: true,
                  badge: 'Quick Apply',
                  onTap: () => context.router.push(const EmployeeLeavesRoute()),
                ),
                _QuickActionTile(
                  icon: Icons.assignment_outlined,
                  iconColor: VelocityColors.primaryRed,
                  iconBg: VelocityColors.dangerBg,
                  title: 'Attendance History',
                  subtitle:
                      'View complete check-in history, timings, and request overtime',
                  badge: 'View All',
                  onTap: () =>
                      context.router.push(const EmployeeHistoryRoute()),
                ),
              ];

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: cards[0]),
                    const SizedBox(width: 14),
                    Expanded(child: cards[1]),
                    const SizedBox(width: 14),
                    Expanded(child: cards[2]),
                  ],
                );
              } else {
                return Column(
                  children: [
                    cards[0],
                    const SizedBox(height: 12),
                    cards[1],
                    const SizedBox(height: 12),
                    cards[2],
                  ],
                );
              }
            },
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // 5. UPCOMING HOLIDAYS & BULLETIN (CALENDAR TILES)
  // ===========================================================================
  Widget _buildUpcomingHolidaysBulletin() {
    final holidaysAsync = ref.watch(upcomingHolidaysListProvider);

    return Container(
      decoration: BoxDecoration(
        color: VelocityColors.baseWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VelocityColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFF97316)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.explore_outlined,
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Upcoming Holidays & Bulletin',
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: VelocityColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'CALENDAR',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: VelocityColors.primaryRed,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          holidaysAsync.when(
            data: (holidays) {
              if (holidays.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  decoration: BoxDecoration(
                    color: VelocityColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VelocityColors.border),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.celebration_outlined,
                        size: 32,
                        color: VelocityColors.textMuted,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No upcoming holidays scheduled',
                        style: TextStyle(
                          color: VelocityColors.textSubtle,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Check back later for updates',
                        style: TextStyle(
                          color: VelocityColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final displayHolidays = holidays.take(4).toList();

              if (displayHolidays.length > 2) {
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 3.2,
                  ),
                  itemCount: displayHolidays.length,
                  itemBuilder: (context, index) {
                    return _buildHolidayTile(displayHolidays[index]);
                  },
                );
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: displayHolidays.map((holiday) {
                    return Container(
                      margin: const EdgeInsets.only(right: 14),
                      child: _buildHolidayTile(holiday),
                    );
                  }).toList(),
                ),
              );
            },
            loading: () => Container(
              height: 100,
              decoration: BoxDecoration(
                color: VelocityColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  color: VelocityColors.primaryRed,
                  strokeWidth: 2.5,
                ),
              ),
            ),
            error: (e, s) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  Widget _buildHolidayTile(Holiday holiday) {
    DateTime? dt;
    try {
      dt = DateTime.parse(holiday.date).toLocal();
    } catch (_) {}

    final monthStr = dt != null
        ? DateFormat('MMM').format(dt).toUpperCase()
        : 'AUG';
    final dayStr = dt != null ? dt.day.toString() : '1';
    final weekdayStr = dt != null ? DateFormat('EEEE').format(dt) : 'Holiday';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [VelocityColors.surfaceAlt, VelocityColors.baseWhite],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: VelocityColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Red Date Square
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  monthStr,
                  style: const TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    height: 1.0,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  dayStr,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    height: 1.0,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                holiday.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: VelocityColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 12,
                    color: VelocityColors.textMuted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    weekdayStr,
                    style: const TextStyle(
                      fontSize: 11,
                      color: VelocityColors.textSubtle,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool isActive;
  final String badge;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.isActive = false,
    required this.badge,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: VelocityColors.baseWhite,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? VelocityColors.primaryRed : VelocityColors.border,
            width: isActive ? 2 : 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: isActive
                        ? const LinearGradient(
                            colors: [Color(0xFFE53935), Color(0xFFF97316)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: isActive ? null : iconBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? Colors.white : iconColor,
                    size: 20,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? VelocityColors.primaryRed
                        : VelocityColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: isActive
                          ? Colors.white
                          : VelocityColors.textSubtle,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: VelocityColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11.5,
                color: VelocityColors.textSubtle,
                height: 1.4,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
