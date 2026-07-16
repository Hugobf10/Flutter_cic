import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
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
      const fields = <String>[
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
      ];
      try {
        _partner = await _odoo.read(
          'res.partner',
          auth.partnerId,
          fields: fields,
        );
      } catch (_) {
        final profile = <String, dynamic>{};
        for (final field in fields) {
          try {
            profile.addAll(
              await _odoo.read('res.partner', auth.partnerId, fields: [field]),
            );
          } catch (_) {
            // Un campo opcional ausente no debe ocultar el resto del perfil.
          }
        }
        _partner = profile;
      }
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
          onPressed: _loading || !auth.canEditModule('profile')
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
                _ProfileHero(
                  name: name,
                  email: (_partner['email'] ?? auth.userLogin).toString(),
                  unitName: auth.unidadNombre,
                  avatar: _buildAvatar(name),
                ),
                const SizedBox(height: 14),
                const AppSectionHeader(
                  title: 'Información personal',
                  subtitle: 'Datos básicos del perfil',
                ),
                _InfoTile(
                  icon: Icons.phone_outlined,
                  label: 'Teléfono',
                  value: (_partner['phone'] ?? '-').toString(),
                ),
                _InfoTile(
                  icon: Icons.smartphone_outlined,
                  label: 'Móvil',
                  value: (_partner['mobile'] ?? '-').toString(),
                ),
                _InfoTile(
                  icon: Icons.badge_outlined,
                  label: 'Puesto',
                  value: (_partner['function'] ?? '-').toString(),
                ),
                const SizedBox(height: 14),
                const AppSectionHeader(
                  title: 'Documentación',
                  subtitle: 'Archivos asociados al perfil',
                ),
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
    final cvId = OdooValues.many2oneId(cvRef);
    final cvName = (_partner['cv_attachment_name'] ?? 'CV').toString();
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.description_rounded,
              color: AppTheme.primary,
            ),
          ),
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('No se pudo abrir el CV: $e')),
                  );
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
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.surfaceElevated,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.textSecondary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.textSecondaryFor(context),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    value,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.name,
    required this.email,
    required this.unitName,
    required this.avatar,
  });

  final String name;
  final String email;
  final String unitName;
  final Widget avatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: AppTheme.radiusLg,
        boxShadow: AppTheme.glowShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
            ),
            child: avatar,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 13,
                  ),
                ),
                if (unitName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unidad: $unitName',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
