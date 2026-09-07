import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../providers/data_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';

class DocumentosScreen extends StatefulWidget {
  const DocumentosScreen({super.key});

  @override
  State<DocumentosScreen> createState() => _DocumentosScreenState();
}

class _DocumentosScreenState extends State<DocumentosScreen> {
  final DataProvider _provider = DataProvider();
  final OdooService _odoo = OdooService();
  final AttachmentService _attachments = AttachmentService();
  final TextEditingController _searchCtrl = TextEditingController();

  static const _fields = [
    'name',
    'codigo',
    'tipo_id',
    'publico',
    'version_count',
    'descarga_count',
    'version_actual_id',
    'unidad_id',
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _loadData({String? search}) {
    final domain = <dynamic>[];
    if (search != null && search.isNotEmpty) {
      domain.addAll([
        '|',
        ['name', 'ilike', search],
        ['codigo', 'ilike', search],
      ]);
    }
    _provider.loadRecords(
      'calidad.documento',
      domain: domain,
      fields: _fields,
      order: 'codigo, name',
      limit: 80,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _provider,
      child: AppScaffold(
        title: context.l10n.documentation,
        child: Column(
          children: [
            AppSearchBar(
              controller: _searchCtrl,
              hintText: context.l10n.searchDocuments,
              onSubmitted: (v) => _loadData(search: v),
              onChanged: (v) {
                if (v.isEmpty) _loadData();
                setState(() {});
              },
            ),
            const SizedBox(height: 12),
            Expanded(
              child: Consumer<DataProvider>(
                builder: (context, p, _) => _buildList(p),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(DataProvider p) {
    if (p.isLoading && p.records.isEmpty) {
      return const AppLoadingView();
    }
    if (p.errorMessage != null) {
      final limitedAccess = OdooService.isAccessError(p.errorMessage);
      return AppEmptyState(
        title: limitedAccess
            ? context.l10n.documentsLimitedAccess
            : context.l10n.couldNotLoadDocuments,
        subtitle: limitedAccess
            ? context.l10n.documentsLimitedAccessHint
            : p.errorMessage!,
        icon: limitedAccess
            ? Icons.lock_outline_rounded
            : Icons.error_outline_rounded,
      );
    }
    if (p.records.isEmpty) {
      return AppEmptyState(
        title: context.l10n.noDocuments,
        subtitle: context.l10n.noDocumentsHint,
        icon: Icons.folder_open_rounded,
      );
    }

    return RefreshIndicator(
      onRefresh: () async => _loadData(search: _searchCtrl.text),
      child: ListView.builder(
        itemCount: p.records.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppSectionHeader(
                title: context.l10n.documentsCount(p.totalCount),
              ),
            );
          }
          final doc = Map<String, dynamic>.from(p.records[i - 1] as Map);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _buildPdfCard(doc),
          );
        },
      ),
    );
  }

  Widget _buildPdfCard(Map<String, dynamic> doc) {
    final codigo = OdooValues.string(doc['codigo']);
    final title = OdooValues.string(
      doc['name'],
      fallback: context.l10n.document,
    );
    final versions = OdooValues.intValue(doc['version_count']) ?? 0;
    final subtitle = codigo.isEmpty
        ? 'PDF · ${context.l10n.versions(versions)}'
        : '$codigo · PDF · ${context.l10n.versions(versions)}';
    final id = OdooValues.intValue(doc['id']);

    return AppPdfCard(
      title: title,
      subtitle: subtitle,
      onDownload: () => _downloadDocument(id),
      onPreview: () => _previewDocument(id),
    );
  }

  Future<void> _previewDocument(int? id) async {
    if (id == null) return;
    final t = context.l10n;
    try {
      final attachment = _odoo.isPortalSession
          ? 0
          : await _resolveDocumentAttachmentId(id);
      if (attachment == null) {
        throw Exception(t.documentWithoutAttachment);
      }
      final file = await _attachments.fetchAttachmentToCache(
        attachmentId: attachment,
        defaultName: 'documento_$id.pdf',
        portalSection: 'documents',
        portalRecordId: id,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            file: file.file,
            title: file.name,
            mimeType: file.mimeType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${t.couldNotOpenDocument}: ${OdooService.prettyError(e)}',
          ),
        ),
      );
    }
  }

  Future<void> _downloadDocument(int? id) async {
    if (id == null) return;
    final t = context.l10n;
    try {
      final attachment = _odoo.isPortalSession
          ? 0
          : await _resolveDocumentAttachmentId(id);
      if (attachment == null) {
        throw Exception(t.documentWithoutAttachment);
      }
      final file = await _attachments.fetchAttachmentToCache(
        attachmentId: attachment,
        defaultName: 'documento_$id.pdf',
        portalSection: 'documents',
        portalRecordId: id,
      );
      if (!mounted) return;
      await Share.shareXFiles([
        XFile(file.file.path, name: file.name, mimeType: file.mimeType),
      ], subject: file.name);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${t.couldNotDownload}: ${OdooService.prettyError(e)}'),
        ),
      );
    }
  }

  Future<int?> _resolveDocumentAttachmentId(int documentId) async {
    final doc = await _odoo.read(
      'calidad.documento',
      documentId,
      fields: const ['version_actual_id'],
    );
    final versionRef = doc['version_actual_id'];
    if (versionRef is! List || versionRef.isEmpty) return null;
    final versionId = (versionRef.first as num).toInt();
    final version = await _odoo.read(
      'calidad.documento.version',
      versionId,
      fields: const ['attachment_id'],
    );
    final attachmentRef = version['attachment_id'];
    if (attachmentRef is! List || attachmentRef.isEmpty) return null;
    await _odoo.callRecordMethod('calidad.documento', [
      documentId,
    ], 'action_registrar_descarga');
    return (attachmentRef.first as num).toInt();
  }
}
