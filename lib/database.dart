import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DbHelper {
  static Database? _db;
  static const String dbName = 'warisan_nusantara.db';
  static const String userTable = 'users';

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    String path = join(await getDatabasesPath(), dbName);
    return await openDatabase(
      path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  // Dipanggil saat install pertama kali (fresh install)
  Future<void> _onCreate(Database db, int version) async {
    await _createUserTable(db);
    await _createScoresTable(db);
    await _createCategoriesTable(db);
    await _createCollectionsTable(db);
    await _createFactsTable(db);
    await _seedCategories(db);
    await _seedCollections(db);
    await _seedFacts(db);
  }

  // Dipanggil saat DB sudah ada tapi versinya lebih lama
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 3) {
      await db.execute(
        "ALTER TABLE collections ADD COLUMN image_path TEXT NOT NULL DEFAULT ''",
      );
      await _seedImagePaths(db);
    }

    if (oldVersion < 4) {
      await _createFactsTable(db);
      await _seedFacts(db);
    }
  }

  // ── Table Creators ────────────────────────────────────────

  Future<void> _createUserTable(Database db) async {
    await db.execute('''
      CREATE TABLE $userTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fullName TEXT,
        username TEXT UNIQUE,
        password TEXT
      )
    ''');
  }

  Future<void> _createScoresTable(Database db) async {
    await db.execute('''
      CREATE TABLE scores (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        score INTEGER,
        date TEXT
      )
    ''');
  }

  Future<void> _createCategoriesTable(Database db) async {
    await db.execute('''
      CREATE TABLE categories (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL UNIQUE
      )
    ''');
  }

  // Tabel collections versi terbaru — sudah ada kolom image_path
  Future<void> _createCollectionsTable(Database db) async {
    await db.execute('''
      CREATE TABLE collections (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        name TEXT NOT NULL,
        location TEXT NOT NULL,
        description TEXT,
        color_hex TEXT NOT NULL,
        image_path TEXT NOT NULL DEFAULT ''
      )
    ''');
  }

  // Tabel facts
  Future<void> _createFactsTable(Database db) async {
    await db.execute('''
    CREATE TABLE facts (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      content TEXT NOT NULL
    )
  ''');
  }

  // ── Seed Data ─────────────────────────────────────────────

  Future<void> _seedCategories(Database db) async {
    final categories = ["Semua", "Batik", "Tari", "Kuliner", "Musik"];
    for (final cat in categories) {
      await db.insert('categories', {'name': cat});
    }
  }

  // Seed lengkap dengan image_path (untuk fresh install / onCreate)
  // Pastikan nama file sesuai dengan yang ada di folder assets/images/
  Future<void> _seedCollections(Database db) async {
    final collections = [
      // ── Batik ──
      {
        'category': 'Batik',
        'name': 'Kawung',
        'location': 'Yogyakarta',
        'description':
            'Motif geometris berbentuk bulatan menyerupai buah kolang-kaling.',
        'color_hex': 'FFF5E1',
        'image_path': 'assets/images/batik_kawung.jpg',
      },
      {
        'category': 'Batik',
        'name': 'Parang Rusak',
        'location': 'Solo',
        'description': 'Motif diagonal melambangkan semangat pantang menyerah.',
        'color_hex': 'FFF5E1',
        'image_path': 'assets/images/batik_parang_rusak.jpg',
      },
      {
        'category': 'Batik',
        'name': 'Mega Mendung',
        'location': 'Cirebon',
        'description':
            'Motif awan bergaya Tiongkok yang khas dari pesisir utara Jawa.',
        'color_hex': 'FFF5E1',
        'image_path': 'assets/images/batik_mega_mendung.jpg',
      },
      // ── Tari ──
      {
        'category': 'Tari',
        'name': 'Saman',
        'location': 'Aceh',
        'description':
            'Tarian massal dengan gerakan serentak yang menakjubkan dari Gayo.',
        'color_hex': 'FCE4EC',
        'image_path': 'assets/images/tari_saman.jpg',
      },
      {
        'category': 'Tari',
        'name': 'Kecak',
        'location': 'Bali',
        'description':
            'Tarian sakral yang mengisahkan Ramayana dengan iringan vokal cak.',
        'color_hex': 'FCE4EC',
        'image_path': 'assets/images/tari_kecak.jpg',
      },
      {
        'category': 'Tari',
        'name': 'Bedhaya',
        'location': 'Yogyakarta',
        'description':
            'Tarian keraton yang sarat makna spiritual dan filosofi Jawa.',
        'color_hex': 'FCE4EC',
        'image_path': 'assets/images/tari_bedhaya.jpg',
      },
      // ── Kuliner ──
      {
        'category': 'Kuliner',
        'name': 'Rendang',
        'location': 'Sumatera Barat',
        'description':
            'Masakan daging berbumbu rempah yang diakui dunia sebagai terlezat.',
        'color_hex': 'FFF3E0',
        'image_path': 'assets/images/kuliner_rendang.jpg',
      },
      {
        'category': 'Kuliner',
        'name': 'Gudeg',
        'location': 'Yogyakarta',
        'description':
            'Masakan berbahan nangka muda dengan cita rasa manis khas Jogja.',
        'color_hex': 'FFF3E0',
        'image_path': 'assets/images/kuliner_gudeg.jpg',
      },
      {
        'category': 'Kuliner',
        'name': 'Soto Betawi',
        'location': 'DKI Jakarta',
        'description':
            'Soto berkuah santan gurih dengan isian daging sapi dan jeroan.',
        'color_hex': 'FFF3E0',
        'image_path': 'assets/images/kuliner_soto_betawi.jpg',
      },
      // ── Musik ──
      {
        'category': 'Musik',
        'name': 'Angklung',
        'location': 'Jawa Barat',
        'description':
            'Alat musik bambu yang diakui UNESCO sebagai warisan tak benda dunia.',
        'color_hex': 'E0F2F1',
        'image_path': 'assets/images/musik_angklung.jpg',
      },
      {
        'category': 'Musik',
        'name': 'Gamelan',
        'location': 'Jawa Tengah',
        'description':
            'Orkestra tradisional dengan instrumen perkusi logam yang harmonis.',
        'color_hex': 'E0F2F1',
        'image_path': 'assets/images/musik_gamelan.jpg',
      },
      {
        'category': 'Musik',
        'name': 'Sasando',
        'location': 'Nusa Tenggara Timur',
        'description':
            'Alat musik petik berbentuk seperti bunga dari daun lontar.',
        'color_hex': 'E0F2F1',
        'image_path': 'assets/images/musik_sasando.jpg',
      },
    ];
    for (final item in collections) {
      await db.insert('collections', item);
    }
  }

  // Seed lengkap facts
  Future<void> _seedFacts(Database db) async {
    final facts = [
      {"content": "Angklung diakui UNESCO sejak 2010 🎶"},
      {"content": "Borobudur adalah candi Buddha terbesar di dunia 🏛️"},
      {"content": "Batik diakui UNESCO tahun 2009 🎨"},
      {"content": "Indonesia punya 700+ bahasa daerah 🗣️"},
      {"content": "Tari Saman disebut Tarian Seribu Tangan 💃"},
      {"content": "Wayang kulit termasuk warisan dunia 🎭"},
      {"content": "Rendang pernah jadi makanan terenak dunia 🌶️"},
      {"content": "Sasando berasal dari NTT 🎵"},
      {"content": "Gamelan dimainkan di upacara adat Jawa 🎼"},
      {"content": "Rumah Tongkonan berasal dari Toraja 🏠"},
    ];

    for (final fact in facts) {
      await db.insert('facts', fact);
    }
  }

  // Dipanggil saat upgrade dari v2 → v3
  // Update image_path untuk baris yang sudah ada berdasarkan name
  Future<void> _seedImagePaths(Database db) async {
    final imageMap = {
      'Kawung': 'assets/images/batik_kawung.jpg',
      'Parang Rusak': 'assets/images/batik_parang_rusak.jpg',
      'Mega Mendung': 'assets/images/batik_mega_mendung.jpg',
      'Saman': 'assets/images/tari_saman.jpg',
      'Kecak': 'assets/images/tari_kecak.jpg',
      'Bedhaya': 'assets/images/tari_bedhaya.jpg',
      'Rendang': 'assets/images/kuliner_rendang.jpg',
      'Gudeg': 'assets/images/kuliner_gudeg.jpg',
      'Soto Betawi': 'assets/images/kuliner_soto_betawi.jpg',
      'Angklung': 'assets/images/musik_angklung.jpg',
      'Gamelan': 'assets/images/musik_gamelan.jpg',
      'Sasando': 'assets/images/musik_sasando.jpg',
    };
    for (final entry in imageMap.entries) {
      await db.update(
        'collections',
        {'image_path': entry.value},
        where: 'name = ?',
        whereArgs: [entry.key],
      );
    }
  }

  // ── User Methods (tidak berubah) ──────────────────────────

  Future<int> saveUser(Map<String, dynamic> user) async {
    var dbClient = await db;
    return await dbClient.insert(userTable, user);
  }

  Future<Map<String, dynamic>?> checkLogin(String user, String pass) async {
    var dbClient = await db;
    var res = await dbClient.query(
      userTable,
      where: "username = ? AND password = ?",
      whereArgs: [user, pass],
    );
    if (res.isNotEmpty) return res.first;
    return null;
  }

  // ── Score Methods (tidak berubah) ─────────────────────────

  Future<void> saveHighScore(int score) async {
    var dbClient = await db;
    await dbClient.insert('scores', {
      'score': score,
      'date': DateTime.now().toString(),
    });
  }

  Future<int> getBestScore() async {
    var dbClient = await db;
    var res = await dbClient.rawQuery(
      "SELECT MAX(score) as max_score FROM scores",
    );
    return res.first['max_score'] as int? ?? 0;
  }

  // ── Category Methods ──────────────────────────────────────

  Future<List<String>> getCategories() async {
    var dbClient = await db;
    final result = await dbClient.query('categories', orderBy: 'id ASC');
    return result.map((row) => row['name'] as String).toList();
  }

  // ── Collection Methods ────────────────────────────────────

  Future<List<Map<String, dynamic>>> getCollections({
    String category = 'Semua',
  }) async {
    var dbClient = await db;
    if (category == 'Semua') {
      return await dbClient.query('collections', orderBy: 'category ASC');
    }
    return await dbClient.query(
      'collections',
      where: 'category = ?',
      whereArgs: [category],
    );
  }

  Future<int> insertCollection(Map<String, dynamic> data) async {
    var dbClient = await db;
    return await dbClient.insert('collections', data);
  }

  Future<int> deleteCollection(int id) async {
    var dbClient = await db;
    return await dbClient.delete(
      'collections',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getFacts() async {
    var dbClient = await db;
    return await dbClient.query('facts');
  }
}
