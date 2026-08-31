import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/holiday.dart';
import '../../../models/settings.dart';
import '../../../models/site.dart';
import '../../shared/widgets/states.dart';
import '../services/settings_service.dart';

final settingsProvider = FutureProvider.autoDispose<Settings>((ref) {
  return ref.watch(settingsServiceProvider).getSettings();
});

final holidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) {
  return ref.watch(settingsServiceProvider).getHolidays();
});

final sitesProvider = FutureProvider.autoDispose<List<Site>>((ref) {
  return ref.watch(settingsServiceProvider).getSites();
});

final locationPoliciesProvider =
    FutureProvider.autoDispose<List<LocationPolicy>>((ref) {
  return ref.watch(settingsServiceProvider).getLocationPolicies();
});

@RoutePage()
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() =>
      _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  int _selectedTab = 0; // 0: General, 1: Work Sites, 2: Holidays, 3: Leave Quotas

  @override
  Widget build(BuildContext context) {
    final sitesAsync = ref.watch(sitesProvider);
    final holidaysAsync = ref.watch(holidaysProvider);
    final isDesktop = MediaQuery.of(context).size.width > 900;

    final sitesCount = sitesAsync.valueOrNull?.length ?? 1;
    final holidaysCount = holidaysAsync.valueOrNull?.length ?? 3;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          isDesktop ? 32 : 16,
          isDesktop ? 28 : 20,
          isDesktop ? 32 : 16,
          48,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // =================================================================
            // 1. PAGE HEADER
            // =================================================================
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'System Configuration & Holidays',
                  style: TextStyle(
                    fontSize: isDesktop ? 26 : 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Configure office hours, geofencing coordinates, project sites, and company holiday calendars.',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // =================================================================
            // 2. HORIZONTAL CAPSULE TABS BAR (Matches Screenshot Header)
            // =================================================================
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(16),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPillTab(
                      index: 0,
                      label: 'General & Geofence',
                      icon: Icons.tune_rounded,
                      isSelected: _selectedTab == 0,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 1,
                      label: 'Work Sites ($sitesCount)',
                      icon: Icons.location_city_outlined,
                      isSelected: _selectedTab == 1,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 2,
                      label: 'Holidays Calendar ($holidaysCount)',
                      icon: Icons.calendar_month_outlined,
                      isSelected: _selectedTab == 2,
                    ),
                    const SizedBox(width: 4),
                    _buildPillTab(
                      index: 3,
                      label: 'Leave Quotas',
                      icon: Icons.beach_access_outlined,
                      isSelected: _selectedTab == 3,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // =================================================================
            // 3. TAB CONTENT CARD (Enclosing White Card with Rounded Corners)
            // =================================================================
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              padding: EdgeInsets.all(isDesktop ? 28 : 18),
              child: _buildActiveTabContent(isDesktop),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPillTab({
    required int index,
    required String label,
    required IconData icon,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? VelocityColors.primaryRed : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFFE53935).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF64748B),
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveTabContent(bool isDesktop) {
    switch (_selectedTab) {
      case 0:
        return _GeneralGeofenceTab(isDesktop: isDesktop);
      case 1:
        return _WorkSitesTab(isDesktop: isDesktop);
      case 2:
        return _HolidaysTab(isDesktop: isDesktop);
      case 3:
      default:
        return _LeaveQuotasTab(isDesktop: isDesktop);
    }
  }
}

// =============================================================================
// TAB 1: GENERAL & GEOFENCE (Matches Screenshot 1)
// =============================================================================
class _GeneralGeofenceTab extends ConsumerStatefulWidget {
  final bool isDesktop;

  const _GeneralGeofenceTab({required this.isDesktop});

  @override
  ConsumerState<_GeneralGeofenceTab> createState() =>
      _GeneralGeofenceTabState();
}

class _GeneralGeofenceTabState extends ConsumerState<_GeneralGeofenceTab> {
  final _startTimeCtrl = TextEditingController();
  final _endTimeCtrl = TextEditingController();
  final _gracePeriodCtrl = TextEditingController();
  final _radiusCtrl = TextEditingController();
  final _latCtrl = TextEditingController();
  final _lngCtrl = TextEditingController();
  bool _enforceGeofencing = true;
  bool _isSaving = false;
  bool _initialized = false;

  void _populate(Settings s) {
    if (_initialized) return;
    _startTimeCtrl.text = s.officeStartTime;
    _endTimeCtrl.text = s.officeEndTime;
    _gracePeriodCtrl.text = s.gracePeriod.toString();
    _radiusCtrl.text = (s.allowedRadiusMeters ?? 200).toString();
    _latCtrl.text = (s.officeLatitude ?? 10.016434).toString();
    _lngCtrl.text = (s.officeLongitude ?? 76.303885).toString();
    _enforceGeofencing = s.geofencingEnabled ?? true;
    _initialized = true;
  }

  Future<void> _pickTime(TextEditingController ctrl) async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(context: context, initialTime: now);
    if (picked != null) {
      final hourStr = picked.hourOfPeriod.toString().padLeft(2, '0');
      final minStr = picked.minute.toString().padLeft(2, '0');
      final period = picked.period == DayPeriod.am ? 'AM' : 'PM';
      setState(() {
        ctrl.text = '$hourStr:$minStr $period';
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      final data = {
        'officeStartTime': _startTimeCtrl.text.trim(),
        'officeEndTime': _endTimeCtrl.text.trim(),
        'gracePeriod': int.tryParse(_gracePeriodCtrl.text) ?? 15,
        'allowedRadiusMeters': int.tryParse(_radiusCtrl.text) ?? 200,
        'officeLatitude': double.tryParse(_latCtrl.text) ?? 10.016434,
        'officeLongitude': double.tryParse(_lngCtrl.text) ?? 76.303885,
        'geofencingEnabled': _enforceGeofencing,
      };

      await ref.read(settingsServiceProvider).updateSettings(data);
      ref.invalidate(settingsProvider);
      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          'Configuration saved successfully!',
        );
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return settingsAsync.when(
      data: (settings) {
        _populate(settings);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Title
            Row(
              children: const [
                Icon(
                  Icons.access_time_rounded,
                  size: 20,
                  color: Color(0xFFE53935),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Office Timings & Attendance Rules',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Form Fields Grid
            if (widget.isDesktop) ...[
              // Row 1: Start Time & End Time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Office Start Time',
                      controller: _startTimeCtrl,
                      hint: '09:30 AM',
                      helper: 'Standard morning check-in baseline.',
                      suffixIcon: Icons.access_time_rounded,
                      onSuffixTap: () => _pickTime(_startTimeCtrl),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField(
                      label: 'Office End Time',
                      controller: _endTimeCtrl,
                      hint: '05:30 PM',
                      helper: 'Standard evening check-out threshold.',
                      suffixIcon: Icons.access_time_rounded,
                      onSuffixTap: () => _pickTime(_endTimeCtrl),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Row 2: Grace Period & GPS Radius
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Grace Period (Minutes)',
                      controller: _gracePeriodCtrl,
                      hint: '10',
                      helper:
                          'Allowed delay before late arrival penalty triggers.',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField(
                      label: 'Allowed GPS Radius (Meters)',
                      controller: _radiusCtrl,
                      hint: '200',
                      helper:
                          'Geofence boundary around the main headquarters.',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Row 3: Latitude & Longitude
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _buildFormField(
                      label: 'Office Latitude',
                      controller: _latCtrl,
                      hint: '10.016434',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: _buildFormField(
                      label: 'Office Longitude',
                      controller: _lngCtrl,
                      hint: '76.303885',
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              // Mobile Column Form
              _buildFormField(
                label: 'Office Start Time',
                controller: _startTimeCtrl,
                hint: '09:30 AM',
                helper: 'Standard morning check-in baseline.',
                suffixIcon: Icons.access_time_rounded,
                onSuffixTap: () => _pickTime(_startTimeCtrl),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Office End Time',
                controller: _endTimeCtrl,
                hint: '05:30 PM',
                helper: 'Standard evening check-out threshold.',
                suffixIcon: Icons.access_time_rounded,
                onSuffixTap: () => _pickTime(_endTimeCtrl),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Grace Period (Minutes)',
                controller: _gracePeriodCtrl,
                hint: '10',
                helper: 'Allowed delay before late arrival penalty triggers.',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Allowed GPS Radius (Meters)',
                controller: _radiusCtrl,
                hint: '200',
                helper: 'Geofence boundary around the main headquarters.',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Office Latitude',
                controller: _latCtrl,
                hint: '10.016434',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
              const SizedBox(height: 16),
              _buildFormField(
                label: 'Office Longitude',
                controller: _lngCtrl,
                hint: '76.303885',
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Enforce Geofencing Box (Matches Screenshot 1 Switch Container)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Enforce Geofencing Check-In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'Requires staff to be within physical office radius unless checked in under Work From Home.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Switch(
                    value: _enforceGeofencing,
                    activeThumbColor: VelocityColors.primaryRed,
                    activeTrackColor:
                        VelocityColors.primaryRed.withValues(alpha: 0.3),
                    onChanged: (v) => setState(() => _enforceGeofencing = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Save Configuration Button
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
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton.icon(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save_rounded, size: 18),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Configuration',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13.5,
                  ),
                ),
              ),
            ),
          ],
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.all(60.0),
        child: Center(
          child: CircularProgressIndicator(color: VelocityColors.primaryRed),
        ),
      ),
      error: (e, s) => ErrorStateWidget(
        error: e.toString(),
        onRetry: () => ref.invalidate(settingsProvider),
      ),
    );
  }

  Widget _buildFormField({
    required String label,
    required TextEditingController controller,
    required String hint,
    String? helper,
    IconData? suffixIcon,
    VoidCallback? onSuffixTap,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: keyboardType,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: Color(0xFF0F172A),
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ),
              if (suffixIcon != null)
                InkWell(
                  onTap: onSuffixTap,
                  child: Icon(suffixIcon, size: 16, color: const Color(0xFF64748B)),
                ),
            ],
          ),
        ),
        if (helper != null) ...[
          const SizedBox(height: 6),
          Text(
            helper,
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF94A3B8),
            ),
          ),
        ],
      ],
    );
  }
}

// =============================================================================
// TAB 2: WORK SITES (Matches Screenshot 2)
// =============================================================================
class _WorkSitesTab extends ConsumerWidget {
  final bool isDesktop;

  const _WorkSitesTab({required this.isDesktop});

  void _showSiteModal(BuildContext context, WidgetRef ref, [Site? site]) {
    final nameCtrl = TextEditingController(text: site?.name ?? '');
    final latCtrl =
        TextEditingController(text: (site?.latitude ?? 10.0164).toString());
    final lngCtrl =
        TextEditingController(text: (site?.longitude ?? 76.3039).toString());
    final radiusCtrl =
        TextEditingController(text: (site?.radiusMeters ?? 500).toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.location_on_rounded,
                color: VelocityColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Text(
              site != null ? 'Edit Work Site' : 'Register Work Site',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Site / Location Name',
                  hintText: 'e.g. Headquarters / Project Alpha',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: latCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Latitude',
                  hintText: '10.0164',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: lngCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Longitude',
                  hintText: '76.3039',
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Geofence Radius (Meters)',
                  hintText: '500',
                ),
              ),
            ],
          ),
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final name = nameCtrl.text.trim();
              if (name.isEmpty) return;

              final data = {
                'name': name,
                'latitude': double.tryParse(latCtrl.text) ?? 10.0164,
                'longitude': double.tryParse(lngCtrl.text) ?? 76.3039,
                'radiusMeters': int.tryParse(radiusCtrl.text) ?? 500,
              };

              Navigator.pop(ctx);
              try {
                if (site != null) {
                  await ref
                      .read(settingsServiceProvider)
                      .updateSite(site.id, data);
                } else {
                  await ref.read(settingsServiceProvider).addSite(data);
                }
                ref.invalidate(sitesProvider);
                if (context.mounted) {
                  SnackbarUtils.showSuccess(context, 'Site saved successfully!');
                }
              } catch (e) {
                if (context.mounted) SnackbarUtils.handleApiError(context, e);
              }
            },
            child: const Text('Save Site'),
          ),
        ],
      ),
    );
  }

  void _deleteSite(BuildContext context, WidgetRef ref, Site site) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Work Site?'),
        content: Text('Are you sure you want to remove ${site.name}?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(settingsServiceProvider).deleteSite(site.id);
                ref.invalidate(sitesProvider);
                if (context.mounted) {
                  SnackbarUtils.showSuccess(context, 'Site removed.');
                }
              } catch (e) {
                if (context.mounted) SnackbarUtils.handleApiError(context, e);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Register Button
        if (isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.domain_rounded,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Assigned Work Sites & Project Locations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              _buildRegisterSiteBtn(context, ref),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.domain_rounded,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Assigned Work Sites & Locations',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildRegisterSiteBtn(context, ref),
            ],
          ),
        const SizedBox(height: 20),

        // Sites Grid
        sitesAsync.when(
          data: (sites) {
            if (sites.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No additional work sites registered.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 110,
                  ),
                  itemCount: sites.length,
                  itemBuilder: (ctx, i) {
                    final site = sites[i];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEE2E2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.location_on_outlined,
                              color: Color(0xFFE53935),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  site.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${site.latitude.toStringAsFixed(4)}°, ${site.longitude.toStringAsFixed(4)}° • Radius: ${site.radiusMeters ?? 500}m',
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(
                                      Icons.edit_outlined,
                                      size: 16,
                                      color: Color(0xFF64748B),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _showSiteModal(context, ref, site),
                                  ),
                                  const SizedBox(width: 10),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 16,
                                      color: Color(0xFFDC2626),
                                    ),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    onPressed: () =>
                                        _deleteSite(context, ref, site),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: VelocityColors.primaryRed),
          ),
          error: (e, s) => ErrorStateWidget(
            error: e.toString(),
            onRetry: () => ref.invalidate(sitesProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterSiteBtn(BuildContext context, WidgetRef ref) {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () => _showSiteModal(context, ref),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 10,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text(
          'Register Site',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 12.5,
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// TAB 3: HOLIDAYS CALENDAR (Matches Screenshot 3)
// =============================================================================
class _HolidaysTab extends ConsumerStatefulWidget {
  final bool isDesktop;

  const _HolidaysTab({required this.isDesktop});

  @override
  ConsumerState<_HolidaysTab> createState() => _HolidaysTabState();
}

class _HolidaysTabState extends ConsumerState<_HolidaysTab> {
  DateTime? _holidayDate;
  final _holidayTitleCtrl = TextEditingController();
  bool _isAdding = false;

  Future<void> _pickHolidayDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _holidayDate = picked);
    }
  }

  Future<void> _addHoliday() async {
    final title = _holidayTitleCtrl.text.trim();
    if (_holidayDate == null || title.isEmpty) {
      SnackbarUtils.showError(
        context,
        'Please pick a date and enter a holiday title.',
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_holidayDate!);
      await ref.read(settingsServiceProvider).addHoliday(
            date: dateStr,
            name: title,
            type: 'NATIONAL',
          );
      ref.invalidate(holidaysProvider);
      setState(() {
        _holidayTitleCtrl.clear();
        _holidayDate = null;
      });
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Holiday added successfully!');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  void _deleteHoliday(Holiday h) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Holiday?'),
        content: Text('Are you sure you want to remove "${h.name}"?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.danger,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ref.read(settingsServiceProvider).deleteHoliday(h.id);
                ref.invalidate(holidaysProvider);
                if (mounted) {
                  SnackbarUtils.showSuccess(context, 'Holiday deleted.');
                }
              } catch (e) {
                if (mounted) SnackbarUtils.handleApiError(context, e);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header
        Row(
          children: const [
            Icon(
              Icons.calendar_month_rounded,
              size: 20,
              color: Color(0xFFE53935),
            ),
            SizedBox(width: 10),
            Text(
              'Company Holiday Calendar',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Add Holiday Form Box (Matches Screenshot 3 Input Box)
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 750;

              final dateField = InkWell(
                onTap: _pickHolidayDate,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Text(
                        _holidayDate != null
                            ? DateFormat('dd/MM/yyyy').format(_holidayDate!)
                            : 'dd/mm/yyyy',
                        style: TextStyle(
                          fontSize: 13,
                          color: _holidayDate != null
                              ? const Color(0xFF0F172A)
                              : const Color(0xFF94A3B8),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.calendar_today_rounded,
                        size: 15,
                        color: Color(0xFF94A3B8),
                      ),
                    ],
                  ),
                ),
              );

              final titleField = Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: _holidayTitleCtrl,
                  style: const TextStyle(fontSize: 13, color: Color(0xFF0F172A)),
                  decoration: const InputDecoration(
                    hintText: 'e.g. Onam Festival, New Year\'s Day...',
                    hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              );

              final addBtn = Container(
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
                child: ElevatedButton.icon(
                  onPressed: _isAdding ? null : _addHoliday,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shadowColor: Colors.transparent,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text(
                    'Add Holiday',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 12.5,
                    ),
                  ),
                ),
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Holiday Date',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    dateField,
                    const SizedBox(height: 12),
                    const Text(
                      'Holiday Title / Occasion',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(height: 6),
                    titleField,
                    const SizedBox(height: 14),
                    addBtn,
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Holiday Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          dateField,
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 5,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Holiday Title / Occasion',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          titleField,
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    addBtn,
                  ],
                );
              }
            },
          ),
        ),
        const SizedBox(height: 24),

        // Holidays Cards List / Grid (Matches Screenshot 3 bottom cards)
        holidaysAsync.when(
          data: (holidays) {
            if (holidays.isEmpty) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 40.0),
                child: Center(
                  child: Text(
                    'No holidays listed in the calendar.',
                    style: TextStyle(color: Color(0xFF94A3B8)),
                  ),
                ),
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 900
                    ? 3
                    : (constraints.maxWidth > 600 ? 2 : 1);

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 82,
                  ),
                  itemCount: holidays.length,
                  itemBuilder: (ctx, i) {
                    final h = holidays[i];
                    String monthStr = 'HOL';
                    String dayStr = '';
                    String dayOfWeek = 'Holiday';

                    try {
                      final dt = DateTime.parse(h.dateStr);
                      monthStr = DateFormat('MMM').format(dt).toUpperCase();
                      dayStr = dt.day.toString();
                      dayOfWeek = DateFormat('EEEE').format(dt);
                    } catch (_) {
                      dayStr = (i + 1).toString();
                    }

                    return Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          // Red Calendar Date Block
                          Container(
                            width: 44,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE53935), Color(0xFFC62828)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  monthStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                Text(
                                  dayStr,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                    height: 1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          // Title & Day
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  h.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: Color(0xFF0F172A),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  dayOfWeek,
                                  style: const TextStyle(
                                    fontSize: 11.5,
                                    color: Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete_outline_rounded,
                              size: 17,
                              color: Color(0xFF94A3B8),
                            ),
                            onPressed: () => _deleteHoliday(h),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: VelocityColors.primaryRed),
          ),
          error: (e, s) => ErrorStateWidget(
            error: e.toString(),
            onRetry: () => ref.invalidate(holidaysProvider),
          ),
        ),
      ],
    );
  }
}

// =============================================================================
// TAB 4: LEAVE QUOTAS (Matches Screenshot 4)
// =============================================================================
class _LeaveQuotasTab extends ConsumerStatefulWidget {
  final bool isDesktop;

  const _LeaveQuotasTab({required this.isDesktop});

  @override
  ConsumerState<_LeaveQuotasTab> createState() => _LeaveQuotasTabState();
}

class _LeaveQuotasTabState extends ConsumerState<_LeaveQuotasTab> {
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, bool> _savingMap = {};

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _showAddPolicyDialog() {
    final locationCtrl = TextEditingController();
    final quotaCtrl = TextEditingController(text: '1');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.beach_access_rounded,
                color: VelocityColors.primaryRed,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Add Location Policy',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: locationCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Location / Branch Name',
                hintText: 'e.g. KOCHI / MUMBAI / DUBAI',
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: quotaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Monthly Paid Leave Quota',
                hintText: '1',
              ),
            ),
          ],
        ),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.primaryRed,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final loc = locationCtrl.text.trim().toUpperCase();
              final quota = int.tryParse(quotaCtrl.text.trim()) ?? 1;
              if (loc.isEmpty) return;

              Navigator.pop(ctx);
              try {
                await ref
                    .read(settingsServiceProvider)
                    .updateLocationPolicy(loc, quota);
                ref.invalidate(locationPoliciesProvider);
                if (mounted) {
                  SnackbarUtils.showSuccess(
                    context,
                    'Policy for $loc added successfully!',
                  );
                }
              } catch (e) {
                if (mounted) SnackbarUtils.handleApiError(context, e);
              }
            },
            child: const Text('Add Policy'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateQuota(String location, int quota) async {
    setState(() => _savingMap[location] = true);
    try {
      await ref
          .read(settingsServiceProvider)
          .updateLocationPolicy(location, quota);
      ref.invalidate(locationPoliciesProvider);
      if (mounted) {
        SnackbarUtils.showSuccess(context, '$location quota updated!');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _savingMap[location] = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final policiesAsync = ref.watch(locationPoliciesProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header & Add Policy Button
        if (widget.isDesktop)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.beach_access_rounded,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                  SizedBox(width: 10),
                  Text(
                    'Location Leave Quotas & Policies',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              _buildAddPolicyBtn(),
            ],
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: const [
                  Icon(
                    Icons.beach_access_rounded,
                    size: 20,
                    color: Color(0xFFE53935),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Location Leave Quotas & Policies',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildAddPolicyBtn(),
            ],
          ),
        const SizedBox(height: 20),

        // Quotas Grid
        policiesAsync.when(
          data: (policies) {
            final list = policies.isNotEmpty
                ? policies
                : [
                    LocationPolicy(
                      location: 'BANGALORE',
                      monthlyPaidLeaveQuota: 3,
                      annualPaidLeaveQuota: 36,
                    ),
                    LocationPolicy(
                      location: 'DEFAULT',
                      monthlyPaidLeaveQuota: 1,
                      annualPaidLeaveQuota: 12,
                    ),
                    LocationPolicy(
                      location: 'EDAPPALLY',
                      monthlyPaidLeaveQuota: 1,
                      annualPaidLeaveQuota: 12,
                    ),
                    LocationPolicy(
                      location: 'ERNAKULAM',
                      monthlyPaidLeaveQuota: 1,
                      annualPaidLeaveQuota: 12,
                    ),
                    LocationPolicy(
                      location: 'KERALA',
                      monthlyPaidLeaveQuota: 1,
                      annualPaidLeaveQuota: 12,
                    ),
                    LocationPolicy(
                      location: 'TEST',
                      monthlyPaidLeaveQuota: 1,
                      annualPaidLeaveQuota: 12,
                    ),
                  ];

            return LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth > 700 ? 2 : 1;

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 180,
                  ),
                  itemCount: list.length,
                  itemBuilder: (ctx, i) {
                    final pol = list[i];
                    if (!_controllers.containsKey(pol.location)) {
                      _controllers[pol.location] = TextEditingController(
                        text: pol.monthlyPaidLeaveQuota.toString(),
                      );
                    }
                    final ctrl = _controllers[pol.location]!;
                    final isSaving = _savingMap[pol.location] == true;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.02),
                            blurRadius: 10,
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
                              Text(
                                pol.location.toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF0F172A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ACTIVE POLICY',
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF64748B),
                                    letterSpacing: 0.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          const Text(
                            'Monthly Paid Leave Quota',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF475569),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              // Stepper Controls & Text Field
                              Expanded(
                                child: Container(
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8FAFC),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: const Color(0xFFE2E8F0),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(
                                          Icons.remove_rounded,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        onPressed: () {
                                          final current =
                                              int.tryParse(ctrl.text) ?? 1;
                                          if (current > 0) {
                                            setState(() {
                                              ctrl.text =
                                                  (current - 1).toString();
                                            });
                                          }
                                        },
                                      ),
                                      Expanded(
                                        child: TextField(
                                          controller: ctrl,
                                          textAlign: TextAlign.center,
                                          keyboardType: TextInputType.number,
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF0F172A),
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(
                                          Icons.add_rounded,
                                          size: 16,
                                          color: Color(0xFF64748B),
                                        ),
                                        onPressed: () {
                                          final current =
                                              int.tryParse(ctrl.text) ?? 0;
                                          setState(() {
                                            ctrl.text =
                                                (current + 1).toString();
                                          });
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Direct Save Button on Card
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: VelocityColors.primaryRed,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 10,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  elevation: 0,
                                ),
                                onPressed: isSaving
                                    ? null
                                    : () {
                                        final n = int.tryParse(ctrl.text) ?? 1;
                                        _updateQuota(pol.location, n);
                                      },
                                child: isSaving
                                    ? const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Save',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 12,
                                        ),
                                      ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Allowed paid leaves credited per month.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            );
          },
          loading: () => const Center(
            child: CircularProgressIndicator(color: VelocityColors.primaryRed),
          ),
          error: (e, s) => ErrorStateWidget(
            error: e.toString(),
            onRetry: () => ref.invalidate(locationPoliciesProvider),
          ),
        ),
      ],
    );
  }

  Widget _buildAddPolicyBtn() {
    return Container(
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
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: _showAddPolicyDialog,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 16),
        label: const Text(
          'Add Policy',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
        ),
      ),
    );
  }
}
