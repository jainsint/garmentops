import 'package:flutter/foundation.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart';
// ignore: avoid_web_libraries_in_flutter
import 'package:universal_html/html.dart' as html;
import '../core/ist_utils.dart';

class ExcelExportService {
  static Future<void> exportRegisterToExcel({
    required String registerName,
    required List<String> headers,
    required List<List<dynamic>> rows,
    String? dateStr,
  }) async {
    final date = dateStr ?? ISTUtils.todayString();
    final fileName = '${registerName.replaceAll(' ', '_')}_Register_$date.xlsx';
    await _buildAndDownload(registerName, headers, rows, fileName);
  }

  static Future<void> exportOrderToExcel({
    required String orderNo,
    required Map<String, List<Map<String, dynamic>>> registerData,
  }) async {
    final date = ISTUtils.todayString();
    final fileName = 'Order_${orderNo.replaceAll(' ', '_')}_$date.xlsx';

    final workbook = Workbook();
    bool firstSheet = true;

    for (final entry in registerData.entries) {
      if (entry.value.isEmpty) continue;
      Worksheet sheet;
      if (firstSheet) {
        sheet = workbook.worksheets[0];
        sheet.name = entry.key;
        firstSheet = false;
      } else {
        sheet = workbook.worksheets.addWithName(entry.key);
      }

      final allKeys = entry.value.first.keys.toList();
      _writeHeaderRow(workbook, sheet, allKeys);

      for (int row = 0; row < entry.value.length; row++) {
        final rowMap = entry.value[row];
        for (int col = 0; col < allKeys.length; col++) {
          _writeCell(sheet, row + 2, col + 1, rowMap[allKeys[col]]);
        }
      }
    }

    if (firstSheet) {
      // No data at all — write empty sheet
      workbook.worksheets[0].name = 'No Data';
    }

    final bytes = Uint8List.fromList(workbook.saveAsStream());
    workbook.dispose();
    _triggerDownload(bytes, fileName);
  }

  static Future<void> _buildAndDownload(
    String sheetName,
    List<String> headers,
    List<List<dynamic>> rows,
    String fileName,
  ) async {
    final workbook = Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = sheetName;

    _writeHeaderRow(workbook, sheet, headers);

    for (int row = 0; row < rows.length; row++) {
      final rowData = rows[row];
      for (int col = 0; col < rowData.length; col++) {
        _writeCell(sheet, row + 2, col + 1, rowData[col]);
      }
    }

    final bytes = Uint8List.fromList(workbook.saveAsStream());
    workbook.dispose();
    _triggerDownload(bytes, fileName);
  }

  static void _writeHeaderRow(
    Workbook workbook,
    Worksheet sheet,
    List<String> headers,
  ) {
    final headerStyle = workbook.styles.add('H_${sheet.name}');
    headerStyle.backColor = '#1A237E';
    headerStyle.fontColor = '#FFFFFF';
    headerStyle.bold = true;
    headerStyle.fontSize = 11;
    headerStyle.hAlign = HAlignType.center;

    for (int col = 0; col < headers.length; col++) {
      final cell = sheet.getRangeByIndex(1, col + 1);
      cell.setText(headers[col]);
      cell.cellStyle = headerStyle;
      sheet.setColumnWidthInPixels(col + 1, 150);
    }
  }

  static void _writeCell(Worksheet sheet, int row, int col, dynamic value) {
    final cell = sheet.getRangeByIndex(row, col);
    if (value is int) {
      cell.setNumber(value.toDouble());
    } else if (value is double) {
      cell.setNumber(value);
    } else {
      cell.setText(value?.toString() ?? '');
    }
  }

  static void _triggerDownload(Uint8List bytes, String fileName) {
    if (kIsWeb) {
      final blob = html.Blob([
        bytes,
      ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', fileName)
        ..click();
      html.Url.revokeObjectUrl(url);
    }
  }
}
