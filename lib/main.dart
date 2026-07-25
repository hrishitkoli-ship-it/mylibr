import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/library_repository.dart';
import 'services/local_blob_store.dart';
import 'services/cover_service.dart';
import 'state/library_state.dart';
import 'screens/bookshelf_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyLibraryApp());
}

class MyLibraryApp extends StatelessWidget {
  const MyLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final blobStore = LocalBlobStore();
    final repository = LibraryRepository();
    final coverService = CoverService(blobStore);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LibraryState(
            repository: repository,
            blobStore: blobStore,
            coverService: coverService,
          ),
        ),
      ],
      child: MaterialApp(
        title: 'MyLibrary',
        theme: ThemeData(colorSchemeSeed: const Color(0xFF6C63FF), useMaterial3: true),
        home: const BookshelfScreen(),
      ),
    );
  }
}
