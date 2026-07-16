import 'package:flutter/material.dart';

import '../../app/screens/document_viewer_screen.dart';
import '../../app/ui/app_components.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';

class PayrollScreen extends StatefulWidget {
  const PayrollScreen({super.key});

  @override
  State<PayrollScreen> createState() => _PayrollScreenState();
}

class _PayrollScreenState extends State<PayrollScreen> {
  final OdooService _odoo = OdooService();
  final AttachmentService _attachments = AttachmentService();
  final TextEditingController _searchCtrl = TextEditingController();

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      List<dynamic> rows;
      try {
        rows = await _odoo.searchRead(
          'payroll.document',
          fields: const [
            'name',
            'document_type',
            'month',
            'month_label',
            'year',
            'attachment_id',
            'imported_at',
          ],
          order: 'year desc, month desc, id desc',
          limit: 200,
        );
      } catch (e) {
        if (!OdooService.isMethodUnavailable(e)) rethrow;
        final payslips = await _odoo.searchRead(
          'hr.payslip',
          fields: const ['name', 'number', 'date_from', 'date_to', 'state'],
          order: 'date_from desc, id desc',
          limit: 200,
        );
        rows = payslips.map((raw) {
          final row = OdooValues.map(raw);
          final date = OdooValues.dateTime(row['date_from']);
          return <String, dynamic>{
            'id': row['id'],
            'name': OdooValues.string(
              row['name'],
              fallback: OdooValues.string(row['number'], fallback: 'Nómina'),
            ),
            'month_label': date == null
                ? ''
                : date.month.toString().padLeft(2, '0'),
            'year': date?.year ?? '',
            'imported_at': row['date_to'],
          };
        }).toList();
      }
      _rows = rows.whereType<Map>().map(Map<String, dynamic>.from).toList();
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchCtrl.text.trim().toLowerCase();
    final filtered = _rows.where((row) {
      if (query.isEmpty) return true;
      final name = (row['name'] ?? '').toString().toLowerCase();
      final year = (row['year'] ?? '').toString().toLowerCase();
      final month = (row['month_label'] ?? '').toString().toLowerCase();
      return name.contains(query) ||
          year.contains(query) ||
          month.contains(query);
    }).toList();

    return AppScaffold(
      title: 'Nóminas',
      actions: [
        IconButton(onPressed: _load, icon: const Icon(Icons.refresh_rounded)),
      ],
      child: Column(
        children: [
          AppSearchBar(
            controller: _searchCtrl,
            hintText: 'Buscar nóminas...',
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildBody(filtered)),
        ],
      ),
    );
  }

  Widget _buildBody(List<Map<String, dynamic>> rows) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return AppEmptyState(
        title: 'No se pudieron cargar las nóminas',
        subtitle: _error!,
        icon: Icons.error_outline_rounded,
      );
    }
    if (rows.isEmpty) {
      return const AppEmptyState(
        title: 'Sin nóminas',
        subtitle: 'No hay documentos de nómina disponibles.',
        icon: Icons.picture_as_pdf_rounded,
      );
    }
    return ListView.builder(
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        final title = (row['name'] ?? 'Nómina').toString();
        final month = (row['month_label'] ?? row['month'] ?? '-').toString();
        final year = (row['year'] ?? '-').toString();
        final importedAt = (row['imported_at'] ?? '').toString();
        final subtitle =
            '$month/$year · ${importedAt.isEmpty ? "sin fecha" : importedAt}';
        final attachmentId = OdooValues.many2oneId(row['attachment_id']);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AppPdfCard(
            title: title,
            subtitle: subtitle,
            onDownload: attachmentId == null
                ? () {}
                : () => _cacheOnly(attachmentId, title),
            onPreview: attachmentId == null
                ? null
                : () => _open(attachmentId, title),
          ),
        );
      },
    );
  }

  Future<void> _open(int attachmentId, String defaultName) async {
    try {
      final local = await _attachments.fetchAttachmentToCache(
        attachmentId: attachmentId,
        defaultName: defaultName,
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DocumentViewerScreen(
            file: local.file,
            title: local.name,
            mimeType: local.mimeType,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo abrir: $e')));
    }
  }

  Future<void> _cacheOnly(int attachmentId, String defaultName) async {
    try {
      final local = await _attachments.fetchAttachmentToCache(
        attachmentId: attachmentId,
        defaultName: defaultName,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Documento descargado: ${local.file.path}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo descargar: $e')));
    }
  }
}
