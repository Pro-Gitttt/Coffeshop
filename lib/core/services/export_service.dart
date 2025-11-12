import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/stock_item_model.dart';
import '../models/stock_history_model.dart';
import '../errors/app_exception.dart';

class ExportService {
  // Export stock items to CSV
  Future<File> exportStockToCSV(List<StockItem> items) async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Name',
        'Category',
        'Quantity',
        'Unit',
        'Alert Threshold',
        'Last Updated',
      ]);
      
      // Data rows
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      for (var item in items) {
        rows.add([
          item.nom,
          item.categorie,
          item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1),
          item.unite,
          item.shortageThreshold?.toStringAsFixed(item.shortageThreshold!.truncateToDouble() == item.shortageThreshold! ? 0 : 1) ?? 'N/A',
          dateFormat.format(item.misAJourLe),
        ]);
      }
      
      final csvData = const ListToCsvConverter().convert(rows);
      
      // Get directory
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/stock_export_$timestamp.csv');
      
      await file.writeAsString(csvData);
      return file;
    } catch (e) {
      throw AppException('export', 'Erreur d\'export CSV: ${e.toString()}');
    }
  }
  
  // Export stock items to PDF
  Future<File> exportStockToPDF(List<StockItem> items) async {
    try {
      final pdf = pw.Document();
      final exportDate = DateFormat('dd/MM/yyyy at HH:mm').format(DateTime.now());
      
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          build: (pw.Context context) {
            return [
              // Header
              pw.Header(
                level: 0,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Stock Report',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Exported on $exportDate',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Summary
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'Total products: ${items.length}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                    pw.Text(
                      'Alerts: ${items.where((item) => item.isLowStock).length}',
                      style: const pw.TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              
              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  // Header row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Unit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Threshold', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  // Data rows
                  ...items.map((item) => pw.TableRow(
                    decoration: item.isLowStock
                        ? const pw.BoxDecoration(color: PdfColors.red100)
                        : null,
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.nom),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.categorie),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.quantite.toStringAsFixed(item.quantite.truncateToDouble() == item.quantite ? 0 : 1),
                        ),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.unite),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(
                          item.shortageThreshold?.toStringAsFixed(item.shortageThreshold!.truncateToDouble() == item.shortageThreshold! ? 0 : 1) ?? 'N/A',
                        ),
                      ),
                    ],
                  )),
                ],
              ),
            ];
          },
        ),
      );
      
      // Save PDF
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/stock_export_$timestamp.pdf');
      
      await file.writeAsBytes(await pdf.save());
      return file;
    } catch (e) {
      throw AppException('export', 'Erreur d\'export PDF: ${e.toString()}');
    }
  }
  
  // Export history to CSV
  Future<File> exportHistoryToCSV(List<StockHistory> history) async {
    try {
      final List<List<dynamic>> rows = [];
      
      // Header
      rows.add([
        'Type',
        'Product',
        'Category',
        'Quantity',
        'Unit',
        'User',
        'Date',
      ]);
      
      // Data rows
      final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
      for (var entry in history) {
        rows.add([
          entry.typeLabel,
          entry.stockItemName,
          entry.category,
          entry.quantityChange.toStringAsFixed(entry.quantityChange.truncateToDouble() == entry.quantityChange ? 0 : 1),
          entry.unit,
          entry.userEmail ?? 'Unknown',
          dateFormat.format(entry.timestamp),
        ]);
      }
      
      final csvData = const ListToCsvConverter().convert(rows);
      
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final file = File('${directory.path}/history_export_$timestamp.csv');
      
      await file.writeAsString(csvData);
      return file;
    } catch (e) {
      throw AppException('export', 'Erreur d\'export historique CSV: ${e.toString()}');
    }
  }
}

