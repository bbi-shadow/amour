import 'dart:async';
import 'dart:io';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

/// DatabaseHelper — SQLite local cache
/// Bảng: profile (hồ sơ bản thân) + cached_photos (ảnh đã tải về)
class DatabaseHelper {
  static Database? _db;
  static Completer<Database>? _completer;

  static Future<Database> get _database async {
    if (_db != null) return _db!;
    if (_completer != null) return _completer!.future;

    _completer = Completer<Database>();
    try {
      _db = await _initDB();
      _completer!.complete(_db!);
    } catch (e) {
      _completer!.completeError(e);
      _completer = null;
      rethrow;
    }
    return _db!;
  }

  static Future<Database> _initDB() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = join(dir.path, 'amour.db');
    return await openDatabase(
      path,
      version: 3, // ✅ v3: thêm bảng cached_photos
      onCreate: (db, version) async {
        // Bảng hồ sơ bản thân
        await db.execute('''
          CREATE TABLE profile (
            uid        TEXT PRIMARY KEY,
            name       TEXT,
            age        INTEGER,
            bio        TEXT,
            city       TEXT,
            gender     TEXT,
            photo_path TEXT,
            updated_at INTEGER
          )
        ''');
        // Bảng cache ảnh user khác
        await db.execute('''
          CREATE TABLE cached_photos (
            uid        TEXT PRIMARY KEY,
            photo_path TEXT NOT NULL,
            photo_url  TEXT,
            cached_at  INTEGER NOT NULL
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE profile ADD COLUMN city TEXT DEFAULT ""');
          await db.execute('ALTER TABLE profile ADD COLUMN gender TEXT DEFAULT ""');
        }
        if (oldVersion < 3) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS cached_photos (
              uid        TEXT PRIMARY KEY,
              photo_path TEXT NOT NULL,
              photo_url  TEXT,
              cached_at  INTEGER NOT NULL
            )
          ''');
        }
      },
    );
  }

  // ══════════════════════════════════════════
  //  PROFILE (hồ sơ bản thân)
  // ══════════════════════════════════════════

  static Future<void> saveProfile({
    required String uid,
    required String name,
    required int age,
    required String bio,
    String? city,
    String? gender,
    String? photoPath,
  }) async {
    final db = await _database;
    await db.insert(
      'profile',
      {
        'uid': uid,
        'name': name,
        'age': age,
        'bio': bio,
        'city': city ?? '',
        'gender': gender ?? '',
        'photo_path': photoPath ?? '',
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getProfile(String uid) async {
    final db = await _database;
    final rows = await db.query(
      'profile',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    return rows.isNotEmpty ? rows.first : null;
  }

  static Future<void> deleteProfile(String uid) async {
    final db = await _database;
    final rows = await db.query(
      'profile',
      columns: ['photo_path'],
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final path = rows.first['photo_path'] as String? ?? '';
      if (path.isNotEmpty) {
        final file = File(path);
        if (await file.exists()) await file.delete();
      }
    }
    await db.delete('profile', where: 'uid = ?', whereArgs: [uid]);
  }

  // ══════════════════════════════════════════
  //  CACHED PHOTOS (ảnh user khác tải về local)
  // ══════════════════════════════════════════

  /// Lấy path ảnh đã cache (null nếu chưa cache hoặc file đã bị xoá)
  static Future<String?> getCachedPhotoPath(String uid) async {
    final db = await _database;
    final rows = await db.query(
      'cached_photos',
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    final path = rows.first['photo_path'] as String? ?? '';
    if (path.isEmpty) return null;
    // Kiểm tra file vẫn còn tồn tại
    if (await File(path).exists()) return path;
    // File mất → xoá record
    await db.delete('cached_photos', where: 'uid = ?', whereArgs: [uid]);
    return null;
  }

  /// Tải ảnh từ URL về local rồi lưu vào cache
  /// Trả về path local, null nếu thất bại
  static Future<String?> downloadAndCachePhoto(String uid, String photoUrl) async {
    if (photoUrl.isEmpty) return null;

    try {
      // Kiểm tra đã cache chưa và URL còn khớp không
      final db = await _database;
      final existing = await db.query(
        'cached_photos',
        where: 'uid = ? AND photo_url = ?',
        whereArgs: [uid, photoUrl],
        limit: 1,
      );
      if (existing.isNotEmpty) {
        final path = existing.first['photo_path'] as String? ?? '';
        if (path.isNotEmpty && await File(path).exists()) return path;
      }

      // Tải ảnh
      final response = await http.get(Uri.parse(photoUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      // Lưu file
      final dir = await getApplicationDocumentsDirectory();
      final cacheDir = Directory(join(dir.path, 'photo_cache'));
      if (!await cacheDir.exists()) await cacheDir.create(recursive: true);

      final filePath = join(cacheDir.path, 'photo_$uid.jpg');
      await File(filePath).writeAsBytes(response.bodyBytes);

      // Lưu vào DB
      await db.insert(
        'cached_photos',
        {
          'uid': uid,
          'photo_path': filePath,
          'photo_url': photoUrl,
          'cached_at': DateTime.now().millisecondsSinceEpoch,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return filePath;
    } catch (_) {
      return null;
    }
  }

  /// Xoá cache ảnh của một user
  static Future<void> deleteCachedPhoto(String uid) async {
    final db = await _database;
    final rows = await db.query(
      'cached_photos',
      columns: ['photo_path'],
      where: 'uid = ?',
      whereArgs: [uid],
      limit: 1,
    );
    if (rows.isNotEmpty) {
      final path = rows.first['photo_path'] as String? ?? '';
      if (path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    }
    await db.delete('cached_photos', where: 'uid = ?', whereArgs: [uid]);
  }

  /// Xoá toàn bộ cache ảnh cũ hơn [days] ngày
  static Future<void> clearOldPhotoCache({int days = 7}) async {
    final db = await _database;
    final cutoff = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final old = await db.query(
      'cached_photos',
      columns: ['photo_path'],
      where: 'cached_at < ?',
      whereArgs: [cutoff],
    );
    for (final row in old) {
      final path = row['photo_path'] as String? ?? '';
      if (path.isNotEmpty) {
        final f = File(path);
        if (await f.exists()) await f.delete();
      }
    }
    await db.delete('cached_photos', where: 'cached_at < ?', whereArgs: [cutoff]);
  }
}