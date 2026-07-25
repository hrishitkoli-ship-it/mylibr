enum ReadingStatus { unread, reading, completed }

class Book {
  String uuid; // also the sembast record key
  String title;
  String author;
  String description;

  /// IndexedDB blob-store key for the PDF bytes (see LocalStorageService).
  String pdfBlobKey;

  /// IndexedDB blob-store key for the cover PNG bytes.
  String coverBlobKey;

  bool hasCustomCover;
  int pageCount;
  int lastReadPage;
  ReadingStatus status;
  int dateAdded;
  int dateLastOpened;
  int fileSizeBytes;
  List<String> genreNames;

  Book({
    required this.uuid,
    required this.title,
    required this.pdfBlobKey,
    required this.coverBlobKey,
    this.author = '',
    this.description = '',
    this.hasCustomCover = false,
    this.pageCount = 0,
    this.lastReadPage = 0,
    this.status = ReadingStatus.unread,
    int? dateAdded,
    int? dateLastOpened,
    this.fileSizeBytes = 0,
    List<String>? genreNames,
  })  : dateAdded = dateAdded ?? DateTime.now().millisecondsSinceEpoch,
        dateLastOpened = dateLastOpened ?? DateTime.now().millisecondsSinceEpoch,
        genreNames = genreNames ?? [];

  Map<String, Object?> toMap() => {
        'uuid': uuid,
        'title': title,
        'author': author,
        'description': description,
        'pdfBlobKey': pdfBlobKey,
        'coverBlobKey': coverBlobKey,
        'hasCustomCover': hasCustomCover,
        'pageCount': pageCount,
        'lastReadPage': lastReadPage,
        'status': status.index,
        'dateAdded': dateAdded,
        'dateLastOpened': dateLastOpened,
        'fileSizeBytes': fileSizeBytes,
        'genreNames': genreNames,
      };

  factory Book.fromMap(Map<String, Object?> map) => Book(
        uuid: map['uuid'] as String,
        title: map['title'] as String,
        pdfBlobKey: map['pdfBlobKey'] as String,
        coverBlobKey: map['coverBlobKey'] as String,
        author: map['author'] as String? ?? '',
        description: map['description'] as String? ?? '',
        hasCustomCover: map['hasCustomCover'] as bool? ?? false,
        pageCount: map['pageCount'] as int? ?? 0,
        lastReadPage: map['lastReadPage'] as int? ?? 0,
        status: ReadingStatus.values[map['status'] as int? ?? 0],
        dateAdded: map['dateAdded'] as int?,
        dateLastOpened: map['dateLastOpened'] as int?,
        fileSizeBytes: map['fileSizeBytes'] as int? ?? 0,
        genreNames: (map['genreNames'] as List?)?.cast<String>() ?? [],
      );
}
