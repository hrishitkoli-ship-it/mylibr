class Bookmark {
  String id; // sembast record key (uuid)
  String bookUuid;
  int pageNumber;
  String note;
  int dateCreated;

  Bookmark({
    required this.id,
    required this.bookUuid,
    required this.pageNumber,
    this.note = '',
    int? dateCreated,
  }) : dateCreated = dateCreated ?? DateTime.now().millisecondsSinceEpoch;

  Map<String, Object?> toMap() => {
        'id': id,
        'bookUuid': bookUuid,
        'pageNumber': pageNumber,
        'note': note,
        'dateCreated': dateCreated,
      };

  factory Bookmark.fromMap(Map<String, Object?> map) => Bookmark(
        id: map['id'] as String,
        bookUuid: map['bookUuid'] as String,
        pageNumber: map['pageNumber'] as int,
        note: map['note'] as String? ?? '',
        dateCreated: map['dateCreated'] as int?,
      );
}
