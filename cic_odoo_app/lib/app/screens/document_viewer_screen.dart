import 'dart:io';

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

class DocumentViewerScreen extends StatelessWidget {
  const DocumentViewerScreen({
    super.key,
    required this.file,
    required this.title,
    required this.mimeType,
    this.allowExternalOpen = true,
  });

  final File file;
  final String title;
  final String mimeType;
  final bool allowExternalOpen;

  bool get _isPdf => mimeType.toLowerCase().contains('pdf');
  bool get _isImage => mimeType.toLowerCase().startsWith('image/');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (allowExternalOpen && !_isPdf && !_isImage)
            IconButton(
              onPressed: () => OpenFilex.open(file.path),
              icon: Icon(Icons.open_in_new_rounded),
              tooltip: context.uiText('Abrir archivo', 'Open file'),
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
            Icon(
              Icons.insert_drive_file_rounded,
              size: 48,
              color: AppTheme.textMutedFor(context),
            ),
            const SizedBox(height: 12),
            Text(
              context.uiText(
                'Vista previa no disponible para este formato.',
                'Preview is not available for this format.',
              ),
              style: TextStyle(color: AppTheme.textSecondaryFor(context)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            if (allowExternalOpen)
              ElevatedButton.icon(
                onPressed: () => OpenFilex.open(file.path),
                icon: Icon(Icons.open_in_new_rounded),
                label: Text(context.uiText('Abrir archivo', 'Open file')),
              )
            else
              Text(
                context.uiText(
                  'Este documento solo puede consultarse como PDF o imagen.',
                  'This document can only be viewed as a PDF or image.',
                ),
                style: TextStyle(color: AppTheme.textMutedFor(context)),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
