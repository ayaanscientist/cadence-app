import 'package:equatable/equatable.dart';

/// Domain entity for a book reading note with optional home-screen widget display.
class BookNote extends Equatable {

  factory BookNote.fromDb(dynamic row) {
    return BookNote(
      id: row.id as String,
      bookTitle: row.bookTitle as String,
      author: row.author as String,
      coreQuote: row.coreQuote as String,
      actionableTakeaway: row.actionableTakeaway as String,
      showInWidget: row.showInWidget as bool,
      createdAt: row.createdAt as DateTime?,
    );
  }
  const BookNote({
    required this.id,
    required this.bookTitle,
    required this.author,
    required this.coreQuote,
    required this.actionableTakeaway,
    this.showInWidget = false,
    this.createdAt,
  });

  final String id;
  final String bookTitle;
  final String author;

  /// A key quote from the book.
  final String coreQuote;

  /// The user's distilled actionable insight.
  final String actionableTakeaway;

  /// When true, this note appears in the home screen widget rotation.
  final bool showInWidget;

  final DateTime? createdAt;

  @override
  List<Object?> get props => [
        id,
        bookTitle,
        author,
        coreQuote,
        actionableTakeaway,
        showInWidget,
        createdAt,
      ];

  @override
  String toString() => 'BookNote("$bookTitle" by $author)';
}
