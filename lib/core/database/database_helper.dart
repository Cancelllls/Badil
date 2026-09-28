import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../../data/models/category_model.dart';
import '../../data/models/product_model.dart';
import '../../data/models/alternative_model.dart';
import '../../data/models/pending_submission_model.dart';

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
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
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

  /// Fetch local Egyptian alternatives for a given boycotted product
  Future<List<AlternativeModel>> getAlternatives(String productId) async {
    final db = await database;

    final query = '''
      SELECT 
        a.note_ar,
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
  Future<List<ProductModel>> searchProducts(String query) async {
    final cleanQuery = query.trim();
    if (cleanQuery.isEmpty) {
      return getFeaturedProducts();
    }

    final db = await database;

    try {
      // 1. Try FTS5 prefix match
      final ftsQuery = '$cleanQuery*';
      final ftsRes = await db.rawQuery('''
        SELECT p.* FROM products_fts f
        JOIN products p ON f.rowid = p.rowid
        WHERE products_fts MATCH ?
        LIMIT 30;
      ''', [ftsQuery]);

      if (ftsRes.isNotEmpty) {
        return ftsRes.map((m) => ProductModel.fromMap(m)).toList();
      }
    } catch (_) {
      // Fallback if FTS syntax error
    }

    // 2. Wildcard fallback
    final likeTerm = '%$cleanQuery%';
    final fallbackRes = await db.rawQuery('''
      SELECT * FROM products
      WHERE name_ar LIKE ? OR name_en LIKE ? OR company_name LIKE ?
      ORDER BY is_featured DESC, name_ar ASC
      LIMIT 30;
    ''', [likeTerm, likeTerm, likeTerm]);

    return fallbackRes.map((m) => ProductModel.fromMap(m)).toList();
  }

  /// Get all categories
  Future<List<CategoryModel>> getCategories() async {
    final db = await database;
    final res = await db.query('categories', orderBy: 'sort_order ASC');
    return res.map((m) => CategoryModel.fromMap(m)).toList();
  }

  /// Get products by category
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
      limit: 15,
    );
    return res.map((m) => ProductModel.fromMap(m)).toList();
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
