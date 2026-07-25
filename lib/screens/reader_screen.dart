import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/tts_service.dart';
import '../services/pdf_text_service.dart';
import '../web_interop/pdf_interop.dart';
import '../state/library_state.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final TtsService _tts;
  PdfJsDocument? _doc;
  Uint8List? _currentPageImage;
  int _currentPage = 1;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastReadPage > 0 ? widget.book.lastReadPage : 1;
    _tts = TtsService(PdfTextService());
    _tts.onPageChanged = (page) {
      setState(() => _currentPage = page);
      _renderCurrentPage();
    };
    _tts.onFinished = () => setState(() {});
    _openDocument();
  }

  Future<void> _openDocument() async {
    final state = context.read<LibraryState>();
    final bytes = await state.blobStore.getBytes(widget.book.pdfBlobKey);
    if (bytes == null) {
      setState(() => _loading = false);
      return;
    }
    _doc = await PdfInterop.open(bytes);
    await _renderCurrentPage();
    setState(() => _loading = false);
  }

  Future<void> _renderCurrentPage() async {
    if (_doc == null) return;
    final image = await PdfInterop.renderPageToPng(_doc!, _currentPage, targetWidth: 900);
    if (mounted) setState(() => _currentPageImage = image);
  }

  void _goToPage(int page) {
    if (_doc == null || page < 1 || page > _doc!.pageCount) return;
    setState(() => _currentPage = page);
    _renderCurrentPage();
  }

  @override
  void dispose() {
    context.read<LibraryState>().updateLastReadPage(widget.book, _currentPage);
    _tts.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: Center(
                    child: InteractiveViewer(
                      minScale: 1,
                      maxScale: 4,
                      child: _currentPageImage == null
                          ? const SizedBox.shrink()
                          : Image.memory(_currentPageImage!),
                    ),
                  ),
                ),
                _PageNavBar(
                  currentPage: _currentPage,
                  totalPages: _doc?.pageCount ?? widget.book.pageCount,
                  onPrev: () => _goToPage(_currentPage - 1),
                  onNext: () => _goToPage(_currentPage + 1),
                ),
                _TtsToolbar(
                  tts: _tts,
                  currentPage: _currentPage,
                  onPlay: () {
                    if (_doc == null) return;
                    _tts.loadDocumentAndPlay(doc: _doc!, startPage: _currentPage);
                  },
                ),
              ],
            ),
    );
  }
}

class _PageNavBar extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  const _PageNavBar({
    required this.currentPage,
    required this.totalPages,
    required this.onPrev,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: onPrev),
          Text('Page $currentPage / $totalPages'),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: onNext),
        ],
      ),
    );
  }
}

class _TtsToolbar extends StatefulWidget {
  final TtsService tts;
  final int currentPage;
  final VoidCallback onPlay;

  const _TtsToolbar({
    required this.tts,
    required this.currentPage,
    required this.onPlay,
  });

  @override
  State<_TtsToolbar> createState() => _TtsToolbarState();
}

class _TtsToolbarState extends State<_TtsToolbar> {
  @override
  Widget build(BuildContext context) {
    final tts = widget.tts;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        boxShadow: const [BoxShadow(blurRadius: 4, color: Colors.black26)],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(tts.state == TtsPlaybackState.playing
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_filled),
                  iconSize: 40,
                  onPressed: () {
                    if (tts.state == TtsPlaybackState.playing) {
                      tts.pause();
                    } else if (tts.state == TtsPlaybackState.paused) {
                      tts.resume();
                    } else {
                      widget.onPlay();
                    }
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle),
                  iconSize: 32,
                  onPressed: () {
                    tts.stop();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                Text('Reading page ${tts.currentPage > 0 ? tts.currentPage : widget.currentPage}'),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.speed, size: 16),
                Expanded(
                  child: Slider(
                    value: tts.speechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: '${tts.speechRate.toStringAsFixed(1)}x',
                    onChanged: (v) {
                      tts.setSpeechRate(v);
                      setState(() {});
                    },
                  ),
                ),
                const Icon(Icons.graphic_eq, size: 16),
                Expanded(
                  child: Slider(
                    value: tts.pitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 6,
                    label: 'Pitch ${tts.pitch.toStringAsFixed(1)}',
                    onChanged: (v) {
                      tts.setPitch(v);
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
