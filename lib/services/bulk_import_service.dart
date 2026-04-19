// ============================================================
// FILE: lib/services/bulk_import_service.dart
// ============================================================
// Bulk product import from CSV files
// Parses CSV client-side, validates rows, batch inserts via Supabase
// ============================================================

import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:csv/csv.dart';
import 'supabase_service.dart';

/// Represents a single parsed row from the import file
class ImportRow {
  final int rowIndex;
  String name;
  String? nameAr;
  double? price;
  double? salePrice;
  String? category;
  String? subcategory;
  String? description;
  String? descriptionAr;
  int? stockQuantity;
  String? sku;
  String? barcode;
  String? imageUrl;
  String currency;

  // Validation
  List<String> errors = [];
  bool get isValid => errors.isEmpty;

  ImportRow({
    required this.rowIndex,
    required this.name,
    this.nameAr,
    this.price,
    this.salePrice,
    this.category,
    this.subcategory,
    this.description,
    this.descriptionAr,
    this.stockQuantity,
    this.sku,
    this.barcode,
    this.imageUrl,
    this.currency = 'USD',
  });

  Map<String, dynamic> toInsertMap(String storeId) {
    final data = <String, dynamic>{
      'store_id': storeId,
      'name': name,
      'price': price,
      'currency': currency,
      'is_available': true,
      'is_featured': false,
      'is_demo': false,
    };
    if (nameAr != null && nameAr!.isNotEmpty) data['name_ar'] = nameAr;
    if (salePrice != null) data['sale_price'] = salePrice;
    if (category != null && category!.isNotEmpty) data['category'] = category;
    if (subcategory != null && subcategory!.isNotEmpty) data['subcategory'] = subcategory;
    if (description != null && description!.isNotEmpty) data['description'] = description;
    if (descriptionAr != null && descriptionAr!.isNotEmpty) data['description_ar'] = descriptionAr;
    if (stockQuantity != null) data['stock_quantity'] = stockQuantity;
    if (sku != null && sku!.isNotEmpty) data['sku'] = sku;
    if (barcode != null && barcode!.isNotEmpty) data['barcode'] = barcode;
    if (imageUrl != null && imageUrl!.isNotEmpty) data['image_url'] = imageUrl;
    return data;
  }
}

/// Result of a bulk import operation
class BulkImportResult {
  final int totalRows;
  final int successCount;
  final int errorCount;
  final List<String> errors;

  BulkImportResult({
    required this.totalRows,
    required this.successCount,
    required this.errorCount,
    required this.errors,
  });
}

class BulkImportService {
  /// Known column header aliases (lowercase) mapped to canonical field names
  static final Map<String, String> _columnAliases = {
    'name': 'name',
    'product name': 'name',
    'product': 'name',
    'item': 'name',
    'item name': 'name',
    'title': 'name',
    'name_ar': 'name_ar',
    'arabic name': 'name_ar',
    'name (arabic)': 'name_ar',
    'price': 'price',
    'unit price': 'price',
    'cost': 'price',
    'amount': 'price',
    'sale price': 'sale_price',
    'sale_price': 'sale_price',
    'discount price': 'sale_price',
    'offer price': 'sale_price',
    'category': 'category',
    'cat': 'category',
    'group': 'category',
    'type': 'category',
    'subcategory': 'subcategory',
    'sub category': 'subcategory',
    'sub_category': 'subcategory',
    'description': 'description',
    'desc': 'description',
    'details': 'description',
    'description_ar': 'description_ar',
    'arabic description': 'description_ar',
    'description (arabic)': 'description_ar',
    'stock': 'stock_quantity',
    'stock quantity': 'stock_quantity',
    'stock_quantity': 'stock_quantity',
    'quantity': 'stock_quantity',
    'qty': 'stock_quantity',
    'sku': 'sku',
    'product code': 'sku',
    'code': 'sku',
    'barcode': 'barcode',
    'bar code': 'barcode',
    'upc': 'barcode',
    'ean': 'barcode',
    'image': 'image_url',
    'image url': 'image_url',
    'image_url': 'image_url',
    'photo': 'image_url',
    'photo url': 'image_url',
    'currency': 'currency',
  };

  /// Parse CSV bytes into ImportRow list
  static List<ImportRow> parseCSV(Uint8List bytes) {
    debugPrint('[BULK_IMPORT] parseCSV called with ${bytes.length} bytes');

    // Try UTF-8 first, strip BOM, fallback to latin1
    String content;
    try {
      content = utf8.decode(bytes);
      // Strip UTF-8 BOM if present
      if (content.startsWith('\uFEFF')) {
        content = content.substring(1);
        debugPrint('[BULK_IMPORT] Stripped UTF-8 BOM');
      }
    } catch (_) {
      content = latin1.decode(bytes);
      debugPrint('[BULK_IMPORT] Fell back to latin1 decoding');
    }

    // Normalize line endings to \n
    content = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

    debugPrint('[BULK_IMPORT] Content length: ${content.length}');
    debugPrint('[BULK_IMPORT] First 200 chars: ${content.substring(0, content.length > 200 ? 200 : content.length)}');

    // Try CSV parser first
    List<List<dynamic>> rows;
    try {
      final csvConverter = const CsvToListConverter(
        shouldParseNumbers: false,
        allowInvalid: true,
        eol: '\n',
      );
      rows = csvConverter.convert(content);
      debugPrint('[BULK_IMPORT] CsvToListConverter parsed ${rows.length} rows');
    } catch (e) {
      debugPrint('[BULK_IMPORT] CsvToListConverter failed: $e, trying manual parse');
      // Fallback: manual CSV parsing
      rows = _manualParse(content);
      debugPrint('[BULK_IMPORT] Manual parse got ${rows.length} rows');
    }

    if (rows.isEmpty) {
      throw Exception('File is empty');
    }

    if (rows.length < 2) {
      throw Exception('File has headers but no data rows');
    }

    // First row is headers
    final headers = rows.first.map((h) => h.toString().trim()).toList();
    debugPrint('[BULK_IMPORT] Headers: $headers');

    final columnMap = _mapColumns(headers);
    debugPrint('[BULK_IMPORT] Column mapping: $columnMap');

    if (!columnMap.containsKey('name')) {
      throw Exception(
        'Missing required column: "Name" or "Product Name".\n'
        'Found columns: ${headers.join(", ")}',
      );
    }

    final importRows = <ImportRow>[];

    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.every((cell) => cell.toString().trim().isEmpty)) {
        debugPrint('[BULK_IMPORT] Skipping empty row $i');
        continue;
      }

      final importRow = _parseRow(i + 1, row, columnMap);
      _validateRow(importRow);
      importRows.add(importRow);
      debugPrint('[BULK_IMPORT] Row ${i + 1}: name="${importRow.name}" price=${importRow.price} valid=${importRow.isValid}');
    }

    debugPrint('[BULK_IMPORT] Total parsed rows: ${importRows.length}');
    return importRows;
  }

  /// Manual CSV parser as fallback
  static List<List<dynamic>> _manualParse(String content) {
    final lines = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final result = <List<dynamic>>[];

    for (final line in lines) {
      final cells = <String>[];
      bool inQuotes = false;
      final buffer = StringBuffer();

      for (int i = 0; i < line.length; i++) {
        final ch = line[i];
        if (ch == '"') {
          inQuotes = !inQuotes;
        } else if (ch == ',' && !inQuotes) {
          cells.add(buffer.toString());
          buffer.clear();
        } else {
          buffer.write(ch);
        }
      }
      cells.add(buffer.toString());
      result.add(cells);
    }

    return result;
  }

  /// Map header names to column indices
  static Map<String, int> _mapColumns(List<String> headers) {
    final map = <String, int>{};
    for (int i = 0; i < headers.length; i++) {
      final normalized = headers[i].toLowerCase().trim();
      final canonical = _columnAliases[normalized];
      if (canonical != null) {
        map[canonical] = i;
      }
    }
    return map;
  }

  /// Parse a single data row
  static ImportRow _parseRow(
      int rowIndex, List<dynamic> row, Map<String, int> columnMap) {
    String cellAt(String field) {
      final idx = columnMap[field];
      if (idx == null || idx >= row.length) return '';
      return row[idx].toString().trim();
    }

    double? parseDouble(String field) {
      final val = cellAt(field);
      if (val.isEmpty) return null;
      // Remove currency symbols and commas
      final cleaned = val.replaceAll(RegExp(r'[^\d.]'), '');
      return double.tryParse(cleaned);
    }

    int? parseInt(String field) {
      final val = cellAt(field);
      if (val.isEmpty) return null;
      final cleaned = val.replaceAll(RegExp(r'[^\d]'), '');
      return int.tryParse(cleaned);
    }

    return ImportRow(
      rowIndex: rowIndex,
      name: cellAt('name'),
      nameAr: cellAt('name_ar').isEmpty ? null : cellAt('name_ar'),
      price: parseDouble('price'),
      salePrice: parseDouble('sale_price'),
      category: cellAt('category').isEmpty ? null : cellAt('category'),
      subcategory: cellAt('subcategory').isEmpty ? null : cellAt('subcategory'),
      description: cellAt('description').isEmpty ? null : cellAt('description'),
      descriptionAr: cellAt('description_ar').isEmpty ? null : cellAt('description_ar'),
      stockQuantity: parseInt('stock_quantity'),
      sku: cellAt('sku').isEmpty ? null : cellAt('sku'),
      barcode: cellAt('barcode').isEmpty ? null : cellAt('barcode'),
      imageUrl: cellAt('image_url').isEmpty ? null : cellAt('image_url'),
      currency: cellAt('currency').isEmpty ? 'USD' : cellAt('currency'),
    );
  }

  /// Validate a single row
  static void _validateRow(ImportRow row) {
    row.errors.clear();

    if (row.name.isEmpty) {
      row.errors.add('Product name is required');
    }
    if (row.name.length > 200) {
      row.errors.add('Name too long (max 200 characters)');
    }

    if (row.price == null) {
      row.errors.add('Price is required');
    } else if (row.price! < 0) {
      row.errors.add('Price cannot be negative');
    }

    if (row.salePrice != null) {
      if (row.salePrice! < 0) {
        row.errors.add('Sale price cannot be negative');
      } else if (row.price != null && row.salePrice! >= row.price!) {
        row.errors.add('Sale price must be less than regular price');
      }
    }

    if (row.stockQuantity != null && row.stockQuantity! < 0) {
      row.errors.add('Stock quantity cannot be negative');
    }
  }

  /// Batch insert validated rows into Supabase
  static Future<BulkImportResult> importProducts({
    required String storeId,
    required List<ImportRow> rows,
  }) async {
    final validRows = rows.where((r) => r.isValid).toList();
    final errors = <String>[];
    int successCount = 0;

    debugPrint('[BULK_IMPORT] Starting import: ${validRows.length} valid of ${rows.length} total');

    // Insert in batches of 50
    const batchSize = 50;
    for (int i = 0; i < validRows.length; i += batchSize) {
      final batch = validRows.skip(i).take(batchSize).toList();
      final payloads = batch.map((r) => r.toInsertMap(storeId)).toList();

      try {
        await SupabaseService.client.from('products').insert(payloads);
        successCount += batch.length;
        debugPrint('[BULK_IMPORT] Batch inserted ${batch.length} products');
      } catch (e) {
        debugPrint('[BULK_IMPORT] Batch error: $e');
        for (int j = 0; j < batch.length; j++) {
          try {
            await SupabaseService.client
                .from('products')
                .insert(batch[j].toInsertMap(storeId));
            successCount++;
          } catch (rowError) {
            errors.add('Row ${batch[j].rowIndex}: $rowError');
          }
        }
      }
    }

    for (final row in rows.where((r) => !r.isValid)) {
      errors.add('Row ${row.rowIndex}: ${row.errors.join(", ")}');
    }

    debugPrint('[BULK_IMPORT] Done: $successCount success, ${errors.length} errors');

    return BulkImportResult(
      totalRows: rows.length,
      successCount: successCount,
      errorCount: rows.length - successCount,
      errors: errors,
    );
  }

  /// Generate a CSV template string
  static String generateTemplate() {
    const headers = [
      'Name',
      'Price',
      'Category',
      'Description',
      'Sale Price',
      'Stock Quantity',
      'SKU',
      'Barcode',
      'Image URL',
      'Name (Arabic)',
      'Description (Arabic)',
    ];
    const exampleRow = [
      'Chicken Shawarma',
      '5.99',
      'Sandwiches',
      'Grilled chicken shawarma with garlic sauce',
      '',
      '100',
      'SW-001',
      '',
      '',
      '',
      '',
    ];
    final buffer = StringBuffer();
    buffer.writeln(headers.join(','));
    buffer.writeln(exampleRow.join(','));
    return buffer.toString();
  }
}
