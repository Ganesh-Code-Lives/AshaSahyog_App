import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODEL
// ─────────────────────────────────────────────────────────────────────────────

enum DocCategory { all, certificates, idProofs, medical, other }

extension DocCategoryExt on DocCategory {
  String get label {
    switch (this) {
      case DocCategory.all: return 'All';
      case DocCategory.certificates: return 'Certificates';
      case DocCategory.idProofs: return 'ID Proofs';
      case DocCategory.medical: return 'Medical';
      case DocCategory.other: return 'Other';
    }
  }

  String get key {
    switch (this) {
      case DocCategory.all: return 'all';
      case DocCategory.certificates: return 'certificates';
      case DocCategory.idProofs: return 'id_proofs';
      case DocCategory.medical: return 'medical';
      case DocCategory.other: return 'other';
    }
  }

  static DocCategory fromKey(String key) {
    switch (key) {
      case 'certificates': return DocCategory.certificates;
      case 'id_proofs': return DocCategory.idProofs;
      case 'medical': return DocCategory.medical;
      default: return DocCategory.other;
    }
  }

  Color get color {
    switch (this) {
      case DocCategory.certificates: return const Color(0xFFBE185D);
      case DocCategory.idProofs: return const Color(0xFF0284C7);
      case DocCategory.medical: return const Color(0xFF065F46);
      case DocCategory.other: return const Color(0xFF7C3AED);
      default: return AppTheme.primary;
    }
  }

  Color get bgColor {
    switch (this) {
      case DocCategory.certificates: return const Color(0xFFFBCFE8);
      case DocCategory.idProofs: return const Color(0xFFBAE6FD);
      case DocCategory.medical: return const Color(0xFFA7F3D0);
      case DocCategory.other: return const Color(0xFFEDE9FE);
      default: return const Color(0xFFF3E8FF);
    }
  }

  IconData get icon {
    switch (this) {
      case DocCategory.certificates: return Icons.workspace_premium_rounded;
      case DocCategory.idProofs: return Icons.credit_card_rounded;
      case DocCategory.medical: return Icons.medical_information_rounded;
      case DocCategory.other: return Icons.insert_drive_file_rounded;
      default: return Icons.folder_rounded;
    }
  }
}

class VaultDocument {
  final String id;
  final String title;
  final String filePath;
  final String fileName;
  final DocCategory category;
  final DateTime uploadedAt;
  final int fileSizeBytes;
  final String fileExtension;

  VaultDocument({
    required this.id,
    required this.title,
    required this.filePath,
    required this.fileName,
    required this.category,
    required this.uploadedAt,
    required this.fileSizeBytes,
    required this.fileExtension,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'filePath': filePath,
        'fileName': fileName,
        'category': category.key,
        'uploadedAt': uploadedAt.toIso8601String(),
        'fileSizeBytes': fileSizeBytes,
        'fileExtension': fileExtension,
      };

  factory VaultDocument.fromJson(Map<String, dynamic> json) => VaultDocument(
        id: json['id'],
        title: json['title'],
        filePath: json['filePath'],
        fileName: json['fileName'],
        category: DocCategoryExt.fromKey(json['category']),
        uploadedAt: DateTime.parse(json['uploadedAt']),
        fileSizeBytes: json['fileSizeBytes'] ?? 0,
        fileExtension: json['fileExtension'] ?? '',
      );

  String get formattedSize {
    if (fileSizeBytes < 1024) return '$fileSizeBytes B';
    if (fileSizeBytes < 1024 * 1024) return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  bool get isImage =>
      ['jpg', 'jpeg', 'png', 'gif', 'webp'].contains(fileExtension.toLowerCase());

  bool get isPdf => fileExtension.toLowerCase() == 'pdf';
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN WIDGET
// ─────────────────────────────────────────────────────────────────────────────

class DocumentVault extends StatefulWidget {
  final VoidCallback onBack;

  const DocumentVault({super.key, required this.onBack});

  @override
  State<DocumentVault> createState() => _DocumentVaultState();
}

class _DocumentVaultState extends State<DocumentVault>
    with TickerProviderStateMixin {
  List<VaultDocument> _documents = [];
  bool _isLoading = true;
  DocCategory _selectedCategory = DocCategory.all;
  String _searchQuery = '';
  bool _isGridView = false;
  final TextEditingController _searchController = TextEditingController();
  late AnimationController _fabController;

  static const String _prefsKey = 'vault_documents';

  @override
  void initState() {
    super.initState();
    _fabController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 300));
    _loadDocuments();
  }

  @override
  void dispose() {
    _fabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── PERSISTENCE ────────────────────────────────────────────────────────────

  Future<void> _loadDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_prefsKey) ?? [];
    final docs = <VaultDocument>[];
    for (final s in raw) {
      try {
        final doc = VaultDocument.fromJson(json.decode(s));
        if (File(doc.filePath).existsSync()) docs.add(doc);
      } catch (_) {}
    }
    if (!mounted) return;
    setState(() {
      _documents = docs;
      _isLoading = false;
    });
  }

  Future<void> _saveDocuments() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _prefsKey, _documents.map((d) => json.encode(d.toJson())).toList());
  }

  // ── UPLOAD ─────────────────────────────────────────────────────────────────

  void _showUploadOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UploadBottomSheet(
        onPickFile: _pickFile,
        onPickImage: _pickImage,
        onPickCamera: _pickCamera,
      ),
    );
  }

  Future<void> _pickFile() async {
    Navigator.pop(context);
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: false,
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );
      if (result == null || result.files.isEmpty) return;
      final file = result.files.first;
      if (file.path == null) return;
      await _saveAndAddDocument(file.path!, file.name, file.size);
    } catch (e) {
      _showError('Could not pick file: $e');
    }
  }

  Future<void> _pickImage() async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (img == null) return;
      final file = File(img.path);
      final size = await file.length();
      await _saveAndAddDocument(img.path, img.name, size);
    } catch (e) {
      _showError('Could not pick image: $e');
    }
  }

  Future<void> _pickCamera() async {
    Navigator.pop(context);
    try {
      final picker = ImagePicker();
      final img = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
      if (img == null) return;
      final file = File(img.path);
      final size = await file.length();
      await _saveAndAddDocument(img.path, img.name, size);
    } catch (e) {
      _showError('Could not capture image: $e');
    }
  }

  Future<void> _saveAndAddDocument(
      String sourcePath, String fileName, int fileSize) async {
    final appDir = await getApplicationDocumentsDirectory();
    final vaultDir = Directory('${appDir.path}/vault');
    if (!vaultDir.existsSync()) vaultDir.createSync(recursive: true);

    final ext = fileName.contains('.') ? fileName.split('.').last : '';
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final destPath = '${vaultDir.path}/$id.$ext';

    await File(sourcePath).copy(destPath);

    if (!mounted) return;
    _showSaveDocumentSheet(
      filePath: destPath,
      fileName: fileName,
      fileSize: fileSize,
      ext: ext,
    );
  }

  // ── SAVE DOCUMENT SHEET ────────────────────────────────────────────────────

  void _showSaveDocumentSheet({
    required String filePath,
    required String fileName,
    required int fileSize,
    required String ext,
  }) {
    final titleController =
        TextEditingController(text: fileName.replaceAll(RegExp(r'\.[^.]+$'), ''));
    DocCategory selectedCat = DocCategory.certificates;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) {
          final isImage = ['jpg', 'jpeg', 'png', 'gif', 'webp']
              .contains(ext.toLowerCase());
          final isPdf = ext.toLowerCase() == 'pdf';

          return Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom),
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Drag Handle ──────────────────────────────────────
                    const SizedBox(height: 12),
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Header Row ───────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        children: [
                          // File preview badge
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 56, height: 56,
                              color: isImage
                                  ? const Color(0xFFBAE6FD)
                                  : isPdf
                                      ? const Color(0xFFFEE2E2)
                                      : const Color(0xFFF3E8FF),
                              child: isImage && File(filePath).existsSync()
                                  ? Image.file(File(filePath), fit: BoxFit.cover)
                                  : Icon(
                                      isPdf
                                          ? Icons.picture_as_pdf_rounded
                                          : isImage
                                              ? Icons.image_rounded
                                              : Icons.insert_drive_file_rounded,
                                      color: isImage
                                          ? const Color(0xFF0284C7)
                                          : isPdf
                                              ? Colors.red
                                              : AppTheme.primary,
                                      size: 28,
                                    ),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Save Document',
                                    style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF1F2937))),
                                const SizedBox(height: 2),
                                Text(
                                  '${ext.toUpperCase()} · ${_fmtSize(fileSize)}',
                                  style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF6B7280)),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Document Name Field ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: TextField(
                        controller: titleController,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          labelText: 'Document Name',
                          hintText: 'e.g. Aadhaar Card',
                          prefixIcon: const Icon(
                              Icons.drive_file_rename_outline_rounded,
                              color: AppTheme.primary,
                              size: 20),
                          filled: true,
                          fillColor: const Color(0xFFFAF8FF),
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE9D5FF))),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: Color(0xFFE9D5FF))),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(
                                  color: AppTheme.primary, width: 2)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // ── Category Section ─────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Choose Category',
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF374151))),
                          const SizedBox(height: 12),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                            childAspectRatio: 2.8,
                            children: [
                              DocCategory.certificates,
                              DocCategory.idProofs,
                              DocCategory.medical,
                              DocCategory.other,
                            ].map((cat) {
                              final isSelected = selectedCat == cat;
                              return GestureDetector(
                                onTap: () =>
                                    setSheetState(() => selectedCat = cat),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? cat.color
                                        : cat.bgColor,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: isSelected
                                          ? cat.color
                                          : cat.color.withValues(alpha: 0.25),
                                      width: isSelected ? 2 : 1.5,
                                    ),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                              color: cat.color
                                                  .withValues(alpha: 0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            )
                                          ]
                                        : [],
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(cat.icon,
                                          size: 18,
                                          color: isSelected
                                              ? Colors.white
                                              : cat.color),
                                      const SizedBox(width: 8),
                                      Text(cat.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                            color: isSelected
                                                ? Colors.white
                                                : cat.color,
                                          )),
                                      if (isSelected) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                            Icons.check_circle_rounded,
                                            size: 14,
                                            color: Colors.white),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // ── Action Buttons ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                try { File(filePath).deleteSync(); } catch (_) {}
                                Navigator.pop(ctx);
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF6B7280),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                side: const BorderSide(
                                    color: Color(0xFFE5E7EB), width: 1.5),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: const Text('Cancel',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            flex: 2,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppTheme.primary, Color(0xFF8B5CF6)],
                                ),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primary
                                        .withValues(alpha: 0.35),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                              ),
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  final doc = VaultDocument(
                                    id: DateTime.now()
                                        .millisecondsSinceEpoch
                                        .toString(),
                                    title: titleController.text
                                            .trim()
                                            .isEmpty
                                        ? 'Untitled Document'
                                        : titleController.text.trim(),
                                    filePath: filePath,
                                    fileName: fileName,
                                    category: selectedCat,
                                    uploadedAt: DateTime.now(),
                                    fileSizeBytes: fileSize,
                                    fileExtension: ext,
                                  );
                                  setState(
                                      () => _documents.insert(0, doc));
                                  _saveDocuments();
                                  Navigator.pop(ctx);
                                  _showSuccess('Document saved!');
                                },
                                icon: const Icon(Icons.save_rounded,
                                    color: Colors.white, size: 18),
                                label: const Text('Save Document',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 14),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(14)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _fmtSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  // ── DELETE ─────────────────────────────────────────────────────────────────

  void _confirmDelete(VaultDocument doc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Document',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${doc.title}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteDocument(doc);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _deleteDocument(VaultDocument doc) {
    try {
      final f = File(doc.filePath);
      if (f.existsSync()) f.deleteSync();
    } catch (_) {}
    setState(() => _documents.removeWhere((d) => d.id == doc.id));
    _saveDocuments();
    _showSuccess('Document deleted');
  }

  // ── OPEN ───────────────────────────────────────────────────────────────────

  Future<void> _openDocument(VaultDocument doc) async {
    final result = await OpenFile.open(doc.filePath);
    if (result.type != ResultType.done && mounted) {
      _showError('Cannot open this file type');
    }
  }

  // ── RENAME ─────────────────────────────────────────────────────────────────

  void _renameDocument(VaultDocument doc) {
    final ctrl = TextEditingController(text: doc.title);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Rename', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: InputDecoration(
            border:
                OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final newTitle = ctrl.text.trim();
              if (newTitle.isNotEmpty) {
                setState(() {
                  final idx = _documents.indexWhere((d) => d.id == doc.id);
                  if (idx != -1) {
                    _documents[idx] = VaultDocument(
                      id: doc.id,
                      title: newTitle,
                      filePath: doc.filePath,
                      fileName: doc.fileName,
                      category: doc.category,
                      uploadedAt: doc.uploadedAt,
                      fileSizeBytes: doc.fileSizeBytes,
                      fileExtension: doc.fileExtension,
                    );
                  }
                });
                _saveDocuments();
              }
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ────────────────────────────────────────────────────────────────

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  void _showSuccess(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: const Color(0xFF059669),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── FILTERED LIST ──────────────────────────────────────────────────────────

  List<VaultDocument> get _filtered {
    return _documents.where((d) {
      final matchCat = _selectedCategory == DocCategory.all ||
          d.category == _selectedCategory;
      final matchSearch = _searchQuery.isEmpty ||
          d.title.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchCat && matchSearch;
    }).toList();
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton(
        onPressed: _showUploadOptions,
        backgroundColor: AppTheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── HEADER ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(
                    bottom: BorderSide(color: AppTheme.border, width: 1.5)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                          onPressed: widget.onBack,
                          icon: const Icon(Icons.arrow_back_rounded,
                              color: AppTheme.textMain)),
                      const Expanded(
                        child: Text('Document Vault',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textMain)),
                      ),
                      IconButton(
                        onPressed: () =>
                            setState(() => _isGridView = !_isGridView),
                        icon: Icon(
                            _isGridView
                                ? Icons.view_list_rounded
                                : Icons.grid_view_rounded,
                            color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search your documents...',
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: AppTheme.textSecondary),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.close_rounded,
                                  color: AppTheme.textSecondary, size: 20),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Category filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      children: DocCategory.values.map((cat) {
                        final isSelected = _selectedCategory == cat;
                        final count = cat == DocCategory.all
                            ? _documents.length
                            : _documents
                                .where((d) => d.category == cat)
                                .length;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.primary
                                    : Colors.white,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                    color: isSelected
                                        ? AppTheme.primary
                                        : AppTheme.border,
                                    width: 1.5),
                              ),
                              child: Row(
                                children: [
                                  Text(cat.label,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.textMain)),
                                  if (count > 0) ...[
                                    const SizedBox(width: 5),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white.withValues(alpha: 0.3)
                                            : AppTheme.primary.withValues(alpha: 0.1),
                                        borderRadius:
                                            BorderRadius.circular(10),
                                      ),
                                      child: Text('$count',
                                          style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : AppTheme.primary)),
                                    )
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── BODY ────────────────────────────────────────────────────────
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppTheme.primary))
                  : filtered.isEmpty
                      ? _EmptyState(
                          isSearching: _searchQuery.isNotEmpty,
                          onUpload: _showUploadOptions,
                        )
                      : _isGridView
                          ? _buildGrid(filtered)
                          : _buildList(filtered),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<VaultDocument> docs) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: docs.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        if (i == docs.length) return const SizedBox(height: 80);
        return _DocumentListCard(
          doc: docs[i],
          onOpen: () => _openDocument(docs[i]),
          onDelete: () => _confirmDelete(docs[i]),
          onRename: () => _renameDocument(docs[i]),
        );
      },
    );
  }

  Widget _buildGrid(List<VaultDocument> docs) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.82,
      ),
      itemCount: docs.length,
      itemBuilder: (_, i) => _DocumentGridCard(
        doc: docs[i],
        onOpen: () => _openDocument(docs[i]),
        onDelete: () => _confirmDelete(docs[i]),
        onRename: () => _renameDocument(docs[i]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// UPLOAD BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _UploadBottomSheet extends StatelessWidget {
  final VoidCallback onPickFile;
  final VoidCallback onPickImage;
  final VoidCallback onPickCamera;

  const _UploadBottomSheet({
    required this.onPickFile,
    required this.onPickImage,
    required this.onPickCamera,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          const Text('Add Document',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937))),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _UploadOption(
                icon: Icons.insert_drive_file_rounded,
                label: 'Files\n(PDF, DOC)',
                color: AppTheme.primary,
                bg: const Color(0xFFF3E8FF),
                onTap: onPickFile,
              ),
              _UploadOption(
                icon: Icons.photo_library_rounded,
                label: 'Gallery\n(Images)',
                color: const Color(0xFF0284C7),
                bg: const Color(0xFFBAE6FD),
                onTap: onPickImage,
              ),
              _UploadOption(
                icon: Icons.camera_alt_rounded,
                label: 'Camera\n(Scan)',
                color: const Color(0xFF065F46),
                bg: const Color(0xFFA7F3D0),
                onTap: onPickCamera,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UploadOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color bg;
  final VoidCallback onTap;

  const _UploadOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3), width: 1.5),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: FontWeight.w600,
                  height: 1.4)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LIST CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentListCard extends StatelessWidget {
  final VaultDocument doc;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _DocumentListCard({
    required this.doc,
    required this.onOpen,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: doc.isImage
                  ? Image.file(
                      File(doc.filePath),
                      width: 50, height: 50,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _iconBox(doc.category),
                    )
                  : _iconBox(doc.category),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: doc.category.bgColor,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(doc.category.label,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: doc.category.color)),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${doc.formattedSize} · ${DateFormat('dd MMM yyyy').format(doc.uploadedAt)}',
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppTheme.textSecondary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (v) {
                if (v == 'open') onOpen();
                if (v == 'rename') onRename();
                if (v == 'delete') onDelete();
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'open',
                    child: Row(children: [
                      Icon(Icons.open_in_new_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Open')
                    ])),
                const PopupMenuItem(
                    value: 'rename',
                    child: Row(children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Rename')
                    ])),
                const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [
                      Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                      SizedBox(width: 10),
                      Text('Delete', style: TextStyle(color: Colors.red))
                    ])),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconBox(DocCategory cat) {
    return Container(
      width: 50, height: 50,
      decoration: BoxDecoration(
        color: cat.bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(cat.icon, color: cat.color, size: 24),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// GRID CARD
// ─────────────────────────────────────────────────────────────────────────────

class _DocumentGridCard extends StatelessWidget {
  final VaultDocument doc;
  final VoidCallback onOpen;
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _DocumentGridCard({
    required this.doc,
    required this.onOpen,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onOpen,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: AppTheme.border, width: 1.5),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6A1B9A).withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(14)),
                child: doc.isImage
                    ? Image.file(File(doc.filePath),
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholderPreview(doc.category))
                    : _placeholderPreview(doc.category),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(doc.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1F2937)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          DateFormat('dd MMM yy').format(doc.uploadedAt),
                          style: const TextStyle(
                              fontSize: 11, color: AppTheme.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      PopupMenuButton<String>(
                        padding: EdgeInsets.zero,
                        iconSize: 18,
                        icon: const Icon(Icons.more_vert_rounded,
                            color: AppTheme.textSecondary, size: 18),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        onSelected: (v) {
                          if (v == 'open') onOpen();
                          if (v == 'rename') onRename();
                          if (v == 'delete') onDelete();
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(
                              value: 'open', child: Text('Open')),
                          const PopupMenuItem(
                              value: 'rename', child: Text('Rename')),
                          PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete',
                                  style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholderPreview(DocCategory cat) {
    return Container(
      color: cat.bgColor,
      child: Center(child: Icon(cat.icon, color: cat.color, size: 40)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onUpload;

  const _EmptyState({required this.isSearching, required this.onUpload});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFF3E8FF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Icon(
                isSearching
                    ? Icons.search_off_rounded
                    : Icons.folder_open_rounded,
                color: AppTheme.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              isSearching ? 'No documents found' : 'Your vault is empty',
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937)),
            ),
            const SizedBox(height: 8),
            Text(
              isSearching
                  ? 'Try a different search term'
                  : 'Upload your certificates, ID proofs,\nand medical records to keep them safe.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 14, color: AppTheme.textSecondary, height: 1.5),
            ),
            if (!isSearching) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onUpload,
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: const Text('Upload Document',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 28, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
