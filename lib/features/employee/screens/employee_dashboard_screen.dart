import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../shared/widgets/dashboard_header_scaffold.dart';
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

final upcomingHolidaysProvider = FutureProvider<Holiday?>((ref) async {
  try {
    final holidays = await ref.watch(settingsServiceProvider).getHolidays();
    if (holidays.isEmpty) return null;
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final futureHolidays = holidays
        .where((h) => h.date.compareTo(todayStr) >= 0)
        .toList();
    futureHolidays.sort((a, b) => a.date.compareTo(b.date));
    return futureHolidays.isNotEmpty ? futureHolidays.first : null;
  } catch (_) {
    return null;
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
  String? _statusMessage;
  bool _isWfh = false;

  Future<Position> _determinePosition() async {
    debugPrint(
      '--> _determinePosition: Checking if location service is enabled...',
    );
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled. Please enable GPS.');
    }

    debugPrint('--> _determinePosition: Checking permissions...');
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      debugPrint('--> _determinePosition: Permission denied, requesting...');
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied.');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception(
        'Location permissions are permanently denied, we cannot request permissions.',
      );
    }

    debugPrint('--> _determinePosition: Getting current position...');
    try {
      final position =
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 100,
            ),
          ).timeout(
            const Duration(seconds: 10),
          ); // Added timeout to prevent hanging infinitely
      debugPrint(
        '--> _determinePosition: Success! Lat: ${position.latitude}, Lng: ${position.longitude}',
      );
      return position;
    } catch (e) {
      debugPrint('--> _determinePosition: Failed to get position: $e');
      throw Exception('Failed to get current location: $e');
    }
  }

  void _handleCheckIn() async {
    debugPrint('--> _handleCheckIn: Button tapped!');
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final position = await _determinePosition();
      final lat = position.latitude;
      final lng = position.longitude;

      debugPrint(
        '--> _handleCheckIn: Calling attendanceServiceProvider.checkIn($lat, $lng)...',
      );
      await ref
          .read(attendanceServiceProvider)
          .checkIn(lat, lng, "Current Location", _isWfh);
      debugPrint('--> _handleCheckIn: API call completed successfully.');

      setState(() {
        _statusMessage =
            'Checked in at ${DateFormat.jm().format(DateTime.now())}';
      });
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.invalidate(todayAttendanceProvider(user.id));
      }
    } catch (e) {
      debugPrint('--> _handleCheckIn: Caught error: $e');
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _handleCheckOut() async {
    debugPrint('--> _handleCheckOut: Button tapped!');
    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });
    try {
      final position = await _determinePosition();
      final lat = position.latitude;
      final lng = position.longitude;

      debugPrint(
        '--> _handleCheckOut: Calling attendanceServiceProvider.checkOut($lat, $lng)...',
      );
      await ref
          .read(attendanceServiceProvider)
          .checkOut(lat, lng, "Current Location");
      debugPrint('--> _handleCheckOut: API call completed successfully.');

      setState(() {
        _statusMessage =
            'Checked out at ${DateFormat.jm().format(DateTime.now())}';
      });
      final user = ref.read(authProvider).user;
      if (user != null) {
        ref.invalidate(todayAttendanceProvider(user.id));
      }
    } catch (e) {
      debugPrint('--> _handleCheckOut: Caught error: $e');
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  late Stream<DateTime> _timeStream;

  @override
  void initState() {
    super.initState();
    _timeStream = Stream.periodic(
      const Duration(seconds: 1),
      (_) => DateTime.now(),
    ).asBroadcastStream();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final employeeId = user?.id ?? '';

    return DashboardHeaderScaffold(
      onRefresh: () async {
        ref.invalidate(employeeLeaveBalanceProvider(employeeId));
        ref.invalidate(employeeMonthlyReportProvider(employeeId));
      },
      headerHeight: 200.0,
      headerContent: _buildHeader(user?.name),
      bodyContent: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSessionBox(ref, employeeId),
          const SizedBox(height: 24),
          _buildLeaveBalances(ref, employeeId),
          const SizedBox(height: 24),
          _buildUpcomingHolidays(ref),
        ],
      ),
    );
  }

  Widget _buildHeader(String? name) {
    final displayName = name ?? 'Employee';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                'Welcome back, $displayName!',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Track your attendance and manage leaves from your personal hub.',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.05),
            border: Border.all(
              color: Theme.of(
                context,
              ).colorScheme.onSurface.withValues(alpha: 0.1),
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                Icons.calendar_today,
                color: Theme.of(context).colorScheme.onSurface,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  DateFormat('EEEE, d MMMM yyyy').format(DateTime.now()),
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatTime(String? timeStr) {
    if (timeStr == null ||
        timeStr.isEmpty ||
        timeStr == '--:--' ||
        timeStr == '--') {
      return '--';
    }
    try {
      final dt = DateTime.parse(timeStr).toLocal();
      return DateFormat.jm().format(dt).toLowerCase();
    } catch (_) {
      return timeStr; // fallback
    }
  }

  Widget _buildSessionBox(WidgetRef ref, String employeeId) {
    return ref
        .watch(todayAttendanceProvider(employeeId))
        .when(
          data: (attendance) {
            final isCheckedIn = attendance != null;
            final isCheckedOut = attendance?.checkOutTime != null;
            final checkInTimeStr = _formatTime(attendance?.checkInTime);
            final checkOutTimeStr = _formatTime(attendance?.checkOutTime);

            String buttonText;
            VoidCallback? onPressed;

            if (_isLoading) {
              buttonText = 'PROCESSING...';
              onPressed = null;
            } else if (!isCheckedIn) {
              buttonText = 'CHECK IN NOW';
              onPressed = _handleCheckIn;
            } else if (!isCheckedOut) {
              buttonText = 'CHECK OUT NOW';
              onPressed = _handleCheckOut;
            } else {
              buttonText = 'ALREADY CHECKED OUT';
              onPressed = null;
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Text(
                        isCheckedOut
                            ? 'WORK SESSION COMPLETED'
                            : (isCheckedIn
                                  ? 'ACTIVE WORK SESSION'
                                  : 'NOT STARTED'),
                        style: TextStyle(
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Icon(
                      Icons.access_time_filled,
                      color: Theme.of(context).colorScheme.primary,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    StreamBuilder<DateTime>(
                      stream: _timeStream,
                      builder: (context, snapshot) {
                        final time = snapshot.data ?? DateTime.now();
                        return Text(
                          DateFormat('hh:mm:ss a').format(time).toLowerCase(),
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'CURRENT SYSTEM TIME',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: Colors.grey.shade600,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'GPS Connected: Ready to mark attendance',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (!isCheckedIn && !isCheckedOut)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.home_work_outlined,
                              color: Theme.of(context).colorScheme.primary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Mark as Work From Home',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).colorScheme.onSurface,
                                ),
                              ),
                            ),
                            Switch.adaptive(
                              value: _isWfh,
                              activeTrackColor: Theme.of(context).colorScheme.primary,
                              onChanged: (val) {
                                setState(() {
                                  _isWfh = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 20),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: _isLoading
                            ? const Center(child: CircularProgressIndicator())
                            : ElevatedButton(
                                onPressed: onPressed,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Theme.of(
                                    context,
                                  ).colorScheme.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 16,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  disabledBackgroundColor: Colors.grey.shade300,
                                  disabledForegroundColor: Colors.grey.shade600,
                                ),
                                child: Text(
                                  buttonText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                      ),
                    ),
                    if (_statusMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          _statusMessage!,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),
                    if (isCheckedIn)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(color: Colors.grey.shade200),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "TODAY'S LOG:",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Check-in Time:',
                                  style: TextStyle(color: Colors.grey.shade700),
                                ),
                                Flexible(
                                  child: Text(
                                    checkInTimeStr,
                                    textAlign: TextAlign.right,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (isCheckedOut) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Check-out Time:',
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                    ),
                                  ),
                                  Flexible(
                                    child: Text(
                                      checkOutTimeStr,
                                      textAlign: TextAlign.right,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.secondary,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(
            child: Text(
              'Failed to load session status',
              style: TextStyle(color: Colors.red),
            ),
          ),
        );
  }

  Widget _buildLeaveBalances(WidgetRef ref, String employeeId) {
    return Container(
      color: Colors.transparent, // Let it use the scaffold background
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ref
          .watch(employeeLeaveBalanceProvider(employeeId))
          .when(
            data: (balance) => LeaveBalanceCards(balance: balance),
            loading: () => const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, s) => const SizedBox(
              height: 200,
              child: Center(
                child: Text(
                  'Failed to load balances',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
          ),
    );
  }

  Widget _buildUpcomingHolidays(WidgetRef ref) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.explore_outlined,
                  color: Theme.of(context).colorScheme.secondary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'UPCOMING HOLIDAYS',
                style: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withValues(alpha: 0.6),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ref
              .watch(upcomingHolidaysProvider)
              .when(
                data: (holiday) {
                  if (holiday == null) {
                    return const Text(
                      'No upcoming holidays.',
                      style: TextStyle(color: Colors.grey),
                    );
                  }

                  DateTime? date;
                  try {
                    date = DateTime.parse(holiday.date);
                  } catch (_) {}

                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            children: [
                              Text(
                                date != null
                                    ? DateFormat(
                                        'MMM',
                                      ).format(date).toUpperCase()
                                    : '---',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                date != null
                                    ? DateFormat('d').format(date)
                                    : '-',
                                style: TextStyle(
                                  color: Colors.red.shade700,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                holiday.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Text(
                                date != null
                                    ? DateFormat('EEEE').format(date)
                                    : '',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, s) => const Text(
                  'Failed to load holidays',
                  style: TextStyle(color: Colors.red),
                ),
              ),
        ],
      ),
    );
  }
}
