import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'db/objectbox_store.dart';
import 'db/library_repository.dart';
import 'services/local_storage_service.dart';
import 'services/cover_service.dart';
import 'state/library_state.dart';
import 'screens/bookshelf_screen.dart';

late ObjectBoxStore objectBoxStore;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  objectBoxStore = await ObjectBoxStore.create();
  runApp(const MyLibraryApp());
}

class MyLibraryApp extends StatelessWidget {
  const MyLibraryApp({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = LocalStorageService();
    final repository = LibraryRepository(objectBoxStore);
    final coverService = CoverService(storage);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => LibraryState(
            repository: repository,
            storage: storage,
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
