import 'package:flutter/material.dart';
import 'objectbox_helper.dart';
import 'quote.dart';
import 'quote_card.dart';

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

  void _showAddQuoteDialog() {
    final authorController = TextEditingController();
    final textController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
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
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
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
                if (textController.text.isNotEmpty && authorController.text.isNotEmpty) {
                  final newQuote = Quote(
                    author: authorController.text,
                    text: textController.text,
                  );
                  objectBoxHelper.addQuote(newQuote);
                  setState(() {
                    quotes = objectBoxHelper.getAllQuotes();
                  });
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

  void _deleteQuote(Quote quote) {
    objectBoxHelper.deleteQuote(quote);
    setState(() {
      quotes = objectBoxHelper.getAllQuotes();
    });
  }


  void _showUpdateQuoteDialog(Quote quote) {
    final authorController = TextEditingController(text: quote.author);
    final textController = TextEditingController(text: quote.text);

    showDialog(
      context: context,
      builder: (context) {
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
              TextField(
                controller: authorController,
                decoration: const InputDecoration(labelText: 'Author'),
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
                if (textController.text.isNotEmpty &&
                    authorController.text.isNotEmpty) {
                  final updatedQuote = quote.copyWith(
                    text: textController.text,
                    author: authorController.text,
                    editedAt: DateTime.now(),
                  );
                  objectBoxHelper.updateQuote(updatedQuote);
                  setState(() {
                    quotes = objectBoxHelper.getAllQuotes();
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Update'),
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
        backgroundColor: Colors.redAccent,
        actions: [
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
          children:
              sortedQuotes.asMap().entries.map((entry) {
                final quote = entry.value;
                return QuoteCard(
                  key: ValueKey(quote.id),
                  quote: quote,
                  delete: () => _deleteQuote(quote),
                  edit: () => _showUpdateQuoteDialog(quote),
                );
              }).toList(),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddQuoteDialog,
        child: const Icon(Icons.add),
        backgroundColor: Colors.redAccent,
      ),
    );
  }
}
