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

// Accent pairs used by Help & Support and Scheme Finder.
const _purple = (ink: AppTheme.primary, tint: Color(0xFFEDE9FE));
const _pink = (ink: AppTheme.pinkDark, tint: Color(0xFFFCE7F3));
const _blue = (ink: Color(0xFF1D4ED8), tint: Color(0xFFDBEAFE));
const _green = (ink: Color(0xFF15803D), tint: Color(0xFFDCFCE7));

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

  static final _buttonStyle = ButtonStyle(
    minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
    padding: const WidgetStatePropertyAll(
      EdgeInsets.symmetric(horizontal: 10, vertical: 10),
    ),
    shape: WidgetStatePropertyAll(
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final busy = _busy != null;
    final document = _document;
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: AppTheme.surface,
                    border: Border(bottom: BorderSide(color: AppTheme.border)),
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: Row(
                    children: [
                      if (Navigator.canPop(context)) ...[
                        const BackButton(),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            'Smart Document Reader',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                    children: [
                      _importCard(busy),
                      if (_busy case final message?
                          when message.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        _ReaderStatus(message: message),
                      ],
                      if (_error case final error?) ...[
                        const SizedBox(height: 12),
                        _ReaderStatus(message: error, isError: true),
                      ],
                      if (document != null) ...[
                        const SizedBox(height: 12),
                        _documentCard(document),
                        if (_canSpeak) ...[
                          const SizedBox(height: 12),
                          _playbackControls(busy),
                        ],
                        const SizedBox(height: 12),
                        _aiControls(busy),
                        if (_answer case final answer?) ...[
                          const SizedBox(height: 12),
                          _textCard('Answer from document', answer, isAi: true),
                        ],
                        const SizedBox(height: 12),
                        _textCard(
                          _showOriginal
                              ? 'Original extracted text'
                              : _derivedLabel!,
                          _visibleDerivedText ?? document.text,
                          isAi: !_showOriginal,
                          action: _derivedText == null
                              ? null
                              : TextButton(
                                  style: _buttonStyle,
                                  onPressed: busy || _playing
                                      ? null
                                      : () => setState(
                                          () => _showOriginal = !_showOriginal,
                                        ),
                                  child: Text(
                                    _showOriginal
                                        ? 'Show ${_derivedLabel!.toLowerCase()}'
                                        : 'Show original text',
                                  ),
                                ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _importCard(bool busy) {
    final canScan = _extractor.supportsImageOcr;
    final upload = OutlinedButton(
      style: _pastelButton(_blue),
      onPressed: busy ? null : _upload,
      child: _actionLabel(Icons.upload_file_outlined, 'Upload Document'),
    );
    return _ReaderCard(
      title: 'Open a document',
      icon: Icons.folder_open_outlined,
      children: [
        if (canScan) ...[
          DropdownButtonFormField<DocumentScript>(
            initialValue: _script,
            isExpanded: true,
            itemHeight: null,
            decoration: _filterDecoration('OCR script'),
            items: [
              for (final script in DocumentScript.values)
                DropdownMenuItem(value: script, child: Text(script.label)),
            ],
            onChanged: busy
                ? null
                : (script) => setState(() => _script = script!),
          ),
          const SizedBox(height: 12),
          _actionPair(
            FilledButton(
              style: _pastelButton(_pink),
              onPressed: busy ? null : _scan,
              child: _actionLabel(
                Icons.document_scanner_outlined,
                'Scan Document',
              ),
            ),
            upload,
          ),
        ] else
          SizedBox(width: double.infinity, child: upload),
        const SizedBox(height: 10),
        Text(
          canScan
              ? 'PDF, JPG or PNG. Extraction stays on this device.'
              : 'Text-based PDF only. Image OCR is available on Android.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        if (widget.initialFile != null && canScan) ...[
          const SizedBox(height: 4),
          TextButton(
            style: _buttonStyle,
            onPressed: busy
                ? null
                : () => _open(
                    () async => widget.initialFile,
                    extension: widget.initialExtension,
                  ),
            child: const Text('Read Vault file again'),
          ),
        ],
      ],
    );
  }

  Widget _documentCard(ExtractedDocument document) {
    final name = _fileName ?? 'Document';
    return _ReaderCard(
      title: 'Selected document',
      icon: Icons.description_outlined,
      iconColors: _blue,
      children: [
        Tooltip(
          message: name,
          excludeFromSemantics: true,
          child: Text(
            name,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
        const SizedBox(height: 10),
        Semantics(
          liveRegion: true,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: _green.tint,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline, color: _green.ink, size: 18),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Text extracted',
                      style: Theme.of(
                        context,
                      ).textTheme.labelLarge?.copyWith(color: _green.ink),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (document.unreadablePages.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text('Unreadable pages: ${document.unreadablePages.join(', ')}'),
        ],
      ],
    );
  }

  Widget _playbackControls(bool busy) {
    final editable = !busy && !_playing;
    final derivedLanguage = _visibleDerivedLanguage;
    return _ReaderCard(
      title: 'Listen to Document',
      icon: Icons.headphones_outlined,
      iconColors: _blue,
      children: [
        if (derivedLanguage == null)
          _languagePicker(
            'Reading voice',
            _voice,
            editable ? (value) => setState(() => _voice = value!) : null,
          )
        else
          Text('Reading voice: ${_languages[derivedLanguage]}'),
        const SizedBox(height: 12),
        Text(
          'Reading speed: ${_speed.toStringAsFixed(1)}',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: _blue.ink),
        ),
        Slider(
          value: _speed,
          min: 0.2,
          max: 0.8,
          divisions: 6,
          label: _speed.toStringAsFixed(1),
          semanticFormatterCallback: (value) =>
              'Reading speed ${value.toStringAsFixed(1)}',
          onChanged: editable
              ? (value) => setState(() => _speed = value)
              : null,
        ),
        _actionPair(
          FilledButton(
            style: _buttonStyle,
            onPressed: editable ? _play : null,
            child: _actionLabel(Icons.play_arrow_rounded, 'Play'),
          ),
          OutlinedButton(
            style: _pastelButton(_blue),
            onPressed: _playing ? _stop : null,
            child: _actionLabel(Icons.stop_rounded, 'Stop'),
          ),
        ),
      ],
    );
  }

  Widget _aiControls(bool busy) => _ReaderCard(
    title: 'Document AI',
    icon: Icons.auto_awesome_outlined,
    purpleHeading: true,
    children: [
      if (!_canSpeak) ...[
        _languagePicker(
          'Original language',
          _voice,
          busy ? null : (value) => setState(() => _voice = value!),
        ),
        const SizedBox(height: 12),
      ],
      _languagePicker(
        'Output language',
        _target,
        busy ? null : (value) => setState(() => _target = value!),
      ),
      const SizedBox(height: 12),
      _actionPair(
        OutlinedButton(
          style: _pastelButton(_pink),
          onPressed: busy ? null : () => _runAi(DocumentAiAction.simplify),
          child: const Text('Simplify', textAlign: TextAlign.center),
        ),
        OutlinedButton(
          style: _pastelButton(_green),
          onPressed: busy ? null : () => _runAi(DocumentAiAction.translate),
          child: const Text('Translate', textAlign: TextAlign.center),
        ),
      ),
      const SizedBox(height: 16),
      const Divider(),
      const SizedBox(height: 8),
      Semantics(
        header: true,
        child: Text(
          'Ask a Question',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _question,
        enabled: !busy,
        maxLength: 500,
        textInputAction: TextInputAction.send,
        onSubmitted: busy ? null : (_) => _runAi(DocumentAiAction.question),
        decoration: const InputDecoration(labelText: 'Ask about this document'),
      ),
      const SizedBox(height: 4),
      SizedBox(
        width: double.infinity,
        child: FilledButton(
          style: _buttonStyle,
          onPressed: busy ? null : () => _runAi(DocumentAiAction.question),
          child: const Text('Ask question', textAlign: TextAlign.center),
        ),
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
    isExpanded: true,
    itemHeight: null,
    decoration: _filterDecoration(label),
    items: [
      for (final language in _languages.entries)
        DropdownMenuItem(value: language.key, child: Text(language.value)),
    ],
    onChanged: onChanged,
  );

  Widget _textCard(
    String label,
    String text, {
    required bool isAi,
    Widget? action,
  }) => _ReaderCard(
    title: label,
    icon: isAi ? Icons.auto_awesome_outlined : Icons.subject_rounded,
    purpleHeading: isAi,
    children: [
      if (action != null) ...[action, const SizedBox(height: 4)],
      SelectableText(
        text,
        style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.5),
      ),
    ],
  );

  ButtonStyle _pastelButton(({Color ink, Color tint}) colors) =>
      _buttonStyle.copyWith(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.disabled) ? null : colors.tint,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled) ? null : colors.ink,
        ),
        side: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.disabled)
              ? null
              : BorderSide(color: colors.ink.withValues(alpha: 0.24)),
        ),
      );

  InputDecoration _filterDecoration(String label) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: AppTheme.border, width: 1.5),
    );
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: AppTheme.background,
      border: border,
      enabledBorder: border,
      disabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppTheme.primary, width: 2),
      ),
    );
  }

  Widget _actionPair(Widget first, Widget second) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(child: first),
        const SizedBox(width: 8),
        Expanded(child: second),
      ],
    ),
  );

  Widget _actionLabel(IconData icon, String label) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Icon(icon, size: 22),
      const SizedBox(height: 5),
      Text(label, textAlign: TextAlign.center),
    ],
  );
}

class _ReaderCard extends StatelessWidget {
  const _ReaderCard({
    required this.title,
    required this.icon,
    required this.children,
    this.iconColors = _purple,
    this.purpleHeading = false,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;
  final ({Color ink, Color tint}) iconColors;
  final bool purpleHeading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      color: AppTheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppTheme.border, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: iconColors.tint,
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: Icon(icon, color: iconColors.ink, size: 20),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: purpleHeading
                            ? AppTheme.primaryDark
                            : AppTheme.textMain,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReaderStatus extends StatelessWidget {
  const _ReaderStatus({required this.message, this.isError = false});

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = isError ? colors.onErrorContainer : _blue.ink;
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: isError ? colors.errorContainer : _blue.tint,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    isError ? Icons.error_outline : Icons.hourglass_top_rounded,
                    color: foreground,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(message, style: TextStyle(color: foreground)),
                  ),
                ],
              ),
              if (!isError) ...[
                const SizedBox(height: 10),
                const LinearProgressIndicator(),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
