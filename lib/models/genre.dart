import 'package:objectbox/objectbox.dart';
import 'book.dart';

@Entity()
class Genre {
  @Id()
  int id = 0;

  @Unique()
  String name = '';

  /// Optional hex color for chip display, e.g. "#FF6B6B".
  String colorHex = '#6C63FF';

  @Backlink('genres')
  final books = ToMany<Book>();

  Genre();

  Genre.create({required this.name, this.colorHex = '#6C63FF'});
}
