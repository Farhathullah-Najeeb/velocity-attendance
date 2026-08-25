import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../services/overtime_service.dart';
import 'employee_overtime_screen.dart';

@RoutePage()
class RequestOvertimeScreen extends ConsumerStatefulWidget {
  const RequestOvertimeScreen({super.key});

  @override
  ConsumerState<RequestOvertimeScreen> createState() => _RequestOvertimeScreenState();
}

class _RequestOvertimeScreenState extends ConsumerState<RequestOvertimeScreen> {
  final _formKey = GlobalKey<FormState>();
  final _workSummaryController = TextEditingController();

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  bool _isLoading = false;

  @override
  void dispose() {
    _workSummaryController.dispose();
    super.dispose();
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
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    ).timeout(const Duration(seconds: 10));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      SnackbarUtils.showError(context, 'Please select Date, Start Time and End Time');
      return;
    }

    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    if (startMinutes >= endMinutes) {
      SnackbarUtils.showError(context, 'End time must be after Start time');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final position = await _determinePosition();
      
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      
      final now = DateTime.now();
      final startDt = DateTime(now.year, now.month, now.day, _startTime!.hour, _startTime!.minute);
      final endDt = DateTime(now.year, now.month, now.day, _endTime!.hour, _endTime!.minute);
      
      await ref.read(overtimeServiceProvider).submitOvertime(
        dateStr: dateStr,
        startTime: startDt.toUtc().toIso8601String(),
        endTime: endDt.toUtc().toIso8601String(),
        workSummary: _workSummaryController.text.trim(),
        latitude: position.latitude,
        longitude: position.longitude,
        address: 'Current Location', 
      );

      if (mounted) {
        SnackbarUtils.showSuccess(context, 'Overtime requested successfully!');
        ref.invalidate(myOvertimeProvider);
        context.router.maybePop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.handleApiError(context, e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Request Overtime'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Submit Overtime Details',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your current location will be attached automatically to this request for verification.',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 24),
                
                // Date Picker
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now().subtract(const Duration(days: 30)),
                      lastDate: DateTime.now(),
                    );
                    if (date != null) setState(() => _selectedDate = date);
                  },
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'Overtime Date',
                      prefixIcon: Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
                    ),
                    child: Text(
                      _selectedDate == null 
                          ? 'Select date' 
                          : DateFormat('MMM dd, yyyy').format(_selectedDate!),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) setState(() => _startTime = time);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Start Time',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _startTime == null 
                                ? 'Select' 
                                : _startTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final time = await showTimePicker(
                            context: context,
                            initialTime: TimeOfDay.now(),
                          );
                          if (time != null) setState(() => _endTime = time);
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'End Time',
                            prefixIcon: Icon(Icons.access_time),
                            border: OutlineInputBorder(),
                          ),
                          child: Text(
                            _endTime == null 
                                ? 'Select' 
                                : _endTime!.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Summary
                TextFormField(
                  controller: _workSummaryController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Work Summary',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                    helperText: 'Briefly describe the work completed',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Work summary is required' : null,
                ),
                const SizedBox(height: 32),

                // Submit Button
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24, width: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('SUBMIT REQUEST', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
