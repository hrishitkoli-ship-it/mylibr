import 'package:objectbox/objectbox.dart';
import 'book.dart';

@Entity()
class Bookmark {
  @Id()
  int id = 0;

  int pageNumber = 0;

  /// Optional user note attached to the bookmark.
  String note = '';

  int dateCreated = 0;

  final book = ToOne<Book>();

  Bookmark();

  Bookmark.create({required this.pageNumber, this.note = ''}) {
    dateCreated = DateTime.now().millisecondsSinceEpoch;
  }
}
