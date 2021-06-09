import 'dart:io';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voc_journal/pages/bookmarks.dart';
import 'package:voc_journal/sm2.dart';

final DateFormat format = DateFormat('yyyy-MM-dd HH:mm:ss');

class Bookmark {
  int? id;
  String word;
  int repetition;
  int interval;
  double easeFactor;
  DateTime nextShowDate;
  DateTime createdAt;

  Bookmark(this.word, this.repetition, this.interval, this.easeFactor,
      this.nextShowDate, this.createdAt,
      {this.id});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'word': word,
      'repetition': repetition,
      'interval': interval,
      'ease_factor': easeFactor,
      'next_show_date': format.format(nextShowDate.toUtc()),
      'created_at': format.format(createdAt.toUtc()),
    };
  }

  factory Bookmark.fromMap(Map<String, dynamic> data) {
    return Bookmark(
        data['word'],
        data['repetition'],
        data['interval'],
        data['ease_factor'],
        DateTime.parse(data['next_show_date'] + 'Z'),
        DateTime.parse(data['created_at'] + 'Z'),
        id: data['id']);
  }

  @override
  String toString() {
    return ' id: $id\nword: $word';
  }
}

enum WordType {
  adverb,
  adjective,
  verb,
  noun,
}

extension ParseToString on WordType {
  String toShortString() {
    return this.toString().split('.').last;
  }
}

class WordDefinition {
  String definition;
  WordType wordType;
  List<String> synonyms;
  List<String> examples;

  WordDefinition(this.definition, this.wordType, this.synonyms, this.examples);

  static WordType parseWordType(String type) {
    switch (type) {
      case 'n':
        return WordType.noun;
      case 'v':
        return WordType.verb;
      case 'a':
        return WordType.adverb;
      case 'r':
      case 's':
        return WordType.adjective;
    }
    throw NullThrownError();
  }
}

class Definition {
  String word;
  List<WordDefinition> definitions = [];

  Definition(
    this.word,
    this.definitions,
  );
}

class DBProvider {
  DBProvider._();

  static final DBProvider db = DBProvider._();
  Database? _database;

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await initDb();
    return _database!;
  }

  initDb() async {
    var databasesPath = await getDatabasesPath();
    var path = join(databasesPath, "dict.db");

    // File(path).deleteSync();
    // print("Done deleting");

    // Check if the database exists
    var exists = await databaseExists(path);

    if (!exists) {
      // Should happen only the first time you launch your application
      print("Creating new copy from asset");

      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}

      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "dict.db"));
      List<int> bytes =
          data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
      print("done writing");
    } else {
      print("Opening existing database");
    }
    // open the database
    return openDatabase(path, version: 1, readOnly: false);
  }

  // search for a word from the db
  Future<List<String>> searchWord(String word) async {
    var db = await database;

    if (word.isEmpty) return [];

    List<Map<String, dynamic>> searchResults = await db.rawQuery(
        "select distinct(word) from wn_synset where word like '$word%' order by length(word) limit 20");

    return searchResults.map<String>((s) => s['word']).toList();
  }

  // get word from db
  Future<Definition> getWord(word) async {
    var db = await database;

    List<Map<String, dynamic>> wordResults = await db.rawQuery("""
      select w.word, w.ss_type, g.gloss, group_concat(wsyn.word, ",") synonyms
      from wn_synset w
      join wn_gloss g on g.synset_id = w.synset_id
      join wn_synset wsyn on wsyn.synset_id = w.synset_id
      where w.word = '$word'
      group by w.synset_id;
    """);

    List<WordDefinition> definitions = [];

    for (var result in wordResults) {
      List<String> glossary = result['gloss'].split(";");
      String definition = glossary[0];
      List<String> examples = glossary
          .getRange(1, glossary.length)
          .map((s) => s.trim())
          .where((s) => s.length > 2)
          .map((s) => s.substring(2, s.length - 2))
          .toList();
      WordType wordType = WordDefinition.parseWordType(result['ss_type']);
      List<String> synonyms = (result['synonyms'] as String)
          .split(",")
          .where((wrd) => wrd != word)
          .toList();

      definitions.add(WordDefinition(definition, wordType, synonyms, examples));
    }

    return Definition(word, definitions);
  }

  Future<Bookmark> addBookmark(String word) async {
    final db = await database;
    var bookmark = Bookmark(word, 0, 0, 2.5, DateTime.now(), DateTime.now());
    var result = await db.insert("bookmarks", bookmark.toMap());
    bookmark.id = result;
    return bookmark;
  }

  Future<void> deleteBookmark(word) async {
    final db = await database;
    await db.delete("bookmarks", where: 'word = ?', whereArgs: [word]);
  }

  Future<List<Bookmark>> getAllBookmarks(SortMethod sortMethod) async {
    final db = await database;
    var orderByClause =
        sortMethod == SortMethod.alpha ? 'word asc' : 'created_at desc';
    var results = await db.query("bookmarks", orderBy: orderByClause);

    return results.map((word) => Bookmark.fromMap(word)).toList();
  }

  Future<List<Bookmark>> getRevisableWords() async {
    final db = await database;

    var results = await db.query("bookmarks",
        where: 'next_show_date <= CURRENT_TIMESTAMP');

    return results.map((data) => Bookmark.fromMap(data)).toList();
  }

  reviseBookmark(int id, SmResponse resp) async {
    final db = await database;

    db.update(
        'bookmarks',
        {
          "repetition": resp.repetitions,
          "interval": resp.interval,
          "ease_factor": resp.easeFactor,
          "next_show_date": format.format(
              DateTime.now().add(Duration(days: resp.interval)).toUtc()),
        },
        where: 'id = ?',
        whereArgs: [id]);
  }
}
