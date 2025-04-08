import 'package:flutter/material.dart';
import 'model.dart';
import 'quote_card.dart';
import 'objectbox_helper.dart';

class AuthorQuotesPage extends StatefulWidget {
  final ObjectBoxHelper objectBoxHelper;

  const AuthorQuotesPage({Key? key, required this.objectBoxHelper}) : super(key: key);

  @override
  _AuthorQuotesPageState createState() => _AuthorQuotesPageState();
}

class _AuthorQuotesPageState extends State<AuthorQuotesPage> {
  List<Author> authors = [];
  Author? selectedAuthor;
  List<Quote> authorQuotes = [];

  @override
  void initState() {
    super.initState();
    _loadAuthors();
  }

  void _loadAuthors() {
    setState(() {
      authors = widget.objectBoxHelper.getAllAuthors();
    });
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quotes by Author'),
        backgroundColor: Colors.teal,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: DropdownButton<Author>(
              isExpanded: true,
              hint: const Text('Select an Author'),
              value: selectedAuthor,
              onChanged: (Author? newValue) {
                if (newValue != null) {
                  _loadAuthorQuotes(newValue);
                }
              },
              items: authors.map((Author author) {
                return DropdownMenuItem<Author>(
                  value: author,
                  child: Text(author.name),
                );
              }).toList(),
            ),
          ),
          Expanded(
            child: selectedAuthor == null
                ? const Center(child: Text('Please select an author to view their quotes'))
                : authorQuotes.isEmpty
                    ? const Center(child: Text('No quotes found for this author'))
                    : SingleChildScrollView(
                        child: Column(
                          children: authorQuotes.map((quote) {
                            return QuoteCard(
                              key: ValueKey('${quote.id}-${quote.editedAt.millisecondsSinceEpoch}'),
                              quote: quote,
                              delete: () => _deleteQuote(quote),
                              edit: () => _showUpdateQuoteDialog(quote),
                            );
                          }).toList(),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}