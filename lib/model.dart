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