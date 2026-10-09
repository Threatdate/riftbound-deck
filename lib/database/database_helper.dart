import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'card_data/origins_cards.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDB('rift_deck.db');
    return _database!;
  }

  Future<Database> _initDB(String fileName) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, fileName);

    return await openDatabase(
      path,
      version: 9,
      onCreate: _createDB,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _createDB(
      Database db,
      int version,
      ) async {
    await db.execute('''
      CREATE TABLE cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        number TEXT NOT NULL UNIQUE,
        series TEXT NOT NULL,
        type TEXT NOT NULL,
        color TEXT NOT NULL,
        rarity TEXT NOT NULL DEFAULT '',
        owned_count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE decks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE deck_cards (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        deck_id INTEGER NOT NULL,
        card_id INTEGER NOT NULL,
        count INTEGER NOT NULL DEFAULT 0
      )
    ''');

    await _insertInitialCards(db);
  }

  Future<void> _onUpgrade(
      Database db,
      int oldVersion,
      int newVersion,
      ) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS
        idx_cards_number
        ON cards(number)
      ''');
    }

    if (oldVersion < 3) {
      await _insertInitialCards(db);
    }

    if (oldVersion < 4) {
      await _insertInitialCards(db);
    }

    if (oldVersion < 5) {
      await _insertInitialCards(db);
    }

    if (oldVersion < 6) {
      await db.delete(
        'cards',
        where: 'number IN (?, ?, ?)',
        whereArgs: ['001', '002', '003'],
      );
    }

    if (oldVersion < 7) {
      await db.execute('''
        ALTER TABLE cards
        ADD COLUMN rarity TEXT NOT NULL DEFAULT ''
      ''');

      await _insertInitialCards(db);
    }

    if (oldVersion < 8) {
      await _insertInitialCards(db);
    }

    if (oldVersion < 9) {
      // 기존 데이터베이스에 남아 있는 미지정 등급 제거
      await db.update(
        'cards',
        {'rarity': ''},
        where: "rarity = '미지정'",
      );

      // 카드 데이터 파일의 등급 정보를 기존 카드에 반영
      await _insertInitialCards(db);
    }
  }

  Future<void> _insertInitialCards(Database db) async {
    for (final card in initialCards) {
      await db.insert(
        'cards',
        {
          'name': card['name'],
          'number': card['number'],
          'series': card['series'],
          'type': card['type'],
          'color': card['color'],
          'rarity': card['rarity'] ?? '',
          'owned_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );

      // 기존 카드의 보유 수량은 유지하고,
      // 카드 데이터에 등급이 있을 때만 등급을 갱신한다.
      if (card['rarity'] != null) {
        await db.update(
          'cards',
          {'rarity': card['rarity']},
          where: 'number = ?',
          whereArgs: [card['number']],
        );
      }
    }
  }
}