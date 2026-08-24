import 'dart:typed_data';
import '../../../core/utils/error_handler.dart';
import '../../shared/widgets/app_scaffold.dart';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../services/admin_service.dart';
import '../../attendance/services/attendance_service.dart';
import '../../../core/theme/app_theme.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;

@RoutePage()
class AdminReportsScreen extends ConsumerStatefulWidget {
  const AdminReportsScreen({super.key});

  @override
  ConsumerState<AdminReportsScreen> createState() => _AdminReportsScreenState();
}

class _AdminReportsScreenState extends ConsumerState<AdminReportsScreen> {
  bool _isGenerating = false;
  String _selectedReportType = 'WEEKLY'; // WEEKLY, MONTHLY, CUSTOM
  String _selectedFormat = 'PDF'; // PDF, EXCEL
  DateTime? _startDate;
  DateTime? _endDate;

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
        _selectedReportType = 'CUSTOM';
      });
    }
  }

  Future<void> _exportReport() async {
    if (_selectedReportType == 'CUSTOM' && (_startDate == null || _endDate == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a date range for custom report')));
      return;
    }

    setState(() => _isGenerating = true);
    try {
      final df = DateFormat('yyyy-MM-dd');
      final bytes = await ref.read(attendanceServiceProvider).exportReport(
        format: _selectedFormat.toLowerCase(),
        type: _selectedReportType == 'CUSTOM' ? null : _selectedReportType.toLowerCase(),
        startDate: _startDate != null ? df.format(_startDate!) : null,
        endDate: _endDate != null ? df.format(_endDate!) : null,
      );

      final ext = _selectedFormat == 'PDF' ? 'pdf' : 'xlsx';
      final mimeType = _selectedFormat == 'PDF' ? 'application/pdf' : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      final fileName = 'attendance_report_${DateTime.now().millisecondsSinceEpoch}.$ext';

      if (kIsWeb) {
        // Share plus on Web will trigger a download
        await Share.shareXFiles([
          XFile.fromData(
            Uint8List.fromList(bytes),
            name: fileName,
            mimeType: mimeType,
          )
        ]);
      } else {
        // Mobile: save to temp and share
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsBytes(bytes);
        
        await Share.shareXFiles([
          XFile(file.path, mimeType: mimeType)
        ], text: 'Attendance Report');
      }
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ErrorHandler.getUserMessage(e)), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() => _isGenerating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      appBar: MediaQuery.of(context).size.width > 800 ? AppBar(title: const Text('Export Reports')) : null,
      body: Center(
        child: SingleChildScrollView(
              padding: AppScaffold.getScrollPadding(context, basePadding: const EdgeInsets.all(24.0)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.analytics_outlined, size: 80, color: AppTheme.primaryRed.withValues(alpha: 0.8)),
                    const SizedBox(height: 24),
                    Text(
                      'Attendance & Exceptions',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generate and download detailed reports for employee attendance, late arrivals, and early exits.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    DropdownButtonFormField<String>(
                      value: _selectedReportType,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Report Type', prefixIcon: Icon(Icons.date_range)),
                      items: const [
                        DropdownMenuItem(value: 'WEEKLY', child: Text('Weekly Report', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'MONTHLY', child: Text('Monthly Report', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'CUSTOM', child: Text('Custom Date Range', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedReportType = val);
                          if (val == 'CUSTOM' && _startDate == null) {
                            _pickDateRange();
                          }
                        }
                      },
                    ),

                    if (_selectedReportType == 'CUSTOM') ...[
                      const SizedBox(height: 16),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(_startDate != null && _endDate != null
                            ? '${DateFormat.yMMMd().format(_startDate!)} - ${DateFormat.yMMMd().format(_endDate!)}'
                            : 'Select Date Range'),
                        leading: const Icon(Icons.calendar_month),
                        trailing: const Icon(Icons.edit, size: 16),
                        onTap: _pickDateRange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                          side: BorderSide(color: Colors.grey.shade300),
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _selectedFormat,
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Export Format', prefixIcon: Icon(Icons.insert_drive_file)),
                      items: const [
                        DropdownMenuItem(value: 'PDF', child: Text('PDF Document (.pdf)', overflow: TextOverflow.ellipsis)),
                        DropdownMenuItem(value: 'EXCEL', child: Text('Excel Spreadsheet (.xlsx)', overflow: TextOverflow.ellipsis)),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedFormat = val);
                      },
                    ),

                    const SizedBox(height: 48),
                    SizedBox(
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: _isGenerating ? null : _exportReport,
                        icon: _isGenerating 
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                            : Icon(_selectedFormat == 'PDF' ? Icons.picture_as_pdf : Icons.table_chart),
                        label: Text(_isGenerating ? 'GENERATING...' : 'DOWNLOAD REPORT'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
