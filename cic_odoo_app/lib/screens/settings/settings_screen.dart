import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Pantalla de ajustes y perfil del usuario.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: context.uiText('Ajustes', 'Settings'),
      child: ListView(
        children: [
          AppCard(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                AppAvatar(
                  name: auth.userName,
                  size: 58,
                  imageBase64: auth.profileImageBase64,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName,
                        style: TextStyle(
                          color: AppTheme.textPrimaryFor(context),
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.userLogin,
                        style: TextStyle(
                          color: AppTheme.textSecondaryFor(context),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 7),
                      AppStatusChip(
                        label: auth.isPortalOnlyUser
                            ? context.uiText('Usuario portal', 'Portal user')
                            : '${context.uiText('Usuario interno', 'Internal user')} · ID ${auth.userId}',
                        color: auth.isPortalOnlyUser
                            ? AppTheme.accent
                            : AppTheme.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(
            context,
            context.uiText('Información de conexión', 'Connection information'),
          ),
          _buildTile(
            context,
            Icons.dns_outlined,
            context.uiText('Servidor', 'Server'),
            auth.serverUrl.isNotEmpty ? auth.serverUrl : AppConfig.odooBaseUrl,
          ),
          _buildTile(
            context,
            Icons.storage_outlined,
            context.uiText('Base de datos', 'Database'),
            auth.database.isNotEmpty
                ? auth.database
                : AppConfig.odooDatabaseName,
          ),
          _buildTile(
            context,
            Icons.info_outline_rounded,
            context.uiText('Versión de la app', 'App version'),
            AppConfig.appVersion,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle(context, context.uiText('Cuenta', 'Account')),
          _buildActionTile(
            context: context,
            icon: Icons.logout_rounded,
            title: context.uiText('Cerrar sesión', 'Sign out'),
            subtitle: context.uiText(
              'Desconectarse de este dispositivo',
              'Sign out from this device',
            ),
            color: AppTheme.danger,
            onTap: () => _confirmLogout(context, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return AppSectionHeader(title: title);
  }

  Widget _buildTile(
    BuildContext context,
    IconData icon,
    String title,
    String value,
  ) {
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
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppTheme.textSecondaryFor(context),
                  fontSize: 13,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: TextStyle(
                  color: AppTheme.textPrimaryFor(context),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            AppIconSurface(icon: icon, color: color, size: 42, iconSize: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: AppTheme.textMutedFor(context),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.cardFor(context),
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
        title: Text(
          context.uiText('Cerrar sesión', 'Sign out'),
          style: TextStyle(color: AppTheme.textPrimaryFor(context)),
        ),
        content: Text(
          context.uiText(
            '¿Estás seguro de que deseas cerrar sesión?',
            'Are you sure you want to sign out?',
          ),
          style: TextStyle(color: AppTheme.textSecondaryFor(context)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.uiText('Cancelar', 'Cancel')),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () {
              Navigator.pop(context);
              auth.logout();
            },
            child: Text(context.uiText('Cerrar sesión', 'Sign out')),
          ),
        ],
      ),
    );
  }
}
