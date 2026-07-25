import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';
import 'package:provider/provider.dart';
import '../models/book.dart';
import '../services/tts_service.dart';
import '../services/pdf_text_service.dart';
import '../state/library_state.dart';

class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen> {
  late final PdfControllerPinch _pdfController;
  late final TtsService _tts;
  int _currentPage = 1;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfControllerPinch(
      document: PdfDocument.openFile(widget.book.filePath),
      initialPage: widget.book.lastReadPage > 0 ? widget.book.lastReadPage : 1,
    );
    _currentPage = widget.book.lastReadPage > 0 ? widget.book.lastReadPage : 1;

    _tts = TtsService(PdfTextService());
    _tts.init();
    _tts.onPageChanged = (page) {
      setState(() => _currentPage = page);
      _pdfController.jumpToPage(page);
    };
    _tts.onFinished = () => setState(() {});
  }

  @override
  void dispose() {
    context.read<LibraryState>().updateLastReadPage(widget.book, _currentPage);
    _tts.dispose();
    _pdfController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title, overflow: TextOverflow.ellipsis),
      ),
      body: Column(
        children: [
          Expanded(
            child: PdfViewPinch(
              controller: _pdfController,
              onPageChanged: (page) => setState(() => _currentPage = page),
            ),
          ),
          _TtsToolbar(
            tts: _tts,
            currentPage: _currentPage,
            onPlay: () => _tts.loadDocumentAndPlay(
              pdfPath: widget.book.filePath,
              startPage: _currentPage,
            ),
          ),
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
                  onPressed: () async {
                    if (tts.state == TtsPlaybackState.playing) {
                      await tts.pause();
                    } else if (tts.state == TtsPlaybackState.paused) {
                      await tts.resume();
                    } else {
                      widget.onPlay();
                    }
                    setState(() {});
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.stop_circle),
                  iconSize: 32,
                  onPressed: () async {
                    await tts.stop();
                    setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                Text('Page ${tts.currentPage > 0 ? tts.currentPage : widget.currentPage}'),
                const Spacer(),
                _SpeedControl(tts: tts, onChanged: () => setState(() {})),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.speed, size: 16),
                Expanded(
                  child: Slider(
                    value: tts.speechRate,
                    min: 0.2,
                    max: 1.0,
                    divisions: 8,
                    label: '${(tts.speechRate * 2).toStringAsFixed(1)}x',
                    onChanged: (v) async {
                      await tts.setSpeechRate(v);
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
                    onChanged: (v) async {
                      await tts.setPitch(v);
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

class _SpeedControl extends StatelessWidget {
  final TtsService tts;
  final VoidCallback onChanged;
  const _SpeedControl({required this.tts, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Text('${(tts.speechRate * 2).toStringAsFixed(1)}x speed',
        style: const TextStyle(fontSize: 12));
  }
}
