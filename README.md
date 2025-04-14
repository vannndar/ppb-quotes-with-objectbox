
# Flutter Quotes App with ObjectBox

This is a simple Flutter project that displays and manages quotes using ObjectBox as the local database. ObjectBox is a high-performance NoSQL database for Flutter that provides easy integration and fast data storage and retrieval.

## Table of Contents
1. [Getting Started](#getting-started)
2. [Installation](#installation)
3. [Setting Up ObjectBox](#setting-up-objectbox)
4. [Creating Models](#creating-models)
5. [Using ObjectBox for Data Storage](#using-objectbox-for-data-storage)
6. [Code Explanation](#code-explanation)
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

Here’s the additional section with explanations for `main.dart`, `author_quotes_page.dart`, and `quote_card.dart`:

---

## Code Explanation

### **main.dart**

`main.dart` is the entry point for the app and handles the display and management of quotes.

- **QuoteList Widget**: This widget is the main screen where all quotes are shown. It provides functionality to sort quotes by date or most recent edits and navigate to the AuthorQuotesPage to view quotes by a specific author.
  
- **State Management**: `StatefulWidget` is used here to dynamically update the list of quotes when they are added, updated, or deleted.

- **Floating Action Button (FAB)**: The FAB is used to toggle between showing options to add a new quote or author.

```dart
class _QuoteListState extends State<QuoteList> {
  late ObjectBoxHelper objectBoxHelper;
  bool isInitialized = false;
  bool _isFabOpen = false;

  @override
  void initState() {
    super.initState();
    ObjectBoxHelper.create().then((helper) {
      setState(() {
        objectBoxHelper = helper;
        quotes = objectBoxHelper.getAllQuotes();
        isInitialized = true;
      });
    });
  }

  List<Quote> quotes = [];
  // Sorting options based on created or edited dates
  List<Quote> get sortedQuotes {
    switch (currentSortOption) {
      case SortOption.newest:
        return quotes.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldest:
        return quotes.toList()..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.recentlyEdited:
        return quotes.toList()..sort((a, b) => b.editedAt.compareTo(a.editedAt));
    }
  }
}
```

---

### **author_quotes_page.dart**

`author_quotes_page.dart` is the page where quotes from a specific author are displayed.

- **AuthorQuotesPage Widget**: Displays the quotes of a selected author and provides the ability to delete or edit those quotes.

- **Stateful Management**: This page uses `StatefulWidget` to reload the quotes when an author is selected.

- **Quote Management**: Functions to load, delete, and update quotes are included here.

```dart
class _AuthorQuotesPageState extends State<AuthorQuotesPage> {
  List<Author> authors = [];
  Author? selectedAuthor;
  List<Quote> authorQuotes = [];

  void _loadAuthorQuotes(Author author) {
    setState(() {
      selectedAuthor = author;
      authorQuotes = author.quotes.toList();
    });
  }

  void _deleteQuote(Quote quote) {
    widget.objectBoxHelper.deleteQuote(quote);
    if (selectedAuthor != null) {
      setState(() {
        authorQuotes = selectedAuthor!.quotes.toList();
      });
    }
  }

  void _showUpdateQuoteDialog(Quote quote) {
    final textController = TextEditingController(text: quote.text);
    Author? selectedAuthorForQuote = quote.author.target;
    List<Author> allAuthors = widget.objectBoxHelper.getAllAuthors();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setDialogState) {
            return AlertDialog(
              title: const Text('Update Quote'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: textController,
                    decoration: const InputDecoration(labelText: 'Quote'),
                    maxLines: 3,
                  ),
                  DropdownButton<Author>(
                    hint: const Text('Select Author'),
                    value: selectedAuthorForQuote,
                    onChanged: (Author? newValue) {
                      setDialogState(() {
                        selectedAuthorForQuote = newValue;
                      });
                    },
                    items: allAuthors.map((Author author) {
                      return DropdownMenuItem<Author>(
                        value: author,
                        child: Text(author.name),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty && selectedAuthorForQuote != null) {
                      Navigator.pop(dialogContext);
                      widget.objectBoxHelper.updateQuote(quote, textController.text, selectedAuthorForQuote!);
                      if (selectedAuthor != null) {
                        setState(() {
                          authorQuotes = selectedAuthor!.quotes.toList();
                        });
                      }
                    }
                  },
                  child: const Text('Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
```

---

### **quote_card.dart**

`quote_card.dart` defines the UI for displaying individual quotes in a card format.

- **QuoteCard Widget**: Displays the quote text, the author’s name, and the creation/edit date. It also includes buttons for editing and deleting the quote.

- **Edit/Delete Callbacks**: These callbacks are used to trigger the deletion or editing of a quote from the list.

```dart
class QuoteCard extends StatelessWidget {
  final Quote quote;
  final VoidCallback delete;
  final VoidCallback edit;
  final Color? cardColor;
  final TextStyle? textStyle;
  final TextStyle? authorStyle;

  const QuoteCard({
    Key? key,
    required this.quote,
    required this.delete,
    required this.edit,
    this.cardColor,
    this.textStyle,
    this.authorStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      color: cardColor ?? theme.cardColor,
      margin: const EdgeInsets.fromLTRB(16.0, 16.0, 16.0, 0),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              quote.text,
              style: textStyle ?? TextStyle(fontSize: 18.0, color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 6.0),
            Text(
              quote.authorName,
              style: authorStyle ?? TextStyle(fontSize: 14.0, color: Colors.grey[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Text('Created: ${quote.formattedCreatedAt}', style: TextStyle(fontSize: 10.0, color: Colors.grey[500])),
            if (quote.editedAt != quote.createdAt)
              Text('Edited: ${quote.formattedEditedAt}', style: TextStyle(fontSize: 10.0, color: Colors.grey[500])),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(onPressed: edit, label: const Text('Edit'), icon: const Icon(Icons.edit, size: 18)),
                const SizedBox(width: 8.0),
                TextButton.icon(onPressed: delete, label: const Text('Delete'), icon: const Icon(Icons.delete, size: 18)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
```

---

### Additional Notes
- The `main.dart` file controls the overall app's navigation, sorting of quotes, and interaction with the database.
- The `author_quotes_page.dart` focuses on handling the author-specific quotes and provides editing functionality.
- The `quote_card.dart` component is responsible for rendering each quote, displaying related information (such as the author and timestamps), and providing buttons for actions like editing or deleting the quote.

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
