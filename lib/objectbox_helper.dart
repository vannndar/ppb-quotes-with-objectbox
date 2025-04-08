import 'dart:io';

import 'package:flutter/widgets.dart';

import 'objectbox.g.dart';
import 'package:path_provider/path_provider.dart';
import 'model.dart';
import 'objectbox.g.dart' as obx;

class ObjectBoxHelper {
  late final Store store;
  late final Box<Quote> quoteBox;
  late final Box<Author> authorBox;

  ObjectBoxHelper._create(this.store) {
    quoteBox = Box<Quote>(store);
    authorBox = Box<Author>(store);
  }

  static Future<ObjectBoxHelper> create() async {
    final store = await _openStoreWithRecovery();
    return ObjectBoxHelper._create(store);
  }

  static Future<Store> _openStoreWithRecovery() async {
    try {
      return await openStore();
    } on obx.SchemaException catch (_) {
      // For development only - delete old database
      final dir = await getApplicationDocumentsDirectory();
      final dbDir = Directory('${dir.path}/objectbox');
      if (await dbDir.exists()) {
        await dbDir.delete(recursive: true);
      }
      return await openStore();
    }
  }

  List<Quote> getAllQuotes() => quoteBox.getAll();
  void addQuote(String textQuote, {Author? author, int? authorId}) {
    store.runInTransaction(TxMode.write, () {
      if (author != null && author.obxId == 0) {
        authorBox.put(author);
        authorId = author.obxId;
      }
      
      if (authorId == null && author == null) {
        throw ArgumentError('Either author or authorId must be provided');
      }

      final newQuote = Quote(
        text: textQuote,
        author: author,
        authorId: authorId,
      );
      
      quoteBox.put(newQuote);
    });
  }
  void updateQuote(Quote quote, String? text, Author? author) {
    if (author?.obxId != quote.author.target?.obxId) {
      quote.author.target?.quotes.remove(quote);
      author?.quotes.add(quote);
    }

    if (text != null) quote.text = text;
    if (author != null) quote.author.target = author;
    quote.editedAt = DateTime.now();
    
    quoteBox.put(quote);
  }

  void deleteQuote(Quote quote) {
    quote.author.target?.quotes.remove(quote);
    quoteBox.remove(quote.obxId);
  }
  
  List<Author> getAllAuthors() => authorBox.getAll();
  void addAuthor(Author author) => authorBox.put(author);
  void updateAuthor(Author author) => authorBox.put(author);
  void deleteAuthor(Author author) {
    final quotes = author.quotes;
    for (var quote in quotes) {
      quoteBox.remove(quote.obxId);
    }

    authorBox.remove(author.obxId);
  }

  List<Quote> getQuotesByAuthor(Author author) {
    final query = quoteBox.query(Quote_.author.equals(author.obxId)).build();
    final results = query.find();
    query.close();
    return results;
  }
}