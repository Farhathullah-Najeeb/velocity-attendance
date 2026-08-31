import 'package:auto_route/auto_route.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../core/router/app_router.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../services/overtime_service.dart';
import '../../../models/overtime.dart';
import '../../shared/widgets/states.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/theme/velocity_colors.dart';

final myOvertimeProvider =
    FutureProvider.autoDispose<List<Overtime>>((ref) async {
      final user = ref.watch(authProvider).user;
      if (user == null) return [];
      return ref
          .watch(overtimeServiceProvider)
          .getMyOvertime(employeeId: user.id);
    });

@RoutePage()
class EmployeeOvertimeScreen extends ConsumerWidget {
  const EmployeeOvertimeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(myOvertimeProvider);
    final isDesktop = kIsWeb && MediaQuery.of(context).size.width > 800;

    return AppScaffold(
      body: RefreshIndicator(
        color: VelocityColors.primaryRed,
        onRefresh: () async {
          ref.invalidate(myOvertimeProvider);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  isDesktop ? 24 : 16,
                  isDesktop ? 20 : 16,
                  isDesktop ? 24 : 16,
                  isDesktop ? 24 : 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isDesktop ? 'Overtime Requests' : 'My Overtime',
                          style: TextStyle(
                            fontSize: isDesktop ? 26 : 22,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Track overtime hours, review approval status, and submit new requests.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    if (isDesktop)
                      ElevatedButton.icon(
                        onPressed: () {
                          context.router.push(const RequestOvertimeRoute());
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: VelocityColors.primaryRed,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text(
                          'Request Overtime',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            asyncData.when(
              loading: () => const SliverFillRemaining(
                child: LoadingStateWidget(),
              ),
              error: (err, _) => SliverFillRemaining(
                child: ErrorStateWidget(
                  error: err.toString(),
                  onRetry: () => ref.invalidate(myOvertimeProvider),
                ),
              ),
              data: (records) {
                if (records.isEmpty) {
                  return const SliverFillRemaining(
                    child: EmptyStateWidget(
                      icon: Icons.timer_off_outlined,
                      title: 'No Overtime Records',
                      message:
                          'You have not submitted any overtime requests yet.',
                    ),
                  );
                }

                if (isDesktop) {
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                    sliver: SliverToBoxAdapter(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.0,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Table Header Row
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                color: const Color(0xFFF8FAFC),
                                child: Row(
                                  children: const [
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'DATE',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'DURATION',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: Text(
                                        'REASON',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        'STATUS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 3,
                                      child: Text(
                                        'REMARKS',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.5,
                                          color: Color(0xFF64748B),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: records.length,
                                separatorBuilder: (ctx, i) => const Divider(
                                  height: 1,
                                  color: Color(0xFFF1F5F9),
                                ),
                                itemBuilder: (context, index) {
                                  final record = records[index];
                                  final hours =
                                      record.overtimeMinutes ~/ 60;
                                  final minutes =
                                      record.overtimeMinutes % 60;
                                  final durationLabel = hours > 0
                                      ? '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}'
                                      : '$minutes min';

                                  String formattedDate = record.dateStr;
                                  try {
                                    final parsed =
                                        DateFormat('yyyy-MM-dd')
                                            .parse(record.dateStr);
                                    formattedDate =
                                        DateFormat('dd MMM yyyy')
                                            .format(parsed);
                                  } catch (_) {}

                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 20,
                                      vertical: 16,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            formattedDate,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            durationLabel,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                              color: Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 4,
                                          child: Text(
                                            record.reason ?? '—',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF334155),
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Align(
                                            alignment: Alignment.centerLeft,
                                            child: _StatusBadge(
                                              status: record.status,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            record.remarks?.isNotEmpty == true
                                                ? record.remarks!
                                                : '—',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              color: Color(0xFF94A3B8),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                // Mobile
                return SliverPadding(
                  padding: AppScaffold.getScrollPadding(
                    context,
                    basePadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) =>
                          _OvertimeCard(record: records[index]),
                      childCount: records.length,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.router.push(const RequestOvertimeRoute());
              },
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add),
              label: const Text(
                'Request Overtime',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color textColor;
    Color borderColor;

    switch (status.toUpperCase()) {
      case 'APPROVED':
        bgColor = const Color(0xFFD1FAE5);
        textColor = const Color(0xFF059669);
        borderColor = const Color(0xFFA7F3D0);
        break;
      case 'REJECTED':
        bgColor = const Color(0xFFFEE2E2);
        textColor = const Color(0xFFDC2626);
        borderColor = const Color(0xFFFECACA);
        break;
      default:
        bgColor = const Color(0xFFFEF3C7);
        textColor = const Color(0xFFD97706);
        borderColor = const Color(0xFFFDE68A);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}

class _OvertimeCard extends StatelessWidget {
  final Overtime record;

  const _OvertimeCard({required this.record});

  @override
  Widget build(BuildContext context) {
    String formattedDate = record.dateStr;
    try {
      final parsed = DateFormat('yyyy-MM-dd').parse(record.dateStr);
      formattedDate = DateFormat('dd MMM yyyy').format(parsed);
    } catch (_) {}

    final hours = record.overtimeMinutes ~/ 60;
    final minutes = record.overtimeMinutes % 60;
    final durationLabel = hours > 0
        ? '$hours hr${hours > 1 ? 's' : ''} ${minutes > 0 ? '$minutes min' : ''}'
        : '$minutes min';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 14,
                    color: Color(0xFF64748B),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    formattedDate,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              _StatusBadge(status: record.status),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: VelocityColors.primaryRed.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.timer_outlined,
                  size: 16,
                  color: VelocityColors.primaryRed,
                ),
                const SizedBox(width: 8),
                Text(
                  durationLabel,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: VelocityColors.primaryRed,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          if (record.reason != null && record.reason!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              record.reason!,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF334155),
              ),
            ),
          ],
          if (record.remarks != null && record.remarks!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.comment_outlined,
                    size: 14,
                    color: Color(0xFF94A3B8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      record.remarks!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
