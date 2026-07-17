import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';

class RegisterExternalTrainingScreen extends StatefulWidget {
  const RegisterExternalTrainingScreen({super.key});

  @override
  State<RegisterExternalTrainingScreen> createState() =>
      _RegisterExternalTrainingScreenState();
}

class _RegisterExternalTrainingScreenState
    extends State<RegisterExternalTrainingScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();

  final _titleCtrl = TextEditingController();
  final _entityCtrl = TextEditingController();
  final _hoursCtrl = TextEditingController();
  DateTime? _endDate;
  bool _saving = false;
  PickedUploadFile? _pickedCertificate;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _entityCtrl.dispose();
    _hoursCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCertificate() async {
    final file = await _attachments.pickPdf();
    if (file == null) return;
    setState(() => _pickedCertificate = file);
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (_titleCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el nombre de la formación.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action(
          'training_create',
          values: {
            'name': _titleCtrl.text.trim(),
            'entidad': _entityCtrl.text.trim(),
            if (_endDate != null) 'fecha_realizacion': _formatDate(_endDate!),
            'duracion': double.tryParse(_hoursCtrl.text.trim()) ?? 0,
            if (_pickedCertificate != null) ...{
              'certificate_data': _pickedCertificate!.base64Data,
              'certificate_name': _pickedCertificate!.name,
            },
          },
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Formación registrada correctamente.')),
        );
        Navigator.of(context).pop(true);
        return;
      }
      final trainingId = await _odoo.create('calidad.formacion', {
        'name': _titleCtrl.text.trim(),
        'origen': 'externa',
        'tipo': 'externa',
        'tipo_formacion': 'externa',
        if (_endDate != null) 'fecha_fin': _formatDate(_endDate!),
        if (_entityCtrl.text.trim().isNotEmpty)
          'descripcion': 'Entidad: ${_entityCtrl.text.trim()}',
      });

      final attendanceId = await _odoo.create('calidad.formacion.asistencia', {
        'formacion_id': trainingId,
        'partner_id': auth.partnerId,
        'estado': 'realizado',
        if (_hoursCtrl.text.trim().isNotEmpty)
          'horas_realizadas': double.tryParse(_hoursCtrl.text.trim()) ?? 0,
      });

      if (_pickedCertificate != null) {
        await _odoo.write('calidad.formacion.asistencia', attendanceId, {
          'certificado_name': _pickedCertificate!.name,
          'certificado_data': _pickedCertificate!.base64Data,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Formación registrada correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo registrar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Registrar formación externa',
      child: ListView(
        children: [
          AppInput(
            controller: _titleCtrl,
            labelText: 'Nombre de la formación',
            prefixIcon: Icons.school_outlined,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _entityCtrl,
            labelText: 'Entidad / centro',
            prefixIcon: Icons.business_outlined,
          ),
          const SizedBox(height: 10),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.event_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _endDate == null
                        ? 'Fecha de finalización'
                        : _formatDate(_endDate!),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _saving
                      ? null
                      : () async {
                          final now = DateTime.now();
                          final date = await showDatePicker(
                            context: context,
                            initialDate: now,
                            firstDate: DateTime(now.year - 10),
                            lastDate: DateTime(now.year + 10),
                          );
                          if (date != null) setState(() => _endDate = date);
                        },
                  child: const Text('Elegir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _hoursCtrl,
            labelText: 'Horas',
            prefixIcon: Icons.schedule_rounded,
          ),
          const SizedBox(height: 12),
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.attach_file_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _pickedCertificate?.name ?? 'Adjuntar certificado (PDF)',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _pickCertificate,
                  child: const Text('Subir'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Enviar solicitud',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
