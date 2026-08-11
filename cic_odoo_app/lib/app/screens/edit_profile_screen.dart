import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/attachment_service.dart';
import '../../services/app_permission_service.dart';
import '../../services/odoo_service.dart';
import '../../services/portal_api_service.dart';
import '../ui/app_components.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.partnerData});

  final Map<String, dynamic> partnerData;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final AttachmentService _attachments = AttachmentService();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _mobileCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _notesCtrl;

  bool _saving = false;
  String? _cvName;
  String? _cvData;
  String? _avatarData;

  int get _partnerId => (widget.partnerData['id'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: (widget.partnerData['name'] ?? '').toString(),
    );
    _emailCtrl = TextEditingController(
      text: (widget.partnerData['email'] ?? '').toString(),
    );
    _phoneCtrl = TextEditingController(
      text: (widget.partnerData['phone'] ?? '').toString(),
    );
    _mobileCtrl = TextEditingController(
      text: (widget.partnerData['mobile'] ?? '').toString(),
    );
    _positionCtrl = TextEditingController(
      text: (widget.partnerData['function'] ?? '').toString(),
    );
    _notesCtrl = TextEditingController(
      text: (widget.partnerData['comment'] ?? '').toString(),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _mobileCtrl.dispose();
    _positionCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickCv() async {
    final file = await _attachments.pickPdf();
    if (file == null) return;
    setState(() {
      _cvName = file.name;
      _cvData = file.base64Data;
    });
  }

  Future<void> _pickAvatar() async {
    final granted = await AppPermissionService.requestPhotos();
    if (!granted) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Necesitamos permiso de Fotos para cambiar la imagen.'),
        ),
      );
      return;
    }
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 86,
      maxWidth: 1400,
      maxHeight: 1400,
    );
    if (image == null) return;
    final bytes = await image.readAsBytes();
    if (bytes.isEmpty) return;
    setState(() => _avatarData = base64Encode(bytes));
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action(
          'profile_update',
          values: {
            'email': _emailCtrl.text.trim(),
            'phone': _phoneCtrl.text.trim(),
            'mobile': _mobileCtrl.text.trim(),
            if (_avatarData != null) 'image_data': _avatarData,
            if (_cvData != null) 'cv_data': _cvData,
            if (_cvName != null) 'cv_name': _cvName,
          },
        );
      } else {
        await _odoo.write('res.partner', _partnerId, {
          'name': _nameCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'mobile': _mobileCtrl.text.trim(),
          'function': _positionCtrl.text.trim(),
          'comment': _notesCtrl.text.trim(),
          if (_avatarData != null) 'image_1920': _avatarData,
          if (_cvData != null) 'cv_attachment_name': _cvName ?? 'CV.pdf',
          if (_cvData != null) 'cv_attachment_data': _cvData,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('No se pudo guardar: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCv = (widget.partnerData['cv_attachment_name'] ?? '')
        .toString();
    return AppScaffold(
      title: 'Editar perfil',
      child: ListView(
        children: [
          AppSectionHeader(
            title: 'Datos personales',
            action: AppButton.outline(
              label: 'Foto',
              icon: Icons.photo_camera_outlined,
              onPressed: _saving ? null : _pickAvatar,
            ),
          ),
          AppInput(
            controller: _nameCtrl,
            labelText: 'Nombre completo',
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _emailCtrl,
            labelText: 'Correo electrónico',
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _phoneCtrl,
            labelText: 'Teléfono',
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _mobileCtrl,
            labelText: 'Móvil',
            prefixIcon: Icons.smartphone_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _positionCtrl,
            labelText: 'Puesto',
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _notesCtrl,
            labelText: 'Notas',
            prefixIcon: Icons.notes_rounded,
          ),
          const SizedBox(height: 16),
          const AppSectionHeader(title: 'Currículum'),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cvName ??
                        (currentCv.isEmpty ? 'Sin CV cargado' : currentCv),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _pickCv,
                  child: Text('Seleccionar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: 'Guardar cambios',
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
