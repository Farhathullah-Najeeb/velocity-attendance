import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../models/user.dart';
import '../../auth/providers/auth_provider.dart';
import '../services/admin_service.dart';

final adminStatsProvider = FutureProvider.autoDispose<Map<String, dynamic>>((
  ref,
) {
  return ref.watch(adminServiceProvider).getDashboardStats();
});

@RoutePage()
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  late Timer _timer;
  late DateTime _currentTime;

  @override
  void initState() {
    super.initState();
    _currentTime = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final statsAsync = ref.watch(adminStatsProvider);
    final isDesktop = kIsWeb && MediaQuery.of(context).size.width > 950;

    return Container(
      color: VelocityColors.background,
      child: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(adminStatsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 48),
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Top Dark Navy Greeting Banner
              _buildGreetingBanner(user, isDesktop),
              const SizedBox(height: 24),

              // 2. Main Body Grid / Stack
              statsAsync.when(
                loading: () => const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(
                      color: VelocityColors.primaryRed,
                    ),
                  ),
                ),
                error: (err, stack) => Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: VelocityColors.baseWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: VelocityColors.border),
                  ),
                  child: Center(
                    child: Text(
                      'Failed to load admin stats: $err',
                      style: const TextStyle(color: VelocityColors.danger),
                    ),
                  ),
                ),
                data: (stats) => isDesktop
                    ? _buildDesktopLayout(context, stats)
                    : _buildMobileLayout(context, stats),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // 1. TOP GREETING BANNER (DARK NAVY GRADIENT)
  // ===========================================================================
  Widget _buildGreetingBanner(User? user, bool isDesktop) {
    final userName = user?.name ?? 'Super Admin';
    final dept = (user?.department ?? 'ADMIN').toLowerCase();
    final role = user?.role ?? 'SUPER_ADMIN';

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
          // Avatar
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
                  color: const Color(0xFFE53935).withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            alignment: Alignment.center,
            child: Text(
              userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
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
          // Greeting + Name + Badges
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
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE53935).withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE53935).withValues(alpha: 0.4),
                        ),
                      ),
                      child: Text(
                        role,
                        style: const TextStyle(
                          color: Color(0xFFFCA5A5),
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
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
                            size: 13,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            dept,
                            style: const TextStyle(
                              color: Color(0xFFE2E8F0),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Portal live status pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFF10B981).withValues(alpha: 0.35),
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: Color(0xFF34D399),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Color(0xFF34D399),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'Portal Live',
                            style: TextStyle(
                              color: Color(0xFFA7F3D0),
                              fontSize: 11.5,
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
                      Row(
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
                            DateFormat('hh:mm:ss a').format(_currentTime),
                            style: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // Live Monitoring Button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  context.router.push(const LiveMonitoringRoute());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.radar_rounded, size: 18),
                label: const Text(
                  'Live Monitoring',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ===========================================================================
  // 2. DESKTOP LAYOUT (Full-width balanced layout)
  // ===========================================================================
  Widget _buildDesktopLayout(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Top Section: 2x2 Stat Cards + Live Office & Health Card on the right
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _RedesignedStatCard(
                          title: 'APPROVED EMPLOYEES',
                          count: stats['approvedEmployees'] ?? 0,
                          icon: Icons.people_rounded,
                          color: const Color(0xFF2563EB),
                          subtitle: 'Active staff members',
                          badge: 'Active',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RedesignedStatCard(
                          title: 'PENDING EMPLOYEES',
                          count: stats['pendingEmployees'] ?? 0,
                          icon: Icons.person_add_rounded,
                          color: const Color(0xFFD97706),
                          subtitle: 'Awaiting registration approval',
                          badge: '${stats['pendingEmployees'] ?? 0} Pending',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _RedesignedStatCard(
                          title: 'PENDING LEAVES',
                          count: stats['pendingLeaves'] ?? 0,
                          icon: Icons.event_note_rounded,
                          color: const Color(0xFF7C3AED),
                          subtitle: 'Leave applications to process',
                          badge: '${stats['pendingLeaves'] ?? 0} Requests',
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _RedesignedStatCard(
                          title: 'PENDING EXCEPTIONS',
                          count: stats['pendingAttendance'] ?? 0,
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFDC2626),
                          subtitle: 'Late-ins and early-outs review',
                          badge: '${stats['pendingAttendance'] ?? 0} Review',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            // Right column: portal health + live clock
            Expanded(
              flex: 3,
              child: _buildHealthCard(context, stats),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Bottom Section: Management Control Center spanning FULL WIDTH
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE53935), Color(0xFFC62828)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Management Control Center',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: VelocityColors.textPrimary,
                letterSpacing: -0.3,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: VelocityColors.primaryRedLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: VelocityColors.primaryRedBorder),
              ),
              child: const Text(
                'QUICK ACCESS HUB',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: VelocityColors.primaryRed,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2-column full-width grid of control center cards
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  _ControlCenterCard(
                    icon: Icons.people_rounded,
                    iconColor: const Color(0xFF2563EB),
                    title: 'Employee Approvals',
                    subtitle: 'Review and approve pending employee registrations.',
                    badge: '${stats['pendingEmployees'] ?? 0} Pending',
                    badgeColor: const Color(0xFFD97706),
                    onTap: () => AutoTabsRouter.of(context).setActiveIndex(1),
                  ),
                  const SizedBox(height: 12),
                  _ControlCenterCard(
                    icon: Icons.event_note_rounded,
                    iconColor: const Color(0xFF7C3AED),
                    title: 'Leave Requests',
                    subtitle: 'Process employee leave applications and balance ledger.',
                    badge: '${stats['pendingLeaves'] ?? 0} Pending',
                    badgeColor: const Color(0xFF7C3AED),
                    onTap: () => AutoTabsRouter.of(context).setActiveIndex(2),
                  ),
                  const SizedBox(height: 12),
                  _ControlCenterCard(
                    icon: Icons.warning_amber_rounded,
                    iconColor: const Color(0xFFDC2626),
                    title: 'Exception Requests',
                    subtitle: 'Review late-ins, early-outs, and attendance regularizations.',
                    badge: '${stats['pendingAttendance'] ?? 0} Exceptions',
                    badgeColor: const Color(0xFFDC2626),
                    onTap: () => AutoTabsRouter.of(context).setActiveIndex(3),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                children: [
                  _ControlCenterCard(
                    icon: Icons.settings_rounded,
                    iconColor: const Color(0xFF475569),
                    title: 'Holidays & Settings',
                    subtitle: 'Configure office hours, grace periods, geofences & holidays.',
                    badge: 'System Rules',
                    badgeColor: const Color(0xFF475569),
                    onTap: () => AutoTabsRouter.of(context).setActiveIndex(4),
                  ),
                  const SizedBox(height: 12),
                  _ControlCenterCard(
                    icon: Icons.analytics_rounded,
                    iconColor: const Color(0xFF059669),
                    title: 'Attendance Reports',
                    subtitle: 'Export comprehensive monthly, weekly logs to PDF & Excel.',
                    badge: 'Analytics',
                    badgeColor: const Color(0xFF059669),
                    onTap: () => AutoTabsRouter.of(context).setActiveIndex(5),
                  ),
                  const SizedBox(height: 12),
                  _ControlCenterCard(
                    icon: Icons.radar_rounded,
                    iconColor: const Color(0xFFE53935),
                    title: 'Live Office Monitoring',
                    subtitle: 'Real-time interactive radar and active staff floor map.',
                    badge: 'Live Radar',
                    badgeColor: const Color(0xFFE53935),
                    onTap: () => context.router.push(const LiveMonitoringRoute()),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ===========================================================================
  // 3. MOBILE LAYOUT
  // ===========================================================================
  Widget _buildMobileLayout(BuildContext context, Map<String, dynamic> stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat Cards Grid
        GridView.count(
          padding: EdgeInsets.zero,
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 0.92,
          children: [
            _RedesignedStatCard(
              title: 'APPROVED EMPLOYEES',
              count: stats['approvedEmployees'] ?? 0,
              icon: Icons.people_rounded,
              color: const Color(0xFF2563EB),
              subtitle: 'Active staff',
              badge: 'Active',
            ),
            _RedesignedStatCard(
              title: 'PENDING EMPLOYEES',
              count: stats['pendingEmployees'] ?? 0,
              icon: Icons.person_add_rounded,
              color: const Color(0xFFD97706),
              subtitle: 'Awaiting approval',
              badge: '${stats['pendingEmployees'] ?? 0}',
            ),
            _RedesignedStatCard(
              title: 'PENDING LEAVES',
              count: stats['pendingLeaves'] ?? 0,
              icon: Icons.event_note_rounded,
              color: const Color(0xFF7C3AED),
              subtitle: 'To review',
              badge: '${stats['pendingLeaves'] ?? 0}',
            ),
            _RedesignedStatCard(
              title: 'PENDING EXCEPTIONS',
              count: stats['pendingAttendance'] ?? 0,
              icon: Icons.warning_amber_rounded,
              color: const Color(0xFFDC2626),
              subtitle: 'Late-ins / early-outs',
              badge: '${stats['pendingAttendance'] ?? 0}',
            ),
          ],
        ),
        const SizedBox(height: 24),
        Column(
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
                    Icons.tune_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Management Control Center',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                    color: VelocityColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _ControlCenterCard(
              icon: Icons.people_rounded,
              iconColor: const Color(0xFF2563EB),
              title: 'Employee Approvals',
              subtitle: 'Review registration requests.',
              badge: '${stats['pendingEmployees'] ?? 0} Pending',
              badgeColor: const Color(0xFFD97706),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(1),
            ),
            const SizedBox(height: 10),
            _ControlCenterCard(
              icon: Icons.event_note_rounded,
              iconColor: const Color(0xFF7C3AED),
              title: 'Leave Requests',
              subtitle: 'Process leave applications.',
              badge: '${stats['pendingLeaves'] ?? 0} Pending',
              badgeColor: const Color(0xFF7C3AED),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(2),
            ),
            const SizedBox(height: 10),
            _ControlCenterCard(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFDC2626),
              title: 'Exception Requests',
              subtitle: 'Review late-ins and exceptions.',
              badge: '${stats['pendingAttendance'] ?? 0} Exceptions',
              badgeColor: const Color(0xFFDC2626),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(3),
            ),
            const SizedBox(height: 10),
            _ControlCenterCard(
              icon: Icons.settings_rounded,
              iconColor: const Color(0xFF475569),
              title: 'Holidays & Settings',
              subtitle: 'Configure office rules & holidays.',
              badge: 'Rules',
              badgeColor: const Color(0xFF475569),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(4),
            ),
            const SizedBox(height: 10),
            _ControlCenterCard(
              icon: Icons.analytics_rounded,
              iconColor: const Color(0xFF059669),
              title: 'Attendance Reports',
              subtitle: 'Export logs to PDF & Excel.',
              badge: 'Analytics',
              badgeColor: const Color(0xFF059669),
              onTap: () => AutoTabsRouter.of(context).setActiveIndex(5),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _buildHealthCard(context, stats),
      ],
    );
  }

  // ===========================================================================
  // 4. PORTAL HEALTH CARD
  // ===========================================================================
  Widget _buildHealthCard(BuildContext context, Map<String, dynamic> stats) {
    final isServerOnline = stats['isServerOnline'] == true;
    final settings = stats['settings'] as Map<String, dynamic>?;
    final isGeoActive = settings?['geofencingEnabled'] == true;
    final radius = settings?['allowedRadiusMeters'] ?? 0;
    final geoText = isGeoActive ? 'ACTIVE (${radius}m)' : 'INACTIVE';
    final totalPending = (stats['pendingEmployees'] ?? 0) +
        (stats['pendingLeaves'] ?? 0) +
        (stats['pendingAttendance'] ?? 0);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: VelocityColors.baseWhite,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VelocityColors.border, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Clock Icon with ambient gradient
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
              size: 28,
              color: VelocityColors.primaryRed,
            ),
          ),
          const SizedBox(height: 14),

          // Digital Clock
          Text(
            DateFormat('hh:mm:ss').format(_currentTime),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
                '${DateFormat('a').format(_currentTime).toUpperCase()} • CURRENT OFFICE TIME',
                style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: VelocityColors.textMuted,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // PORTAL HEALTH SUMMARY Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Icon(
                  Icons.monitor_heart_outlined,
                  size: 14,
                  color: VelocityColors.primaryRed,
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'PORTAL HEALTH SUMMARY',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: VelocityColors.textSubtle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Health Rows
          _HealthRow(
            icon: Icons.dns_rounded,
            label: 'Backend Server',
            value: isServerOnline ? 'ONLINE' : 'OFFLINE',
            valueColor: isServerOnline
                ? const Color(0xFF059669)
                : VelocityColors.danger,
            isPill: true,
          ),
          const Divider(height: 20, color: VelocityColors.divider),
          _HealthRow(
            icon: Icons.location_searching_rounded,
            label: 'GPS Geo-Fencing',
            value: geoText,
            valueColor: isGeoActive
                ? const Color(0xFF2563EB)
                : VelocityColors.textSubtle,
            isPill: true,
          ),
          const Divider(height: 20, color: VelocityColors.divider),
          _HealthRow(
            icon: Icons.assignment_late_outlined,
            label: 'Pending Tasks',
            value: '$totalPending Requests',
            valueColor: totalPending > 0
                ? const Color(0xFFDC2626)
                : const Color(0xFF059669),
            isPill: false,
          ),
        ],
      ),
    );
  }
}

class _RedesignedStatCard extends StatefulWidget {
  final String title;
  final int count;
  final IconData icon;
  final Color color;
  final String subtitle;
  final String badge;

  const _RedesignedStatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    required this.subtitle,
    required this.badge,
  });

  @override
  State<_RedesignedStatCard> createState() => _RedesignedStatCardState();
}

class _RedesignedStatCardState extends State<_RedesignedStatCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: VelocityColors.baseWhite,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _hovered ? widget.color.withValues(alpha: 0.5) : VelocityColors.border,
            width: _hovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _hovered
                  ? widget.color.withValues(alpha: 0.12)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: _hovered ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              // Top Accent Line
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 3.5,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [widget.color, widget.color.withValues(alpha: 0.4)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Icon Badge
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, color: widget.color, size: 18),
                        ),
                        // Badge Chip
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: widget.color.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.badge,
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              color: widget.color,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w700,
                        color: VelocityColors.textSubtle,
                        letterSpacing: 0.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.count.toString(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: VelocityColors.textPrimary,
                        letterSpacing: -0.5,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: VelocityColors.textMuted,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlCenterCard extends StatefulWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final VoidCallback onTap;

  const _ControlCenterCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.onTap,
  });

  @override
  State<_ControlCenterCard> createState() => _ControlCenterCardState();
}

class _ControlCenterCardState extends State<_ControlCenterCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          decoration: BoxDecoration(
            color: VelocityColors.baseWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _hovered
                  ? widget.iconColor.withValues(alpha: 0.5)
                  : VelocityColors.border,
              width: _hovered ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: _hovered
                    ? widget.iconColor.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.02),
                blurRadius: _hovered ? 14 : 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  widget.icon,
                  color: widget.iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: VelocityColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      style: const TextStyle(
                        color: VelocityColors.textSubtle,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: widget.badgeColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.badge,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: widget.badgeColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.chevron_right_rounded,
                color: _hovered ? widget.iconColor : VelocityColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HealthRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color valueColor;
  final bool isPill;

  const _HealthRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.valueColor,
    required this.isPill,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: VelocityColors.textSubtle),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
                color: VelocityColors.textSecondary,
              ),
            ),
          ],
        ),
        if (isPill)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: valueColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: valueColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: valueColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: valueColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: valueColor,
                letterSpacing: 0.3,
              ),
            ),
          ),
      ],
    );
  }
}
