import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';
import '../providers/app_state_provider.dart';
import '../screens/document_viewer_screen.dart';
import '../ui/app_components.dart';
import 'edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final OdooService _odoo = OdooService();
  final AttachmentService _attachments = AttachmentService();

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _partner = const {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (auth.partnerId <= 0) {
      setState(() {
        _loading = false;
        _error = 'No se encontró el perfil del usuario.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _partner = await _odoo.read(
        'res.partner',
        auth.partnerId,
        fields: const [
          'name',
          'email',
          'phone',
          'mobile',
          'function',
          'comment',
          'unidad_id',
          'cv_attachment_id',
          'cv_attachment_name',
          'image_1920',
        ],
      );
    } catch (e) {
      _error = OdooService.prettyError(e);
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppStateProvider>();
    final name = (_partner['name'] ?? auth.userName).toString().trim().isEmpty
        ? 'Usuario'
        : (_partner['name'] ?? auth.userName).toString();

    return AppScaffold(
      title: 'Mi perfil',
      actions: [
        IconButton(
          onPressed: _loading
              ? null
              : () async {
                  final saved = await Navigator.of(context).push<bool>(
                    MaterialPageRoute(
                      builder: (_) => EditProfileScreen(partnerData: _partner),
                    ),
                  );
                  if (saved == true) _load();
                },
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? AppEmptyState(
                  title: 'No se pudo cargar el perfil',
                  subtitle: _error!,
                  icon: Icons.error_outline_rounded,
                  action: AppButton.primary(label: 'Reintentar', onPressed: _load),
                )
              : ListView(
                  children: [
                    AppCard(
                      child: Row(
                        children: [
                          _buildAvatar(name),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                                Text(
                                  (_partner['email'] ?? auth.userLogin).toString(),
                                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                                ),
                                if (auth.unidadNombre.isNotEmpty)
                                  Text(
                                    'Unidad: ${auth.unidadNombre}',
                                    style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    const AppSectionHeader(title: 'Información personal'),
                    _InfoTile(label: 'Teléfono', value: (_partner['phone'] ?? '-').toString()),
                    _InfoTile(label: 'Móvil', value: (_partner['mobile'] ?? '-').toString()),
                    _InfoTile(label: 'Puesto', value: (_partner['function'] ?? '-').toString()),
                    const SizedBox(height: 14),
                    const AppSectionHeader(title: 'Currículum'),
                    _buildCvCard(),
                    const SizedBox(height: 14),
                    AppCard(
                      child: SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        value: appState.themeMode == ThemeMode.dark,
                        onChanged: (_) => appState.toggleThemeMode(),
                        title: const Text('Modo oscuro'),
                        subtitle: const Text('Alternar tema claro / oscuro'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppButton.primary(
                      label: 'Cerrar sesión',
                      icon: Icons.logout_rounded,
                      onPressed: () => context.read<AuthProvider>().logout(),
                    ),
                  ],
                ),
    );
  }

  Widget _buildAvatar(String name) {
    final raw = (_partner['image_1920'] ?? '').toString();
    if (raw.isEmpty) return AppAvatar(name: name, size: 54);
    try {
      final bytes = base64Decode(raw);
      return CircleAvatar(
        radius: 27,
        backgroundImage: MemoryImage(Uint8List.fromList(bytes)),
      );
    } catch (_) {
      return AppAvatar(name: name, size: 54);
    }
  }

  Widget _buildCvCard() {
    final cvRef = _partner['cv_attachment_id'];
    final cvId = (cvRef is List && cvRef.isNotEmpty) ? (cvRef.first as num).toInt() : null;
    final cvName = (_partner['cv_attachment_name'] ?? 'CV').toString();
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.description_rounded),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cvId == null ? 'No hay CV cargado' : cvName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          if (cvId != null)
            TextButton(
              onPressed: () async {
                try {
                  final local = await _attachments.fetchAttachmentToCache(
                    attachmentId: cvId,
                    defaultName: cvName,
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
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('No se pudo abrir el CV: $e')));
                }
              },
              child: const Text('Ver'),
            ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: const TextStyle(color: AppTheme.textSecondary)),
            ),
            Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

