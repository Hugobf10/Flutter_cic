import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../theme/app_theme.dart';

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({
    super.key,
    required this.file,
    required this.title,
    required this.mimeType,
  });

  final File file;
  final String title;
  final String mimeType;

  bool get _isPdf => mimeType.toLowerCase().contains('pdf');
  bool get _isImage => mimeType.toLowerCase().startsWith('image/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (!_isPdf && !_isImage)
            IconButton(
              onPressed: () => OpenFilex.open(file.path),
              icon: const Icon(Icons.open_in_new_rounded),
              tooltip: 'Abrir archivo',
            ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isPdf) {
      return SfPdfViewer.file(file);
    }
    if (_isImage) {
      return InteractiveViewer(
        maxScale: 6,
        child: Center(child: Image.file(file)),
      );
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.insert_drive_file_rounded, size: 48, color: AppTheme.textMuted),
            const SizedBox(height: 12),
            const Text(
              'Vista previa no disponible para este formato.',
              style: TextStyle(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => OpenFilex.open(file.path),
              icon: const Icon(Icons.open_in_new_rounded),
              label: const Text('Abrir archivo'),
            ),
          ],
        ),
      ),
    );
  }
}

