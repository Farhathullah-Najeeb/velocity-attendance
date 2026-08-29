import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/velocity_colors.dart';
import '../../../core/utils/error_handler.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../models/holiday.dart';
import '../../../models/settings.dart';
import '../../../models/site.dart';
import '../../shared/widgets/app_scaffold.dart';
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
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              color: Theme.of(context).colorScheme.surface,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: Theme.of(context).colorScheme.primary,
                unselectedLabelColor: Theme.of(context).hintColor,
                indicatorColor: Theme.of(context).colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.schedule_outlined, size: 18),
                    text: 'Office & Timing',
                  ),
                  Tab(
                    icon: Icon(Icons.celebration_outlined, size: 18),
                    text: 'Holidays',
                  ),
                  Tab(
                    icon: Icon(Icons.location_city_outlined, size: 18),
                    text: 'Work Sites',
                  ),
                  Tab(
                    icon: Icon(Icons.policy_outlined, size: 18),
                    text: 'Leave Policies',
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            const Expanded(
              child: TabBarView(
                children: [
                  _OfficeTimingTab(),
                  _HolidaysTab(),
                  _WorkSitesTab(),
                  _LocationPoliciesTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 1. OFFICE TIMING & GEOFENCE TAB
// ==========================================
class _OfficeTimingTab extends ConsumerWidget {
  const _OfficeTimingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(settingsProvider),
      child: settingsAsync.when(
        data: (settings) => _OfficeTimingForm(settings: settings),
        loading: () => const LoadingStateWidget(),
        error: (e, _) => ErrorStateWidget(
          error: ErrorHandler.getUserMessage(e),
          onRetry: () => ref.invalidate(settingsProvider),
        ),
      ),
    );
  }
}

class _OfficeTimingForm extends ConsumerStatefulWidget {
  final Settings settings;
  const _OfficeTimingForm({required this.settings});

  @override
  ConsumerState<_OfficeTimingForm> createState() => _OfficeTimingFormState();
}

class _OfficeTimingFormState extends ConsumerState<_OfficeTimingForm> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _graceCtrl;
  late TextEditingController _radiusCtrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.settings.officeStartTime);
    _endCtrl = TextEditingController(text: widget.settings.officeEndTime);
    _graceCtrl = TextEditingController(
      text: widget.settings.gracePeriod.toString(),
    );
    _radiusCtrl = TextEditingController(
      text: widget.settings.allowedRadiusMeters?.toString() ?? '500',
    );
  }

  @override
  void dispose() {
    _startCtrl.dispose();
    _endCtrl.dispose();
    _graceCtrl.dispose();
    _radiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectTime(TextEditingController ctrl) async {
    TimeOfDay initial = const TimeOfDay(hour: 9, minute: 0);
    if (ctrl.text.contains(':')) {
      final parts = ctrl.text.split(':');
      initial = TimeOfDay(
        hour: int.tryParse(parts[0]) ?? 9,
        minute: int.tryParse(parts[1]) ?? 0,
      );
    }
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
    );
    if (picked != null) {
      final hour = picked.hour.toString().padLeft(2, '0');
      final minute = picked.minute.toString().padLeft(2, '0');
      setState(() => ctrl.text = '$hour:$minute');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final payload = {
        'officeStartTime': _startCtrl.text.trim(),
        'officeEndTime': _endCtrl.text.trim(),
        'gracePeriod': int.tryParse(_graceCtrl.text.trim()) ?? 15,
        'allowedRadiusMeters': int.tryParse(_radiusCtrl.text.trim()) ?? 500,
      };
      await ref.read(settingsServiceProvider).updateSettings(payload);
      ref.invalidate(settingsProvider);
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Settings updated successfully');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(
        context,
        basePadding: const EdgeInsets.all(16.0),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.timer_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            'Shift Hours & Attendance Rules',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configure official shift timings and late arrival thresholds for the organisation.',
                      style: TextStyle(
                        color: Theme.of(context).hintColor,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _startCtrl,
                            readOnly: true,
                            onTap: () => _selectTime(_startCtrl),
                            decoration: const InputDecoration(
                              labelText: 'Shift Start Time',
                              prefixIcon: Icon(Icons.wb_sunny_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _endCtrl,
                            readOnly: true,
                            onTap: () => _selectTime(_endCtrl),
                            decoration: const InputDecoration(
                              labelText: 'Shift End Time',
                              prefixIcon: Icon(Icons.nightlight_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _graceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Grace Period (Mins)',
                              prefixIcon: Icon(Icons.timelapse_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _radiusCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Allowed Radius (Meters)',
                              prefixIcon: Icon(Icons.radar_outlined),
                            ),
                            validator: (v) =>
                                v == null || v.isEmpty ? 'Required' : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.primary,
                          foregroundColor:
                              Theme.of(context).colorScheme.onPrimary,
                        ),
                        onPressed: _isLoading ? null : _save,
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text('Save Shift Settings'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 2. HOLIDAYS TAB
// ==========================================
class _HolidaysTab extends ConsumerStatefulWidget {
  const _HolidaysTab();

  @override
  ConsumerState<_HolidaysTab> createState() => _HolidaysTabState();
}

class _HolidaysTabState extends ConsumerState<_HolidaysTab> {
  final _dateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _customLocCtrl = TextEditingController();
  String _type = 'NATIONAL'; // 'NATIONAL', 'REGIONAL', 'BRANCH'
  final List<String> _selectedLocations = [];
  String _filterLocation = 'ALL';
  bool _isAdding = false;

  @override
  void dispose() {
    _dateCtrl.dispose();
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _customLocCtrl.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _dateCtrl.text = DateFormat('yyyy-MM-dd').format(picked));
    }
  }

  void _addCustomLocation() {
    final text = _customLocCtrl.text.trim();
    if (text.isNotEmpty && !_selectedLocations.contains(text)) {
      setState(() {
        _selectedLocations.add(text);
        _customLocCtrl.clear();
      });
    }
  }

  Future<void> _addHoliday() async {
    if (_dateCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
      SnackbarUtils.showError(context, 'Please enter holiday name and date');
      return;
    }

    if (_type != 'NATIONAL' && _selectedLocations.isEmpty) {
      SnackbarUtils.showError(
        context,
        'Please select at least one branch/location for $_type holiday',
      );
      return;
    }

    setState(() => _isAdding = true);
    try {
      final applicable = _type == 'NATIONAL' ? <String>[] : _selectedLocations;
      await ref.read(settingsServiceProvider).addHoliday(
            date: _dateCtrl.text.trim(),
            name: _nameCtrl.text.trim(),
            type: _type,
            applicableLocations: applicable,
            description: _descCtrl.text.trim().isNotEmpty
                ? _descCtrl.text.trim()
                : null,
          );
      _dateCtrl.clear();
      _nameCtrl.clear();
      _descCtrl.clear();
      _customLocCtrl.clear();
      setState(() {
        _type = 'NATIONAL';
        _selectedLocations.clear();
      });
      ref.invalidate(holidaysProvider);
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Holiday added successfully');
      }
    } catch (e) {
      if (mounted) SnackbarUtils.handleApiError(context, e);
    } finally {
      if (mounted) setState(() => _isAdding = false);
    }
  }

  Future<void> _deleteHoliday(Holiday holiday) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Holiday'),
        content: Text('Are you sure you want to delete "${holiday.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(settingsServiceProvider).deleteHoliday(holiday.id);
        ref.invalidate(holidaysProvider);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Holiday deleted successfully');
        }
      } catch (e) {
        if (mounted) SnackbarUtils.handleApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final holidaysAsync = ref.watch(holidaysProvider);
    final sitesAsync = ref.watch(sitesProvider);
    final policiesAsync = ref.watch(locationPoliciesProvider);

    // Extract available location names
    final Set<String> defaultLocations = {
      'Kochi',
      'Trivandrum',
      'Calicut',
      'Bangalore',
      'Dubai',
      'Remote',
    };
    sitesAsync.whenData((sites) {
      for (final s in sites) {
        if (s.name.isNotEmpty) defaultLocations.add(s.name);
      }
    });
    policiesAsync.whenData((policies) {
      for (final p in policies) {
        if (p.location.isNotEmpty) defaultLocations.add(p.location);
      }
    });

    return SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(
        context,
        basePadding: const EdgeInsets.all(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Add Holiday Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Add New Holiday',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Holiday Name (e.g. Republic Day / Onam)',
                      prefixIcon: Icon(Icons.celebration_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _dateCtrl,
                          readOnly: true,
                          onTap: _selectDate,
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            hintText: 'YYYY-MM-DD',
                            prefixIcon: Icon(Icons.calendar_today_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _type,
                          isExpanded: true,
                          decoration: const InputDecoration(
                            labelText: 'Scope / Type',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'NATIONAL',
                              child: Text(
                                'National',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'REGIONAL',
                              child: Text(
                                'Regional',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'BRANCH',
                              child: Text(
                                'Branch',
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _type = v;
                                if (v == 'NATIONAL') _selectedLocations.clear();
                              });
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _descCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (Optional)',
                      hintText: 'e.g. State holiday applicable for Kerala branches',
                      prefixIcon: Icon(Icons.description_outlined),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location Selector for REGIONAL / BRANCH
                  if (_type == 'NATIONAL') ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.public, color: Colors.green.shade800, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'National Holiday: Automatically applies to all branches and staff nationwide.',
                              style: TextStyle(
                                color: Colors.green.shade900,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else ...[
                    Text(
                      _type == 'REGIONAL'
                          ? 'SELECT REGIONAL LOCATIONS / BRANCHES:'
                          : 'SELECT APPLICABLE BRANCH:',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: defaultLocations.map((loc) {
                        final isSelected = _selectedLocations.contains(loc);
                        return FilterChip(
                          label: Text('📍 $loc'),
                          selected: isSelected,
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                          onSelected: (selected) {
                            setState(() {
                              if (_type == 'BRANCH') {
                                _selectedLocations.clear();
                                if (selected) _selectedLocations.add(loc);
                              } else {
                                if (selected) {
                                  _selectedLocations.add(loc);
                                } else {
                                  _selectedLocations.remove(loc);
                                }
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customLocCtrl,
                            decoration: const InputDecoration(
                              hintText: 'Add custom location name...',
                              isDense: true,
                              prefixIcon: Icon(Icons.add_location_alt_outlined, size: 18),
                            ),
                            onSubmitted: (_) => _addCustomLocation(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton(
                          onPressed: _addCustomLocation,
                          child: const Text('Add'),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 18),

                  SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            Theme.of(context).colorScheme.primary,
                        foregroundColor:
                            Theme.of(context).colorScheme.onPrimary,
                      ),
                      icon: _isAdding
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.add),
                      label: const Text('Add Holiday'),
                      onPressed: _isAdding ? null : _addHoliday,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Holidays List Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_month_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Declared Company Holidays',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Filter by Location Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('All'),
                          selected: _filterLocation == 'ALL',
                          selectedColor: Theme.of(context).colorScheme.primary,
                          checkmarkColor: Colors.white,
                          labelStyle: TextStyle(
                            color: _filterLocation == 'ALL'
                                ? Colors.white
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _filterLocation = 'ALL');
                            }
                          },
                        ),
                        const SizedBox(width: 6),
                        ...defaultLocations.map((loc) {
                          final isLocSelected = _filterLocation == loc;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: ChoiceChip(
                              label: Text(loc),
                              selected: isLocSelected,
                              selectedColor: Theme.of(context).colorScheme.primary,
                              checkmarkColor: Colors.white,
                              labelStyle: TextStyle(
                                color: isLocSelected
                                    ? Colors.white
                                    : Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                              onSelected: (selected) {
                                setState(() {
                                  _filterLocation = selected ? loc : 'ALL';
                                });
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  holidaysAsync.when(
                    data: (holidays) {
                      final filtered = holidays.where((h) {
                        if (_filterLocation == 'ALL') return true;
                        return h.appliesTo(_filterLocation);
                      }).toList();

                      if (filtered.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 24),
                          child: Center(
                            child: Text(
                              'No declared holidays found for selected location.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        );
                      }
                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final h = filtered[index];
                          final typeColor = h.type == 'NATIONAL'
                              ? Colors.green
                              : (h.type == 'REGIONAL'
                                  ? Colors.deepOrange
                                  : Colors.purple);

                          final locText = h.isNational
                              ? '🌐 All Locations (National)'
                              : '📍 ${h.applicableLocations.join(", ")}';

                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: typeColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.event,
                                color: typeColor,
                                size: 20,
                              ),
                            ),
                            title: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    h.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: typeColor.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: typeColor.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Text(
                                    h.type,
                                    style: TextStyle(
                                      color: typeColor,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const SizedBox(height: 4),
                                Text(
                                  h.dateStr.isNotEmpty ? h.dateStr : h.date,
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  locText,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                if (h.description != null &&
                                    h.description!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    h.description!,
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: 11,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _deleteHoliday(h),
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          ErrorHandler.getUserMessage(e),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 3. WORK SITES TAB
// ==========================================
class _WorkSitesTab extends ConsumerWidget {
  const _WorkSitesTab();

  void _showSiteModal(
    BuildContext context,
    WidgetRef ref, [
    Site? site,
  ]) {
    final nameCtrl = TextEditingController(text: site?.name);
    final latCtrl = TextEditingController(
      text: site?.latitude.toString() ?? '',
    );
    final lngCtrl = TextEditingController(
      text: site?.longitude.toString() ?? '',
    );
    final radiusCtrl = TextEditingController(
      text: site?.radiusMeters?.toString() ?? '500',
    );
    final addressCtrl = TextEditingController(text: site?.address ?? '');
    final officeStartCtrl = TextEditingController(text: site?.officeStartTime ?? '');
    final officeEndCtrl = TextEditingController(text: site?.officeEndTime ?? '');

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: Text(site == null ? 'Create Work Site' : 'Edit Work Site'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Site Name'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: latCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: lngCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: radiusCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Allowed Radius (Meters)',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: addressCtrl,
                decoration: const InputDecoration(labelText: 'Address'),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: officeStartCtrl,
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: dialogCtx,
                          initialTime: const TimeOfDay(hour: 9, minute: 0),
                        );
                        if (time != null) {
                          officeStartCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Start Time (Optional)'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: officeEndCtrl,
                      readOnly: true,
                      onTap: () async {
                        final time = await showTimePicker(
                          context: dialogCtx,
                          initialTime: const TimeOfDay(hour: 17, minute: 0),
                        );
                        if (time != null) {
                          officeEndCtrl.text = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
                        }
                      },
                      decoration: const InputDecoration(labelText: 'End Time (Optional)'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              if (nameCtrl.text.trim().isEmpty) return;
              final payload = {
                'name': nameCtrl.text.trim(),
                'latitude': double.tryParse(latCtrl.text) ?? 0,
                'longitude': double.tryParse(lngCtrl.text) ?? 0,
                'radiusMeters': int.tryParse(radiusCtrl.text) ?? 500,
                'address': addressCtrl.text.trim(),
                if (officeStartCtrl.text.isNotEmpty) 'officeStartTime': officeStartCtrl.text,
                if (officeEndCtrl.text.isNotEmpty) 'officeEndTime': officeEndCtrl.text,
              };
              try {
                if (site == null) {
                  await ref.read(settingsServiceProvider).addSite(payload);
                } else {
                  await ref
                      .read(settingsServiceProvider)
                      .updateSite(site.id, payload);
                }
                ref.invalidate(sitesProvider);
                if (dialogCtx.mounted) {
                  Navigator.pop(dialogCtx);
                  SnackbarUtils.showSuccess(
                    dialogCtx,
                    site == null ? 'Site created' : 'Site updated',
                  );
                }
              } catch (e) {
                if (dialogCtx.mounted) {
                  SnackbarUtils.handleApiError(dialogCtx, e);
                }
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteSite(
    BuildContext context,
    WidgetRef ref,
    Site site,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Work Site'),
        content: Text('Are you sure you want to delete "${site.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: VelocityColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await ref.read(settingsServiceProvider).deleteSite(site.id);
        ref.invalidate(sitesProvider);
        if (context.mounted) {
          SnackbarUtils.showSuccess(context, 'Site deleted successfully');
        }
      } catch (e) {
        if (context.mounted) SnackbarUtils.handleApiError(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sitesAsync = ref.watch(sitesProvider);

    return SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(
        context,
        basePadding: const EdgeInsets.all(16.0),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Office Geofence & Sites',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Authorized locations for GPS punch-in',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          Theme.of(context).colorScheme.primary,
                      foregroundColor:
                          Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Site'),
                    onPressed: () => _showSiteModal(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              sitesAsync.when(
                data: (sites) {
                  if (sites.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No work sites configured yet.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sites.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final s = sites[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.location_on,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          s.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Radius: ${s.radiusMeters ?? 500}m • Lat: ${s.latitude.toStringAsFixed(4)}, Lng: ${s.longitude.toStringAsFixed(4)}',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () =>
                                  _showSiteModal(context, ref, s),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.red,
                              ),
                              onPressed: () =>
                                  _deleteSite(context, ref, s),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      ErrorHandler.getUserMessage(e),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 4. LOCATION LEAVE POLICIES TAB
// ==========================================
class _LocationPoliciesTab extends ConsumerWidget {
  const _LocationPoliciesTab();

  void _showEditPolicyModal(
    BuildContext context,
    WidgetRef ref,
    LocationPolicy policy,
  ) {
    final quotaCtrl = TextEditingController(
      text: policy.monthlyPaidLeaveQuota.toString(),
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit Leave Quota: ${policy.location}'),
        content: TextField(
          controller: quotaCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Paid Leave Quota',
            helperText: 'Number of paid leaves allowed per month',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () async {
              final quota = int.tryParse(quotaCtrl.text);
              if (quota == null) return;
              try {
                await ref
                    .read(settingsServiceProvider)
                    .updateLocationPolicy(policy.location, quota);
                ref.invalidate(locationPoliciesProvider);
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  SnackbarUtils.showSuccess(ctx, 'Policy updated');
                }
              } catch (e) {
                if (ctx.mounted) SnackbarUtils.handleApiError(ctx, e);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final policiesAsync = ref.watch(locationPoliciesProvider);

    return SingleChildScrollView(
      padding: AppScaffold.getScrollPadding(
        context,
        basePadding: const EdgeInsets.all(16.0),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.policy_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Location-Specific Leave Quotas',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Monthly paid leave allocations assigned per regional office.',
                style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 16),
              policiesAsync.when(
                data: (policies) {
                  if (policies.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No location policies configured.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: policies.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final p = policies[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.place_outlined,
                            color:
                                Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                        ),
                        title: Text(
                          p.location,
                          style:
                              const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          'Monthly Paid Quota: ${p.monthlyPaidLeaveQuota} Days',
                          style: TextStyle(
                            color: Theme.of(context).hintColor,
                            fontSize: 12,
                          ),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () =>
                              _showEditPolicyModal(context, ref, p),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      ErrorHandler.getUserMessage(e),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
