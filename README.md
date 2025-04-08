
# Flutter Quotes App with ObjectBox

This is a simple Flutter project that displays and manages quotes using ObjectBox as the local database. ObjectBox is a high-performance NoSQL database for Flutter that provides easy integration and fast data storage and retrieval.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Installation](#installation)
3. [Setting Up ObjectBox](#setting-up-objectbox)
4. [Creating Models](#creating-models)
5. [Using ObjectBox for Data Storage](#using-objectbox-for-data-storage)
6. [CRUD Operations](#crud-operations)
7. [Running the App](#running-the-app)

---

## Getting Started

To run this Flutter project, you need to have Flutter and Dart installed on your local machine. If you don't have Flutter installed, follow the official installation guide from [flutter.dev](https://flutter.dev/docs/get-started/install).

Once Flutter is installed, make sure you have the latest version of ObjectBox by checking the [ObjectBox Flutter documentation](https://pub.dev/packages/objectbox).

---

## Installation

### 1. Add Dependencies

In the `pubspec.yaml` file, add the necessary dependencies for `objectbox` and the `objectbox_flutter_libs` plugin:

```yaml
dependencies:

  objectbox: ^4.1.0
  objectbox_flutter_libs: any

```

After adding these dependencies, run:

```bash
flutter pub get
```

### 2. Generate ObjectBox Files

After adding the dependencies, you need to generate the required ObjectBox files. To do this, you will use the `objectbox_generator` package.

First, in your `pubspec.yaml` file, add the following dev dependency:

```yaml
dev_dependencies:
  build_runner: ^2.4.15
  objectbox_generator: any
```

Then, run the following command to generate the ObjectBox files:

```bash
dart run build_runner build
```

This will generate code for your data models, enabling ObjectBox to handle data efficiently.

---

## Setting Up ObjectBox

To use ObjectBox in your Flutter project, you need to initialize the ObjectBox database in your application. First, create an `objectbox helper` class that will handle opening and closing the database.

Create a file named `objectbox_helper.dart` in the `lib/` directory:

```dart
mport 'dart:io';

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
```

In the `ObjectBox` class, we initialize the `Store` and the `Box` for storing `Quote` objects and `Author` objects.

---

## Creating Models

You will need to define the data models that will be stored in the ObjectBox database. For this app, we'll create a model.

Create a file named `model.dart` in the `lib/` directory:

```dart
import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

@Entity()
class Quote {
  @Id()
  int obxId = 0;

  String id;
  String text;
  DateTime createdAt;
  DateTime editedAt; 

  final author = ToOne<Author>();

  Quote({
    String? id,
    required this.text,
    Author? author,
    int? authorId,
    DateTime? createdAt,
    DateTime? editedAt,
  }) : id = id ?? const Uuid().v4(),
      createdAt = createdAt ?? DateTime.now(),
      editedAt = editedAt ?? DateTime.now() {
    if (text.isEmpty) throw ArgumentError('Quote text cannot be empty');
    if (author != null) {
      this.author.target = author;
    }
  }

  Quote copyWith({String? text, Author? author, DateTime? editedAt}) {
    return Quote(
      id: this.id,
      text: text ?? this.text,
      author: author ?? this.author.target!,
      createdAt: createdAt,
      editedAt: editedAt ?? DateTime.now(),
    );
  }

  String get formattedCreatedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
  String get formattedEditedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(editedAt);

  String get authorName => author.target?.name ?? 'Unknown Author';
}

@Entity()
class Author {
  @Id()
  int obxId = 0;

  String id;
  String name;
  DateTime createdAt;
  DateTime editedAt; 

  @Backlink('author')
  final quotes = ToMany<Quote>();

  Author({
    String? id,
    required this.name,
    DateTime? createdAt,
    DateTime? editedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       editedAt = editedAt ?? DateTime.now() {
    if (name.isEmpty) throw ArgumentError('Author name cannot be empty');
  }

  Author copyWith({String? name, DateTime? editedAt}) {
    return Author(
      id: id,
      name: name ?? this.name,
      createdAt: createdAt,
      editedAt: editedAt ?? DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Author && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  String get formattedCreatedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
  String get formattedEditedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(editedAt);
}
```

In this model we have two entities: `Quote` and `Author`.
- `@Entity()` annotation marks the class as a data model.
- `Quote` represents a quote with properties like `text`, `createdAt`, and `editedAt`. It also has a relationship with the `Author` entity.
- `Author` represents the author of a quote with properties like `name`, `createdAt`, and `editedAt`. It has a backlink to the `Quote` entity.
- `@Id()` annotation marks the field as the primary key.
- `@Backlink()` annotation creates a reverse relationship from `Quote` to `Author`.
- `ToOne` and `ToMany` are used to define one-to-one and one-to-many relationships, respectively.


Once the model is created, run the following command to generate the required code:

```bash
dart run build_runner build
```

---

## CRUD Operations


### **CRUD for Quote**
1. **Create**: Use `addQuote(text, author, authorId)` to add a new quote, where you can specify either an `Author` object or an `authorId`.
2. **Read**: Use `getAllQuotes()` to retrieve all quotes and `getQuotesByAuthor(author)` to fetch quotes by a specific author.
3. **Update**: Use `updateQuote(quote, text, author)` to modify the text and/or author of an existing quote.
4. **Delete**: Use `deleteQuote(quote)` to remove a quote from the database, and also detach it from its author.



### **CRUD for Author**
1. **Create**: Use `addAuthor(author)` to add a new author to the database.
2. **Read**: Use `getAllAuthors()` to retrieve all authors.
3. **Update**: Use `updateAuthor(author)` to modify the details of an existing author.
4. **Delete**: Use `deleteAuthor(author)` to remove an author and all their associated quotes from the database.


---

## Running the App

1. Ensure that you've set up ObjectBox and generated the necessary files.
2. Run the Flutter app using the following command:

```bash
flutter run
```

The app will show a list of quotes with options to add, edit, and delete quotes. You can also create authors and view quotes by specific authors.

---
