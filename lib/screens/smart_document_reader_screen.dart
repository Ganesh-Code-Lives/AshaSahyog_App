import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import '../services/document_ai_service.dart';
import '../services/document_extraction_service.dart';
import '../services/tts_service.dart';
import '../theme/app_theme.dart';

const _languages = {'en': 'English', 'hi': 'Hindi', 'mr': 'Marathi'};

class SmartDocumentReaderScreen extends StatefulWidget {
  const SmartDocumentReaderScreen({
    super.key,
    this.initialFile,
    this.initialExtension,
  });

  final XFile? initialFile;
  final String? initialExtension;

  @override
  State<SmartDocumentReaderScreen> createState() =>
      _SmartDocumentReaderScreenState();
}

class _SmartDocumentReaderScreenState extends State<SmartDocumentReaderScreen> {
  final _extractor = DocumentExtractionService();
  final _ai = DocumentAiService();
  final _tts = TTSService();
  final _question = TextEditingController();

  DocumentScript _script = DocumentScript.latin;
  ExtractedDocument? _document;
  String? _fileName;
  String? _derivedText;
  String? _derivedLabel;
  String? _derivedLanguage;
  String? _answer;
  String? _error;
  String? _busy;
  String _voice = 'en';
  String _target = 'hi';
  double _speed = 0.5;
  bool _playing = false;
  bool _showOriginal = true;

  String? get _visibleDerivedText => _showOriginal ? null : _derivedText;
  String? get _visibleDerivedLanguage =>
      _showOriginal ? null : _derivedLanguage;

  bool get _canSpeak =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  @override
  void initState() {
    super.initState();
    final file = widget.initialFile;
    if (file != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          unawaited(
            _open(() async => file, extension: widget.initialExtension),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    if (_playing) unawaited(_tts.stop());
    _question.dispose();
    super.dispose();
  }

  Future<void> _open(
    Future<XFile?> Function() pick, {
    String? extension,
    bool cleanPickerCopy = false,
  }) async {
    if (_busy != null) return;
    setState(() {
      _busy = 'Opening document…';
      _error = null;
    });
    XFile? file;
    try {
      file = await pick();
      if (file == null || !mounted) return;
      await _stop();
      if (!mounted) return;
      setState(() => _busy = 'Extracting text…');
      if (await file.length() > DocumentExtractionService.maxBytes) {
        throw const DocumentReadException('Choose a file under 20 MB.');
      }
      final data = await file.readAsBytes();
      if (!mounted) return;
      final result = await _extractor.extract(
        data,
        extension: extension ?? file.name.split('.').last,
        script: _script,
        isCancelled: () => !mounted,
      );
      if (!mounted) return;
      setState(() {
        _document = result;
        _fileName = file!.name;
        _derivedText = null;
        _showOriginal = true;
        _derivedLabel = null;
        _derivedLanguage = null;
        _answer = null;
        _voice = _script == DocumentScript.latin ? 'en' : 'hi';
        _question.clear();
      });
    } on DocumentReadException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Could not read this file. Try a clear image or unlocked PDF.';
        });
      }
    } finally {
      if (cleanPickerCopy && file != null && !kIsWeb) {
        await _deletePickerCopy(file);
      }
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _deletePickerCopy(XFile file) async {
    try {
      final temporaryDirectory = await getTemporaryDirectory();
      final copy = File(file.path);
      final resolved = await copy.resolveSymbolicLinks();
      final cache = await temporaryDirectory.resolveSymbolicLinks();
      if (resolved.startsWith('$cache${Platform.pathSeparator}')) {
        await copy.delete();
      }
    } catch (_) {
      // Some picker providers return a stream or remove their cache themselves.
    }
  }

  Future<void> _upload() => _open(() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extractor.supportsImageOcr
          ? ['pdf', 'jpg', 'jpeg', 'png']
          : ['pdf'],
      withData: kIsWeb,
    );
    return result?.xFiles.single;
  }, cleanPickerCopy: true);

  Future<void> _scan() => _open(
    () => ImagePicker().pickImage(
      source: ImageSource.camera,
      maxWidth: 3200,
      maxHeight: 3200,
      imageQuality: 95,
      requestFullMetadata: false,
    ),
    cleanPickerCopy: true,
  );

  Future<void> _play() async {
    final text = _visibleDerivedText ?? _document?.text;
    if (text == null || _playing || _busy != null) return;
    setState(() {
      _playing = true;
      _error = null;
    });
    final language = _visibleDerivedLanguage ?? _voice;
    final success = await _tts.readDocument(
      text,
      langCode: language,
      rate: _speed,
    );
    if (!mounted || !_playing) return;
    setState(() {
      _playing = false;
      if (!success) {
        _error =
            'Could not play ${_languages[language]}. '
            'Check that an offline voice for this language is installed.';
      }
    });
  }

  Future<void> _stop() async {
    if (!_playing) return;
    await _tts.stop();
    if (mounted && _playing) setState(() => _playing = false);
  }

  Future<void> _runAi(DocumentAiAction action) async {
    final document = _document?.text;
    if (document == null || _busy != null) return;
    final question = _question.text.trim();
    if (action == DocumentAiAction.question && question.isEmpty) {
      setState(() => _error = 'Enter a question about this document.');
      return;
    }
    if (document.length > DocumentAiService.maxTextLength) {
      setState(() {
        _error =
            'AI supports up to 30,000 characters. Open a shorter document.';
      });
      return;
    }
    final language = action == DocumentAiAction.question ? _voice : _target;
    setState(() {
      _busy = '';
      _error = null;
    });

    final consent = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Send text to Google Gemini?'),
        content: Text(
          'This sends the extracted document text'
          '${action == DocumentAiAction.question ? ' and your question' : ''} '
          'through AshaSahyog’s Supabase backend to Google Gemini. '
          'The original file stays on this device. Continue only if you are '
          'comfortable sharing any personal information in the text.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Send text'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (consent != true) {
      setState(() => _busy = null);
      return;
    }

    await _stop();
    if (!mounted) return;
    setState(() {
      _busy = 'Waiting for Gemini…';
      if (action == DocumentAiAction.question) _answer = null;
    });
    try {
      final result = await _ai.run(
        action: action,
        document: document,
        language: language,
        question: action == DocumentAiAction.question ? question : null,
      );
      if (!mounted) return;
      setState(() {
        if (action == DocumentAiAction.question) {
          _answer = result;
        } else {
          _derivedText = result;
          _showOriginal = false;
          _derivedLanguage = language;
          _derivedLabel = action == DocumentAiAction.simplify
              ? 'Simplified text'
              : '${_languages[language]} translation';
        }
      });
    } on DocumentAiException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Document AI is unavailable. Try again later.');
      }
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busy;
    final document = _document;
    return Scaffold(
      appBar: AppBar(title: const Text('Smart Document Reader')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (_extractor.supportsImageOcr)
            DropdownButtonFormField<DocumentScript>(
              initialValue: _script,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'OCR script'),
              items: [
                for (final script in DocumentScript.values)
                  DropdownMenuItem(value: script, child: Text(script.label)),
              ],
              onChanged: busy != null
                  ? null
                  : (script) => setState(() => _script = script!),
            ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_extractor.supportsImageOcr)
                FilledButton.icon(
                  onPressed: busy == null ? _scan : null,
                  icon: const Icon(Icons.document_scanner_outlined),
                  label: const Text('Scan Document'),
                ),
              if (widget.initialFile != null && _extractor.supportsImageOcr)
                OutlinedButton.icon(
                  onPressed: busy == null
                      ? () => _open(
                          () async => widget.initialFile,
                          extension: widget.initialExtension,
                        )
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Read Vault file again'),
                ),
              OutlinedButton.icon(
                onPressed: busy == null ? _upload : null,
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            _extractor.supportsImageOcr
                ? 'PDF, JPG or PNG. Extraction stays on this device.'
                : 'Text-based PDF only. Image OCR is available on Android.',
          ),
          if (busy != null && busy.isNotEmpty) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
            Semantics(liveRegion: true, child: Text(busy)),
          ],
          if (_error case final error?) ...[
            const SizedBox(height: 12),
            Semantics(
              liveRegion: true,
              child: Text(
                error,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ),
          ],
          if (document != null) ...[
            const SizedBox(height: 20),
            Text(
              _fileName ?? 'Document',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            if (document.unreadablePages.isNotEmpty)
              Text('Unreadable pages: ${document.unreadablePages.join(', ')}'),
            if (_canSpeak) _playbackControls(busy != null),
            if (_derivedText != null)
              TextButton.icon(
                onPressed: busy != null || _playing
                    ? null
                    : () => setState(() => _showOriginal = !_showOriginal),
                icon: const Icon(Icons.description_outlined),
                label: Text(
                  _showOriginal
                      ? 'Show ${_derivedLabel!.toLowerCase()}'
                      : 'Show original text',
                ),
              ),
            ExpansionTile(
              title: const Text('Document AI'),
              subtitle: const Text('Simplify, translate, or ask a question'),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              children: [
                _aiControls(busy != null),
                if (_answer case final answer?)
                  _textCard('Answer from document', answer),
              ],
            ),
            _textCard(
              _showOriginal ? 'Original extracted text' : _derivedLabel!,
              _visibleDerivedText ?? document.text,
            ),
          ],
        ],
      ),
    );
  }

  Widget _playbackControls(bool busy) {
    final editable = !busy && !_playing;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_visibleDerivedLanguage == null)
          _languagePicker(
            'Reading voice',
            _voice,
            editable ? (value) => setState(() => _voice = value!) : null,
          ),
        Text('Reading speed: ${_speed.toStringAsFixed(1)}'),
        Slider(
          value: _speed,
          min: 0.2,
          max: 0.8,
          divisions: 6,
          label: _speed.toStringAsFixed(1),
          semanticFormatterCallback: (value) => value.toStringAsFixed(1),
          onChanged: editable
              ? (value) => setState(() => _speed = value)
              : null,
        ),
        Wrap(
          spacing: 8,
          children: [
            FilledButton.icon(
              onPressed: editable ? _play : null,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Play'),
            ),
            OutlinedButton.icon(
              onPressed: _playing ? _stop : null,
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _aiControls(bool busy) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      if (!_canSpeak)
        _languagePicker(
          'Original language',
          _voice,
          busy ? null : (value) => setState(() => _voice = value!),
        ),
      _languagePicker(
        'Translate to',
        _target,
        busy ? null : (value) => setState(() => _target = value!),
      ),
      Wrap(
        spacing: 8,
        children: [
          OutlinedButton(
            onPressed: busy ? null : () => _runAi(DocumentAiAction.simplify),
            child: const Text('Simplify'),
          ),
          OutlinedButton(
            onPressed: busy ? null : () => _runAi(DocumentAiAction.translate),
            child: const Text('Translate'),
          ),
        ],
      ),
      const SizedBox(height: 12),
      TextField(
        controller: _question,
        enabled: !busy,
        maxLength: 500,
        textInputAction: TextInputAction.send,
        onSubmitted: busy ? null : (_) => _runAi(DocumentAiAction.question),
        decoration: const InputDecoration(labelText: 'Ask about this document'),
      ),
      FilledButton(
        onPressed: busy ? null : () => _runAi(DocumentAiAction.question),
        child: const Text('Ask question'),
      ),
    ],
  );

  Widget _languagePicker(
    String label,
    String value,
    ValueChanged<String?>? onChanged,
  ) => DropdownButtonFormField<String>(
    key: ValueKey((label, value)),
    initialValue: value,
    decoration: InputDecoration(labelText: label),
    items: [
      for (final language in _languages.entries)
        DropdownMenuItem(value: language.key, child: Text(language.value)),
    ],
    onChanged: onChanged,
  );

  Widget _textCard(String label, String text) => Card(
    color: AppTheme.surface,
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          SelectableText(text),
        ],
      ),
    ),
  );
}
