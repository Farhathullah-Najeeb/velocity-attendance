import 'package:auto_route/auto_route.dart';
import '../../../core/utils/error_handler.dart';
import '../../shared/widgets/app_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/settings_service.dart';
import '../../../models/settings.dart';
import '../../../models/holiday.dart';
import '../../../models/site.dart';
import '../../../core/theme/app_theme.dart';
import 'package:intl/intl.dart';

// Provides the settings data
final settingsProvider = FutureProvider.autoDispose<Settings>((ref) {
  return ref.watch(settingsServiceProvider).getSettings();
});

final holidaysProvider = FutureProvider.autoDispose<List<Holiday>>((ref) {
  return ref.watch(settingsServiceProvider).getHolidays();
});

final sitesProvider = FutureProvider.autoDispose<List<Site>>((ref) {
  return ref.watch(settingsServiceProvider).getSites();
});

final locationPoliciesProvider = FutureProvider.autoDispose<List<LocationPolicy>>((ref) {
  return ref.watch(settingsServiceProvider).getLocationPolicies();
});

@RoutePage()
class AdminSettingsScreen extends ConsumerStatefulWidget {
  const AdminSettingsScreen({super.key});

  @override
  ConsumerState<AdminSettingsScreen> createState() => _AdminSettingsScreenState();
}

class _AdminSettingsScreenState extends ConsumerState<AdminSettingsScreen> {
  // To keep the file clean, we will implement sections inside this class or via smaller widgets.
  
  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: MediaQuery.of(context).size.width > 800 ? AppBar(title: const Text('System Configuration')) : null,
      body: SingleChildScrollView(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSettingsSection(context, ref),
            const SizedBox(height: 24),
            _buildHolidaysSection(context, ref),
            const SizedBox(height: 24),
            _buildSitesSection(context, ref),
            const SizedBox(height: 24),
            _buildPoliciesSection(context, ref),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSettingsSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(settingsProvider);
    return state.when(
      data: (settings) => _SettingsForm(initialSettings: settings),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
    );
  }

  Widget _buildHolidaysSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(holidaysProvider);
    return state.when(
      data: (holidays) => _HolidaysList(holidays: holidays),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
    );
  }

  Widget _buildSitesSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(sitesProvider);
    return state.when(
      data: (sites) => _SitesList(sites: sites),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
    );
  }

  Widget _buildPoliciesSection(BuildContext context, WidgetRef ref) {
    final state = ref.watch(locationPoliciesProvider);
    return state.when(
      data: (policies) => _PoliciesList(policies: policies),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Text(ErrorHandler.getUserMessage(e)),
    );
  }
}

class _SettingsForm extends ConsumerStatefulWidget {
  final Settings initialSettings;
  const _SettingsForm({required this.initialSettings});
  @override
  ConsumerState<_SettingsForm> createState() => _SettingsFormState();
}

class _SettingsFormState extends ConsumerState<_SettingsForm> {
  late TextEditingController _startCtrl;
  late TextEditingController _endCtrl;
  late TextEditingController _graceCtrl;
  late TextEditingController _latCtrl;
  late TextEditingController _lngCtrl;
  late TextEditingController _radiusCtrl;
  late bool _geofence;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startCtrl = TextEditingController(text: widget.initialSettings.officeStartTime);
    _endCtrl = TextEditingController(text: widget.initialSettings.officeEndTime);
    _graceCtrl = TextEditingController(text: widget.initialSettings.gracePeriod.toString());
    _latCtrl = TextEditingController(text: widget.initialSettings.officeLatitude?.toString() ?? '');
    _lngCtrl = TextEditingController(text: widget.initialSettings.officeLongitude?.toString() ?? '');
    _radiusCtrl = TextEditingController(text: widget.initialSettings.allowedRadiusMeters?.toString() ?? '200');
    _geofence = widget.initialSettings.geofencingEnabled ?? true;
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsServiceProvider).updateSettings({
        'officeStartTime': _startCtrl.text,
        'officeEndTime': _endCtrl.text,
        'gracePeriod': int.tryParse(_graceCtrl.text) ?? 15,
        'officeLatitude': double.tryParse(_latCtrl.text),
        'officeLongitude': double.tryParse(_lngCtrl.text),
        'allowedRadiusMeters': int.tryParse(_radiusCtrl.text) ?? 200,
        'geofencingEnabled': _geofence,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Settings saved successfully')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Office Hours & Attendance Policies', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _startCtrl, decoration: const InputDecoration(labelText: 'Start Time (HH:MM)'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _endCtrl, decoration: const InputDecoration(labelText: 'End Time (HH:MM)'))),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _graceCtrl, decoration: const InputDecoration(labelText: 'Grace Period (mins)'), keyboardType: TextInputType.number),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Main Office Geofencing', style: Theme.of(context).textTheme.titleMedium),
                Switch(value: _geofence, onChanged: (v) => setState(() => _geofence = v)),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: _radiusCtrl, decoration: const InputDecoration(labelText: 'Allowed Radius (meters)'), keyboardType: TextInputType.number),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                const SizedBox(width: 16),
                Expanded(child: TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading ? const CircularProgressIndicator() : const Text('Save Settings'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HolidaysList extends ConsumerStatefulWidget {
  final List<Holiday> holidays;
  const _HolidaysList({required this.holidays});
  @override
  ConsumerState<_HolidaysList> createState() => _HolidaysListState();
}

class _HolidaysListState extends ConsumerState<_HolidaysList> {
  final _dateCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _addHoliday() async {
    if (_dateCtrl.text.isEmpty || _nameCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsServiceProvider).addHoliday(_dateCtrl.text, _nameCtrl.text);
      _dateCtrl.clear();
      _nameCtrl.clear();
      ref.invalidate(holidaysProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteHoliday(String id) async {
    try {
      await ref.read(settingsServiceProvider).deleteHoliday(id);
      ref.invalidate(holidaysProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Holiday Calendar', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _dateCtrl,
                    decoration: const InputDecoration(labelText: 'Date (YYYY-MM-DD)', prefixIcon: Icon(Icons.calendar_today)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(labelText: 'Holiday Name'),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isLoading ? null : _addHoliday,
                  child: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.holidays.isEmpty)
              const Text('No holidays configured.', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.holidays.length,
                itemBuilder: (context, index) {
                  final h = widget.holidays[index];
                  return ListTile(
                    title: Text(h.name),
                    subtitle: Text(h.date),
                    trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteHoliday(h.id)),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SitesList extends ConsumerStatefulWidget {
  final List<Site> sites;
  const _SitesList({required this.sites});
  @override
  ConsumerState<_SitesList> createState() => _SitesListState();
}

class _SitesListState extends ConsumerState<_SitesList> {
  Future<void> _deleteSite(String id) async {
    try {
      await ref.read(settingsServiceProvider).deleteSite(id);
      ref.invalidate(sitesProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
    }
  }

  void _showSiteModal([Site? site]) {
    final _nameCtrl = TextEditingController(text: site?.name);
    final _latCtrl = TextEditingController(text: site?.latitude.toString());
    final _lngCtrl = TextEditingController(text: site?.longitude.toString());
    final _radiusCtrl = TextEditingController(text: site?.radiusMeters?.toString() ?? '500');
    final _addressCtrl = TextEditingController(text: site?.address);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(site == null ? 'Create Work Site' : 'Edit Work Site'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Site Name')),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: TextField(controller: _latCtrl, decoration: const InputDecoration(labelText: 'Latitude'))),
                  const SizedBox(width: 8),
                  Expanded(child: TextField(controller: _lngCtrl, decoration: const InputDecoration(labelText: 'Longitude'))),
                ],
              ),
              const SizedBox(height: 8),
              TextField(controller: _radiusCtrl, decoration: const InputDecoration(labelText: 'Radius (m)')),
              const SizedBox(height: 8),
              TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: 'Address')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final payload = {
                'name': _nameCtrl.text,
                'latitude': double.tryParse(_latCtrl.text) ?? 0,
                'longitude': double.tryParse(_lngCtrl.text) ?? 0,
                'radiusMeters': int.tryParse(_radiusCtrl.text) ?? 500,
                'address': _addressCtrl.text,
              };
              try {
                if (site == null) {
                  await ref.read(settingsServiceProvider).addSite(payload);
                } else {
                  await ref.read(settingsServiceProvider).updateSite(site.id, payload);
                }
                ref.invalidate(sitesProvider);
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e))));
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Work Site Locations', style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(icon: const Icon(Icons.add), label: const Text('Add Site'), onPressed: _showSiteModal),
              ],
            ),
            const SizedBox(height: 16),
            if (widget.sites.isEmpty)
              const Text('No sites configured.', style: TextStyle(color: Colors.grey))
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.sites.length,
                itemBuilder: (context, index) {
                  final s = widget.sites[index];
                  return ListTile(
                    title: Text(s.name),
                    subtitle: Text('Lat: ${s.latitude}, Lng: ${s.longitude} | Radius: ${s.radiusMeters}m'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(icon: const Icon(Icons.edit), onPressed: () => _showSiteModal(s)),
                        IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteSite(s.id)),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _PoliciesList extends ConsumerStatefulWidget {
  final List<LocationPolicy> policies;
  const _PoliciesList({required this.policies});
  @override
  ConsumerState<_PoliciesList> createState() => _PoliciesListState();
}

class _PoliciesListState extends ConsumerState<_PoliciesList> {
  final _locCtrl = TextEditingController();
  final _quotaCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _savePolicy() async {
    if (_locCtrl.text.isEmpty || _quotaCtrl.text.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await ref.read(settingsServiceProvider).updateLocationPolicy(_locCtrl.text.toUpperCase(), int.parse(_quotaCtrl.text));
      _locCtrl.clear();
      _quotaCtrl.clear();
      ref.invalidate(locationPoliciesProvider);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Location-based Leave Quota Policies', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.policies.length,
              itemBuilder: (context, index) {
                final p = widget.policies[index];
                return ListTile(
                  title: Text(p.location),
                  subtitle: Text('Monthly Paid Leave Quota: ${p.monthlyPaidLeaveQuota}'),
                );
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: TextField(controller: _locCtrl, decoration: const InputDecoration(labelText: 'Location Name (e.g. KERALA)'))),
                const SizedBox(width: 8),
                Expanded(child: TextField(controller: _quotaCtrl, decoration: const InputDecoration(labelText: 'Monthly Quota'), keyboardType: TextInputType.number)),
                const SizedBox(width: 8),
                ElevatedButton(onPressed: _isLoading ? null : _savePolicy, child: const Text('Add / Update')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
