import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../state/library_state.dart';
import '../models/book.dart';
import 'reader_screen.dart';

class BookshelfScreen extends StatelessWidget {
  const BookshelfScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<LibraryState>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('MyLibrary'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search title, author, or genre…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: state.setSearchQuery,
            ),
          ),
          Expanded(
            child: state.books.isEmpty
                ? const Center(child: Text('No books yet — import a PDF to get started.'))
                : GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.62,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 16,
                    ),
                    itemCount: state.books.length,
                    itemBuilder: (context, index) => _BookTile(book: state.books[index]),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isImporting
            ? null
            : () async {
                final book = await state.importPdf();
                if (book != null && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
                  );
                }
              },
        icon: state.isImporting
            ? const SizedBox(
                width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.add),
        label: Text(state.isImporting ? 'Importing…' : 'Add PDF'),
      ),
    );
  }
}

class _BookTile extends StatelessWidget {
  final Book book;
  const _BookTile({required this.book});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ReaderScreen(book: book)),
      ),
      onLongPress: () => _showBookOptions(context, book),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: AspectRatio(
                aspectRatio: 0.7,
                child: File(book.coverPath).existsSync()
                    ? Image.file(File(book.coverPath), fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade300,
                        child: const Icon(Icons.picture_as_pdf, size: 40),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(book.title, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          if (book.author.isNotEmpty)
            Text(book.author, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          if (book.genres.isNotEmpty)
            Wrap(
              spacing: 4,
              children: book.genres.take(2).map((g) => Chip(
                label: Text(g.name, style: const TextStyle(fontSize: 9)),
                padding: EdgeInsets.zero,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              )).toList(),
            ),
        ],
      ),
    );
  }

  void _showBookOptions(BuildContext context, Book book) {
    final state = context.read<LibraryState>();
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Set custom cover'),
              onTap: () {
                Navigator.pop(context);
                state.setCustomCover(book);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete book'),
              onTap: () {
                Navigator.pop(context);
                state.deleteBook(book);
              },
            ),
          ],
        ),
      ),
    );
  }
}
