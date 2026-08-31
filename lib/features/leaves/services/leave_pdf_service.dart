import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';

class LeavePdfService {
  static Future<Uint8List> generateLeaveReceiptPdf({
    required String employeeName,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required int totalDays,
    required String reason,
    required String status,
    String? appliedAt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Banner
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red800,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VELOCITY ATTENDANCE',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          'OFFICIAL LEAVE APPLICATION RECEIPT',
                          style: const pw.TextStyle(
                            color: PdfColors.red100,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Text(
                        'STATUS: ${status.toUpperCase()}',
                        style: pw.TextStyle(
                          color: PdfColors.red800,
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 24),

              // Details Card
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildPdfRow('Applicant Name', employeeName),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow('Leave Type', leaveType),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow('From Date', fromDate),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow('To Date', toDate),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow('Total Duration', '$totalDays day(s)'),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow('Reason for Leave', reason),
                    pw.Divider(color: PdfColors.grey200),
                    _buildPdfRow(
                      'Application Date',
                      appliedAt ?? DateFormat('dd MMM yyyy, hh:mm a').format(DateTime.now()),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 40),

              // Footer Signatures
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Employee Signature',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Container(width: 140, height: 1, color: PdfColors.grey400),
                      pw.SizedBox(height: 4),
                      pw.Text(
                        'Manager / HR Signature',
                        style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            value,
            style: const pw.TextStyle(fontSize: 11, color: PdfColors.black),
          ),
        ],
      ),
    );
  }

  static Future<void> printLeaveReceipt({
    required String employeeName,
    required String leaveType,
    required String fromDate,
    required String toDate,
    required int totalDays,
    required String reason,
    required String status,
    String? appliedAt,
  }) async {
    try {
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async {
          return await generateLeaveReceiptPdf(
            employeeName: employeeName,
            leaveType: leaveType,
            fromDate: fromDate,
            toDate: toDate,
            totalDays: totalDays,
            reason: reason,
            status: status,
            appliedAt: appliedAt,
          );
        },
        name: 'Leave_Receipt_${fromDate.replaceAll(' ', '_')}.pdf',
      );
    } catch (_) {
      // Fallback share if direct layout fails
      final bytes = await generateLeaveReceiptPdf(
        employeeName: employeeName,
        leaveType: leaveType,
        fromDate: fromDate,
        toDate: toDate,
        totalDays: totalDays,
        reason: reason,
        status: status,
        appliedAt: appliedAt,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'Leave_Receipt_${fromDate.replaceAll(' ', '_')}.pdf',
      );
    }
  }
}
