import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';
import '../../shared/widgets/dashboard_header_scaffold.dart';
import '../../attendance/services/attendance_service.dart';
import '../../leaves/services/leave_service.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/leave.dart';

final employeeLeaveBalanceProvider = FutureProvider.autoDispose.family<LeaveBalance, String>((ref, employeeId) {
  return ref.watch(leaveServiceProvider).getLeaveBalance(employeeId);
});

final employeeMonthlyReportProvider = FutureProvider.autoDispose.family<Map<String, dynamic>, String>((ref, employeeId) {
  return ref.watch(attendanceServiceProvider).getMonthlyReport(employeeId: employeeId);
});

@RoutePage()
class EmployeeDashboardScreen extends ConsumerStatefulWidget {
  const EmployeeDashboardScreen({super.key});

  @override
  ConsumerState<EmployeeDashboardScreen> createState() => _EmployeeDashboardScreenState();
}

class _EmployeeDashboardScreenState extends ConsumerState<EmployeeDashboardScreen> {
  bool _isLoading = false;
  String? _statusMessage;

  Future<Position> _determinePosition() async {
    debugPrint('--> _determinePosition: Checking if location service is enabled...');
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
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    }

    debugPrint('--> _determinePosition: Getting current position...');
    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      ).timeout(const Duration(seconds: 10)); // Added timeout to prevent hanging infinitely
      debugPrint('--> _determinePosition: Success! Lat: ${position.latitude}, Lng: ${position.longitude}');
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
      
      debugPrint('--> _handleCheckIn: Calling attendanceServiceProvider.checkIn($lat, $lng)...');
      await ref.read(attendanceServiceProvider).checkIn(lat, lng, "Current Location");
      debugPrint('--> _handleCheckIn: API call completed successfully.');
      
      setState(() {
        _statusMessage = 'Checked in at ${DateFormat.jm().format(DateTime.now())}';
      });
    } catch (e) {
      debugPrint('--> _handleCheckIn: Caught error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red),
        );
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
      
      debugPrint('--> _handleCheckOut: Calling attendanceServiceProvider.checkOut($lat, $lng)...');
      await ref.read(attendanceServiceProvider).checkOut(lat, lng, "Current Location");
      debugPrint('--> _handleCheckOut: API call completed successfully.');
      
      setState(() {
        _statusMessage = 'Checked out at ${DateFormat.jm().format(DateTime.now())}';
      });
    } catch (e) {
      debugPrint('--> _handleCheckOut: Caught error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final employeeId = user?.id ?? '';

    return DashboardHeaderScaffold(
      headerHeight: 320.0,
      onRefresh: () async {
        ref.invalidate(employeeLeaveBalanceProvider(employeeId));
        ref.invalidate(employeeMonthlyReportProvider(employeeId));
      },
      headerContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                  children: [
                    const TextSpan(
                      text: 'VEL',
                      style: TextStyle(color: Colors.white),
                    ),
                    WidgetSpan(
                      alignment: PlaceholderAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(Icons.location_on, color: AppTheme.primaryRed, size: 20),
                      ),
                    ),
                    const TextSpan(
                      text: 'CITY',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'THE PROJECT MANAGEMENT PEOPLE',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 8,
              letterSpacing: 2,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Welcome back,',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                user?.name ?? 'Employee',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(width: 8),
              const Text('👋', style: TextStyle(fontSize: 24)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            DateFormat('EEEE, MMMM d, yyyy').format(DateTime.now()),
            style: const TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
      bodyContent: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Attendance Card (overlapping)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _AttendanceCard(
              isLoading: _isLoading,
              statusMessage: _statusMessage,
              onCheckIn: _handleCheckIn,
              onCheckOut: _handleCheckOut,
            ),
          ),

          const SizedBox(height: 24),

          // 2. Stats Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: _buildStatsSection(ref, employeeId),
          ),

          const SizedBox(height: 24),

          // 3. Quick Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(
                      Icons.flash_on,
                      color: AppTheme.primaryRed,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'QUICK ACTIONS',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _QuickActionCard(
                  icon: Icons.calendar_today_outlined,
                  title: 'Apply for Leave',
                  subtitle: 'Submit a new leave or vacation request.',
                  onTap: () => AutoTabsRouter.of(context).setActiveIndex(1), // Leaves tab
                ),
                const SizedBox(height: 8),
                _QuickActionCard(
                  icon: Icons.history,
                  title: 'View Attendance History',
                  subtitle: 'Check your past check-ins and logs.',
                  onTap: () => AutoTabsRouter.of(context).setActiveIndex(2), // History tab
                ),
                const SizedBox(height: 8),
                _QuickActionCard(
                  icon: Icons.more_time,
                  title: 'Request Overtime',
                  subtitle: 'Log additional working hours.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Coming soon')));
                  },
                ),
                const SizedBox(height: 8),
                _QuickActionCard(
                  icon: Icons.notifications_none_outlined,
                  title: 'View Notifications',
                  subtitle: 'Stay updated on your requests.',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No new notifications')));
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // 4. Guidelines
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                      const SizedBox(width: 8),
                      Text('Guidelines', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text('• Ensure you check in before 9:00 AM to avoid late remarks.'),
                  const SizedBox(height: 4),
                  const Text('• Location access is required for remote check-ins.'),
                  const SizedBox(height: 4),
                  const Text('• Forgotten check-outs will default to half-day penalty.'),
                ],
              ),
            ),
          ),

          const SizedBox(height: 100), // Bottom padding for nav bar
        ],
      ),
    );
  }

  Widget _buildStatsSection(WidgetRef ref, String employeeId) {
    if (employeeId.isEmpty) return const SizedBox.shrink();

    final leaveBalanceAsync = ref.watch(employeeLeaveBalanceProvider(employeeId));
    final monthlyReportAsync = ref.watch(employeeMonthlyReportProvider(employeeId));

    final leaveBalance = leaveBalanceAsync.maybeWhen(
      data: (d) {
        int total = 0;
        d.balances.forEach((key, value) {
          total += value.remaining;
        });
        return total;
      },
      orElse: () => 0,
    );
    
    // We just parse whatever we can from the report, or fallback to 0
    int daysPresent = 0;
    int lateIns = 0;
    
    monthlyReportAsync.whenData((report) {
      if (report['summary'] != null) {
        daysPresent = report['summary']['totalPresent'] ?? 0;
        lateIns = report['summary']['totalLate'] ?? 0;
      }
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth > 600;
        return GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: isDesktop ? 4 : 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isDesktop ? 1.5 : 1.15,
          children: [
            _EmployeeStatCard(
              title: 'THIS MONTH',
              count: daysPresent,
              icon: Icons.check_circle_outline,
              color: AppTheme.statBlue,
              subtitle: 'Days Present',
            ),
            _EmployeeStatCard(
              title: 'LEAVE BALANCE',
              count: leaveBalance,
              icon: Icons.flight_takeoff,
              color: AppTheme.statPurple,
              subtitle: 'Remaining leaves',
            ),
            _EmployeeStatCard(
              title: 'LATE-INS',
              count: lateIns,
              icon: Icons.access_time,
              color: AppTheme.statOrange,
              subtitle: 'This month',
            ),
            _EmployeeStatCard(
              title: 'PENDING REQ.',
              count: 0, // Mock for now since we don't have a direct endpoint for own pending
              icon: Icons.pending_actions,
              color: AppTheme.statYellow,
              subtitle: 'Awaiting approval',
            ),
          ],
        );
      },
    );
  }
}

class _AttendanceCard extends StatelessWidget {
  final bool isLoading;
  final String? statusMessage;
  final VoidCallback onCheckIn;
  final VoidCallback onCheckOut;

  const _AttendanceCard({
    required this.isLoading,
    required this.statusMessage,
    required this.onCheckIn,
    required this.onCheckOut,
  });

  @override
  Widget build(BuildContext context) {
    // For disabling, we use the status message if we can, otherwise keep both enabled.
    // e.g. "Checked in at 9:03 AM" means we can't check in again.
    final hasCheckedIn = statusMessage != null && statusMessage!.toLowerCase().contains('in at');
    final hasCheckedOut = statusMessage != null && statusMessage!.toLowerCase().contains('out at');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: isLoading
              ? const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Fetching location & saving...'),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Live Status Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          statusMessage != null ? Icons.verified_user : Icons.circle_outlined,
                          size: 16,
                          color: statusMessage != null ? Colors.green.shade600 : Colors.grey.shade500,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          statusMessage ?? 'Ready to mark attendance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: statusMessage != null ? Colors.green.shade700 : Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (hasCheckedIn || hasCheckedOut) ? null : onCheckIn,
                            icon: const Icon(Icons.login),
                            label: const Text('Check In'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              backgroundColor: AppTheme.primaryRed,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade500,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: (hasCheckedIn && !hasCheckedOut) ? onCheckOut : null,
                            icon: const Icon(Icons.logout),
                            label: const Text('Check Out'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              disabledForegroundColor: Colors.grey.shade400,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _EmployeeStatCard extends StatelessWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;

  const _EmployeeStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 4,
              child: Container(color: color),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: color, size: 20),
                  ),
                  const Spacer(),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    count.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.grey.shade500,
                      height: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryRed.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryRed, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
