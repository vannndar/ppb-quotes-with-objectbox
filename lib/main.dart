import 'package:flutter/material.dart';
import 'objectbox_helper.dart';
import 'model.dart';
import 'quote_card.dart';

import 'author_quotes_page.dart';

void main() => runApp(const MaterialApp(home: QuoteList()));

enum SortOption { newest, oldest, recentlyEdited }

class QuoteList extends StatefulWidget {
  const QuoteList({Key? key}) : super(key: key);

  @override
  _QuoteListState createState() => _QuoteListState();
}

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

  List<Quote> quotes = [
  ];

  SortOption currentSortOption = SortOption.newest;


  List<Quote> get sortedQuotes {
    switch (currentSortOption) {
      case SortOption.newest:
        return quotes.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case SortOption.oldest:
        return quotes.toList()
          ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case SortOption.recentlyEdited:
        return quotes.toList()
          ..sort((a, b) => b.editedAt.compareTo(a.editedAt));
    }
  }

  void _naviagetToAutorQuotes(){
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AuthorQuotesPage(objectBoxHelper: objectBoxHelper),
      ),
    ).then((_) {
      setState(() {
        quotes = objectBoxHelper.getAllQuotes();
      });
    });
  }

  void _showAddQuoteDialog() {
    final textController = TextEditingController();
    Author? selectedAuthor;
    List<Author> authors = objectBoxHelper.getAllAuthors();

    if (authors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add an author first')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(  // Add StatefulBuilder here
          builder: (context, setState) {  // This setState is local to the dialog
            return AlertDialog(
              title: const Text('Add New Quote'),
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
                    value: selectedAuthor,
                    onChanged: (Author? newValue) {
                      setState(() {  // This setState updates the dialog
                        selectedAuthor = newValue;
                      });
                    },
                    items: authors.map((Author author) {
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
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (textController.text.isNotEmpty && selectedAuthor != null) {
                      objectBoxHelper.addQuote(textController.text, author: selectedAuthor!);
                      this.setState(() {  // Use the original setState to update the parent
                        quotes = objectBoxHelper.getAllQuotes();
                      });
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          }
        );
      },
    );
  }

  void _deleteQuote(Quote quote) {
    objectBoxHelper.deleteQuote(quote);
    setState(() {
      quotes = objectBoxHelper.getAllQuotes();
    });
  }


  void _showUpdateQuoteDialog(Quote quote) {
    final textController = TextEditingController(text: quote.text);
    Author? selectedAuthor = quote.author.target;
    List<Author> authors = objectBoxHelper.getAllAuthors();

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
                    value: selectedAuthor,
                    onChanged: (Author? newValue) {
                      setDialogState(() {
                        selectedAuthor = newValue;
                      });
                    },
                    items: authors.map((Author author) {
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
                    debugPrint('Selected author: $selectedAuthor');
                    debugPrint('Quote text: ${textController.text}');
                    if (textController.text.isNotEmpty && selectedAuthor != null) {
                      // First close the dialog
                      Navigator.pop(dialogContext);
                      
                      // Then update the quote and refresh the UI
                      objectBoxHelper.updateQuote(quote, textController.text, selectedAuthor!);
                      setState(() {
                        quotes = objectBoxHelper.getAllQuotes();
                      });
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

  void _showAddAuthorDialog() {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add New Author'),
          content: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: 'Author Name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newAuthor = Author(name: nameController.text);
                  objectBoxHelper.addAuthor(newAuthor);
                  Navigator.pop(context);
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      appBar: AppBar(
        title: const Text('Awesome Quotes'),
        centerTitle: true,
        backgroundColor: Colors.teal,
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            tooltip: 'Quotes by Author',
            onPressed: _naviagetToAutorQuotes,
            color: Colors.amber,
          ),
          DropdownButton<SortOption>(
            dropdownColor: Colors.white,
            value: currentSortOption,
            onChanged: (SortOption? newValue) {
              if (newValue != null) {
                setState(() {
                  currentSortOption = newValue;
                });
              }
            },
            items:
                SortOption.values.map((SortOption option) {
                  return DropdownMenuItem<SortOption>(
                    value: option,
                    child: Text(
                      option.toString().split('.').last,
                      style: const TextStyle(color: Colors.black),
                    ),
                  );
                }).toList(),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: sortedQuotes.asMap().entries.map((entry) {
            final quote = entry.value;
            // Use a combination of ID and timestamp for a more unique key
            return QuoteCard(
              key: ValueKey('${quote.id}-${quote.editedAt.millisecondsSinceEpoch}'),
              quote: quote,
              delete: () => _deleteQuote(quote),
              edit: () => _showUpdateQuoteDialog(quote),
            );
          }).toList(),
        ),
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (_isFabOpen) ...[
            FloatingActionButton(
              heroTag: 'addAuthor',
              onPressed: () {
                setState(() => _isFabOpen = false);
                _showAddAuthorDialog();
              },
              child: const Icon(Icons.person_add),
              backgroundColor: Colors.lightBlueAccent,
              mini: true,
            ),
            const SizedBox(height: 16),
            FloatingActionButton(
              heroTag: 'addQuote',
              onPressed: () {
                setState(() => _isFabOpen = false);
                _showAddQuoteDialog();
              },
              child: const Icon(Icons.format_quote),
              backgroundColor: Colors.tealAccent,
              mini: true,
            ),
            const SizedBox(height: 16),
          ],
          FloatingActionButton(
            heroTag: 'mainFab',
            onPressed: () {
              setState(() => _isFabOpen = !_isFabOpen);
            },
            child: Icon(_isFabOpen ? Icons.close : Icons.add),
            backgroundColor: _isFabOpen ? Colors.grey : Colors.teal,
          ),
        ],
      ),
    );
  }
}
