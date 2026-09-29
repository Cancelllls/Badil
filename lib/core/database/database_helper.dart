import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/alternative_model.dart';
import '../../data/models/pending_submission_model.dart';
import '../../data/models/country_prefix_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('badil.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, filePath);

    final exists = await databaseExists(path);

    if (!exists) {
      if (kDebugMode) {
        print("Creating a new copy of badil.db from bundled assets...");
      }

      try {
        await Directory(p.dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      final ByteData data = await rootBundle.load('assets/database/badil_seed.db');
      final List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes, flush: true);
      if (kDebugMode) {
        print("Successfully copied seed database to $path");
      }
    }

    final db = await openDatabase(
      path,
      version: 2,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          try {
            await db.execute('ALTER TABLE products ADD COLUMN reason_en TEXT;');
          } catch (_) {}
          try {
            await db.execute('ALTER TABLE product_alternatives ADD COLUMN note_en TEXT;');
          } catch (_) {}
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS country_prefixes (
                prefix TEXT PRIMARY KEY,
                country_code TEXT NOT NULL,
                name_ar TEXT NOT NULL,
                name_en TEXT NOT NULL,
                flag_emoji TEXT NOT NULL,
                default_status TEXT NOT NULL
              );
            ''');
          } catch (_) {}
          try {
            await db.execute('''
              CREATE TABLE IF NOT EXISTS app_settings (
                key TEXT PRIMARY KEY,
                value TEXT NOT NULL
              );
            ''');
          } catch (_) {}
        }
      },
    );

    return db;
  }

  /// Normalizes Arabic text by unifying hamzas, teh marbuta, alef maqsura, and stripping diacritics
  static String normalizeArabic(String input) {
    return input
        .replaceAll(RegExp(r'[\u064B-\u065F]'), '') // Tashkeel / harakat
        .replaceAll(RegExp(r'[أإآا]'), 'ا')
        .replaceAll(RegExp(r'[ةه]'), 'ه')
        .replaceAll(RegExp(r'[ىي]'), 'ي')
        .trim();
  }

  /// Look up product by barcode with smart prefix handling
  Future<ProductModel?> getProductByBarcode(String barcode) async {
    final db = await database;
    final cleanBarcode = barcode.trim();

    // 1. Try exact barcode match
    var res = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [cleanBarcode],
      limit: 1,
    );

    if (res.isNotEmpty) {
      return ProductModel.fromMap(res.first);
    }

    // 2. Try with leading zero added (UPC-A to EAN-13 normalization)
    if (cleanBarcode.length == 12) {
      res = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: ['0$cleanBarcode'],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return ProductModel.fromMap(res.first);
      }
    }

    // 3. Try with leading zero stripped
    if (cleanBarcode.startsWith('0')) {
      res = await db.query(
        'products',
        where: 'barcode = ?',
        whereArgs: [cleanBarcode.substring(1)],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return ProductModel.fromMap(res.first);
      }
    }

    return null;
  }

  /// Detect country of origin from barcode using GS1 prefix standard
  Future<CountryPrefixModel?> getCountryPrefix(String barcode) async {
    final clean = barcode.trim();
    if (clean.length < 3) return null;

    final db = await database;
    final prefix3 = clean.substring(0, 3);

    try {
      final res = await db.query(
        'country_prefixes',
        where: 'prefix = ?',
        whereArgs: [prefix3],
        limit: 1,
      );

      if (res.isNotEmpty) {
        return CountryPrefixModel.fromMap(res.first);
      }
    } catch (_) {}

    return null;
  }

  /// Fetch local alternatives for a given product
  Future<List<AlternativeModel>> getAlternatives(String productId) async {
    final db = await database;

    final query = '''
      SELECT 
        a.note_ar,
        a.note_en,
        a.rating,
        p.id,
        p.barcode,
        p.name_ar,
        p.name_en,
        p.company_name,
        p.country_of_origin,
        p.category_id,
        p.status,
        p.reason_ar,
        p.reason_en,
        p.image_url,
        p.is_featured,
        p.created_at
      FROM product_alternatives a
      JOIN products p ON a.alternative_product_id = p.id
      WHERE a.product_id = ?
      ORDER BY a.rating DESC;
    ''';

    final res = await db.rawQuery(query, [productId]);
    return res.map((row) {
      final product = ProductModel.fromMap(row);
      return AlternativeModel.fromMap(row, product);
    }).toList();
  }

  /// Instant search using FTS5 with fallback to wildcard LIKE
  Future<List<ProductModel>> searchProducts(String query, {String? statusFilter}) async {
    final cleanQuery = query.trim();
    final db = await database;

    if (cleanQuery.isEmpty) {
      if (statusFilter != null && statusFilter.isNotEmpty) {
        final res = await db.query(
          'products',
          where: 'status = ?',
          whereArgs: [statusFilter],
          orderBy: 'is_featured DESC, name_ar ASC',
          limit: 30,
        );
        return res.map((m) => ProductModel.fromMap(m)).toList();
      }
      return getFeaturedProducts();
    }

    try {
      // 1. Try FTS5 prefix match
      final ftsQuery = '$cleanQuery*';
      final statusClause = statusFilter != null ? "AND p.status = '$statusFilter'" : '';
      final ftsRes = await db.rawQuery('''
        SELECT p.* FROM products_fts f
        JOIN products p ON f.rowid = p.rowid
        WHERE products_fts MATCH ? $statusClause
        LIMIT 40;
      ''', [ftsQuery]);

      if (ftsRes.isNotEmpty) {
        return ftsRes.map((m) => ProductModel.fromMap(m)).toList();
      }
    } catch (_) {
      // Fallback if FTS syntax error
    }

    // 2. Wildcard fallback
    final likeTerm = '%$cleanQuery%';
    final statusClause = statusFilter != null ? "AND status = '$statusFilter'" : '';
    final fallbackRes = await db.rawQuery('''
      SELECT * FROM products
      WHERE (name_ar LIKE ? OR name_en LIKE ? OR company_name LIKE ?) $statusClause
      ORDER BY is_featured DESC, name_ar ASC
      LIMIT 40;
    ''', [likeTerm, likeTerm, likeTerm]);

    return fallbackRes.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Fetch all categories
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final res = await db.query('categories', orderBy: 'sort_order ASC');
    return res.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Fetch products belonging to a category
  Future<List<ProductModel>> getProductsByCategory(String categoryId) async {
    final db = await database;
    final res = await db.query(
      'products',
      where: 'category_id = ?',
      whereArgs: [categoryId],
      orderBy: 'is_featured DESC, name_ar ASC',
    );
    return res.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Get featured Egyptian brands
  Future<List<ProductModel>> getFeaturedProducts() async {
    final db = await database;
    final res = await db.query(
      'products',
      where: 'is_featured = 1 AND status = ?',
      whereArgs: ['safe_local'],
      orderBy: 'name_ar ASC',
      limit: 20,
    );
    return res.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Settings KV store
  Future<String?> getSetting(String key) async {
    final db = await database;
    try {
      final res = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: [key],
        limit: 1,
      );
      if (res.isNotEmpty) {
        return res.first['value'] as String?;
      }
    } catch (_) {}
    return null;
  }

  Future<void> setSetting(String key, String value) async {
    final db = await database;
    try {
      await db.insert(
        'app_settings',
        {'key': key, 'value': value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (_) {}
  }

  /// Insert crowdsourced pending submission
  Future<void> insertPendingSubmission(PendingSubmissionModel submission) async {
    final db = await database;
    await db.insert(
      'pending_submissions',
      submission.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Get pending submissions for syncing
  Future<List<PendingSubmissionModel>> getPendingSubmissions() async {
    final db = await database;
    final res = await db.query(
      'pending_submissions',
      where: 'status = ?',
      whereArgs: ['pending'],
    );
    return res.map((m) => PendingSubmissionModel.fromMap(m)).toList();
  }

  /// Mark submissions as synced
  Future<void> markSubmissionSynced(String id) async {
    final db = await database;
    await db.update(
      'pending_submissions',
      {'status': 'synced'},
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}
