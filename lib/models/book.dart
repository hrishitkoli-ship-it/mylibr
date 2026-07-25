import 'package:objectbox/objectbox.dart';
import 'genre.dart';
import 'bookmark.dart';

enum ReadingStatus { unread, reading, completed }

@Entity()
class Book {
  @Id()
  int id = 0;

  /// Unique local identifier (uuid), stable across DB migrations.
  String uuid = '';

  String title = '';
  String author = '';
  String description = '';

  /// Absolute path to the PDF file inside the app sandbox directory.
  /// e.g. <appDocsDir>/library/pdfs/<uuid>.pdf
  String filePath = '';

  /// Absolute path to the cover image (either auto-extracted page-1
  /// render or a user-picked custom image), stored in
  /// <appDocsDir>/library/covers/<uuid>.png
  String coverPath = '';

  /// True if the user overrode the auto-generated cover.
  bool hasCustomCover = false;

  int pageCount = 0;

  /// Last page the user was reading (for "resume reading").
  int lastReadPage = 0;

  @Transient()
  ReadingStatus status = ReadingStatus.unread;

  // ObjectBox can't store enums directly; this int is the persisted field.
  int get dbStatus => status.index;
  set dbStatus(int value) => status = ReadingStatus.values[value];

  int dateAdded = 0; // millisecondsSinceEpoch
  int dateLastOpened = 0;

  /// File size in bytes, useful for storage-usage screens.
  int fileSizeBytes = 0;

  final genres = ToMany<Genre>();
  final bookmarks = ToMany<Bookmark>();

  Book();

  Book.create({
    required this.uuid,
    required this.title,
    required this.filePath,
    required this.coverPath,
    this.author = '',
    this.description = '',
    this.pageCount = 0,
    this.fileSizeBytes = 0,
  }) {
    dateAdded = DateTime.now().millisecondsSinceEpoch;
    dateLastOpened = dateAdded;
    status = ReadingStatus.unread;
  }
}
