import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/attachment_service.dart';
import '../../services/app_permission_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../l10n/strings.dart';
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
  late String _communicationChannel;

  bool _saving = false;
  String? _cvName;
  String? _cvData;
  String? _avatarData;

  int get _partnerId => (widget.partnerData['id'] as num).toInt();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['name']),
    );
    _emailCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['email']),
    );
    _phoneCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['phone']),
    );
    _mobileCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['mobile']),
    );
    _positionCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['function']),
    );
    _notesCtrl = TextEditingController(
      text: OdooValues.string(widget.partnerData['comment']),
    );
    const allowedChannels = {'odoo', 'email', 'ambos'};
    final configuredChannel = widget
        .partnerData['comunicaciones_canal_notificacion']
        ?.toString();
    _communicationChannel = allowedChannels.contains(configuredChannel)
        ? configuredChannel!
        : 'odoo';
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
        SnackBar(
          content: Text(
            context.uiText(
              'Necesitamos permiso de Fotos para cambiar la imagen.',
              'Photos permission is required to change the image.',
            ),
          ),
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
            'comunicaciones_canal_notificacion': _communicationChannel,
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
          'comunicaciones_canal_notificacion': _communicationChannel,
          if (_avatarData != null) 'image_1920': _avatarData,
          if (_cvData != null) 'cv_attachment_name': _cvName ?? 'CV.pdf',
          if (_cvData != null) 'cv_attachment_data': _cvData,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.uiText(
              'Perfil actualizado correctamente.',
              'Profile updated successfully.',
            ),
          ),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.uiText('No se pudo guardar', 'Could not save')}: $e',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentCv = OdooValues.string(
      widget.partnerData['cv_attachment_name'],
    );
    return AppScaffold(
      title: context.uiText('Editar perfil', 'Edit profile'),
      child: ListView(
        children: [
          AppSectionHeader(
            title: context.uiText('Datos personales', 'Personal details'),
            action: AppButton.outline(
              label: context.uiText('Foto', 'Photo'),
              icon: Icons.photo_camera_outlined,
              onPressed: _saving ? null : _pickAvatar,
            ),
          ),
          AppInput(
            controller: _nameCtrl,
            labelText: context.uiText('Nombre completo', 'Full name'),
            prefixIcon: Icons.person_outline_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _emailCtrl,
            labelText: context.uiText('Correo electrónico', 'Email'),
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _phoneCtrl,
            labelText: context.uiText('Teléfono', 'Phone'),
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _mobileCtrl,
            labelText: context.uiText('Móvil', 'Mobile'),
            prefixIcon: Icons.smartphone_rounded,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _positionCtrl,
            labelText: context.uiText('Puesto', 'Position'),
            prefixIcon: Icons.badge_outlined,
          ),
          const SizedBox(height: 10),
          AppInput(
            controller: _notesCtrl,
            labelText: context.uiText('Notas', 'Notes'),
            prefixIcon: Icons.notes_rounded,
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            initialValue: _communicationChannel,
            decoration: InputDecoration(
              labelText: context.uiText(
                'Canal de comunicaciones',
                'Communication channel',
              ),
              prefixIcon: Icon(Icons.notifications_outlined),
            ),
            items: [
              DropdownMenuItem(
                value: 'odoo',
                child: Text(
                  context.uiText(
                    'Solo Odoo e intranet',
                    'Odoo and intranet only',
                  ),
                ),
              ),
              DropdownMenuItem(
                value: 'email',
                child: Text(
                  context.uiText('Solo correo electrónico', 'Email only'),
                ),
              ),
              DropdownMenuItem(
                value: 'ambos',
                child: Text(
                  context.uiText(
                    'Odoo/intranet y correo electrónico',
                    'Odoo/intranet and email',
                  ),
                ),
              ),
            ],
            onChanged: _saving
                ? null
                : (value) =>
                      setState(() => _communicationChannel = value ?? 'odoo'),
          ),
          const SizedBox(height: 16),
          AppSectionHeader(title: context.uiText('Currículum', 'CV')),
          AppCard(
            child: Row(
              children: [
                Icon(Icons.attach_file_rounded),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _cvName ??
                        (currentCv.isEmpty
                            ? context.uiText('Sin CV cargado', 'No CV uploaded')
                            : currentCv),
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: _saving ? null : _pickCv,
                  child: Text(context.uiText('Seleccionar', 'Select')),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          AppButton.primary(
            label: context.uiText('Guardar cambios', 'Save changes'),
            icon: Icons.check_rounded,
            loading: _saving,
            onPressed: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}
