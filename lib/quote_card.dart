import 'package:flutter/material.dart';
import 'quote.dart';

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
              style:
                  textStyle ??
                  TextStyle(
                    fontSize: 18.0,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
            ),
            const SizedBox(height: 6.0),
            Text(
              quote.author,
              style:
                  authorStyle ??
                  TextStyle(
                    fontSize: 14.0,
                    color: Colors.grey[800],
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Created: ${quote.formattedCreatedAt}',
              style: TextStyle(fontSize: 10.0, color: Colors.grey[500]),
            ),
            if (quote.editedAt != quote.createdAt)
              Text(
                'Edited: ${quote.formattedEditedAt}',
                style: TextStyle(fontSize: 10.0, color: Colors.grey[500]),
              ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: edit,
                  label: const Text('Edit'),
                  icon: const Icon(Icons.edit, size: 18),
                ),
                const SizedBox(width: 8.0),
                TextButton.icon(
                  onPressed: delete,
                  label: const Text('Delete'),
                  icon: const Icon(Icons.delete, size: 18),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
