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
      version: 6,
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
          'owned_count': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }
}