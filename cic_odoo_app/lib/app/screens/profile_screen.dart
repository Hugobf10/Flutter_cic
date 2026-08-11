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
import '../../services/portal_api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
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
      if (_odoo.isPortalSession) {
        final rows = await _portalApi.section('profile', limit: 1);
        final first = rows.isEmpty ? const <String, dynamic>{} : rows.first;
        _partner = OdooValues.map(first['partner']);
        if (_partner.isEmpty) {
          throw StateError('El servidor no devolvió el perfil de la intranet.');
        }
        if (mounted) setState(() => _loading = false);
        return;
      }
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
                  if (saved == true) {
                    await auth.refreshPartnerProfile();
                    await _load();
                  }
                },
          icon: Icon(Icons.edit_outlined),
        ),
      ],
      child: _loading
          ? const AppLoadingView()
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
                  avatar: AppAvatar(
                    name: name,
                    size: 58,
                    imageBase64: _profileImage(auth.profileImageBase64),
                  ),
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
                    title: Text('Modo oscuro'),
                    subtitle: Text('Alternar tema claro / oscuro'),
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

  String _profileImage(String fallback) {
    for (final raw in [
      _partner['image_128'],
      _partner['image_1920'],
      fallback,
    ]) {
      if (raw is String) {
        final value = raw.trim();
        final lower = value.toLowerCase();
        if (value.isNotEmpty && lower != 'false' && lower != 'null') {
          return value;
        }
      }
    }
    return '';
  }

  Widget _buildCvCard() {
    final cvRef = _partner['cv_attachment_id'];
    final cvId = OdooValues.many2oneId(cvRef);
    final cvName = (_partner['cv_attachment_name'] ?? 'CV').toString();
    return AppCard(
      child: Row(
        children: [
          const AppIconSurface(
            icon: Icons.description_rounded,
            color: AppTheme.primary,
            size: 42,
            iconSize: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              cvId == null ? 'No hay CV cargado' : cvName,
              style: TextStyle(fontWeight: FontWeight.w600),
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
              child: Text('Ver'),
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
            AppIconSurface(
              icon: icon,
              color: AppTheme.primary,
              size: 40,
              iconSize: 18,
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
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          avatar,
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: AppTheme.textPrimaryFor(context),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 13,
                  ),
                ),
                if (unitName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Unidad: $unitName',
                    style: TextStyle(
                      color: AppTheme.textMutedFor(context),
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
