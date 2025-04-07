import 'package:objectbox/objectbox.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

@Entity()
class Quote {
  @Id()
  int obxId = 0;

  String id;
  String text;
  String author;
  DateTime createdAt;
  DateTime editedAt; 

  Quote({
    String? id,
    required this.text,
    required this.author,
    DateTime? createdAt,
    DateTime? editedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       editedAt = editedAt ?? DateTime.now() {
    if (text.isEmpty) throw ArgumentError('Quote text cannot be empty');
    if (author.isEmpty) throw ArgumentError('Author cannot be empty');
  }

  Quote copyWith({String? text, String? author, DateTime? editedAt}) {
    return Quote(
      id: id,
      text: text ?? this.text,
      author: author ?? this.author,
      createdAt: createdAt,
      editedAt: editedAt ?? DateTime.now(),
    );
  }

  String get formattedCreatedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(createdAt);
  String get formattedEditedAt =>
      DateFormat('dd MMM yyyy - HH:mm').format(editedAt);
}
