import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../app/ui/app_components.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

/// Pantalla de ajustes y perfil del usuario.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AppScaffold(
      title: 'Ajustes',
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGradient,
              borderRadius: AppTheme.radiusLg,
              boxShadow: AppTheme.glowShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 56, height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: AppTheme.radiusMd,
                  ),
                  child: Center(
                    child: Text(
                      _initials(auth.userName),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        auth.userLogin,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.82),
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'ID: ${auth.userId}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Información de conexión'),
          _buildTile(
            Icons.dns_outlined,
            'Servidor',
            auth.serverUrl.isNotEmpty ? auth.serverUrl : AppConfig.odooBaseUrl,
          ),
          _buildTile(
            Icons.storage_outlined,
            'Base de datos',
            auth.database.isNotEmpty
                ? auth.database
                : AppConfig.odooDatabaseName,
          ),
          _buildTile(
            Icons.info_outline_rounded,
            'Versión de la app',
            AppConfig.appVersion,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Cuenta'),
          _buildActionTile(
            icon: Icons.logout_rounded,
            title: 'Cerrar sesión',
            subtitle: 'Desconectarse de este dispositivo',
            color: AppTheme.danger,
            onTap: () => _confirmLogout(context, auth),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(title, style: const TextStyle(color: AppTheme.textMuted, fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
    );
  }

  Widget _buildTile(IconData icon, String title, String value) {
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
              child: Icon(icon, color: AppTheme.textMuted, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
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

  Widget _buildActionTile({required IconData icon, required String title, required String subtitle, required Color color, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.radiusMd,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.06),
            borderRadius: AppTheme.radiusMd,
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
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
                      style: const TextStyle(
                        color: AppTheme.textMuted,
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
      ),
    );
  }

  void _confirmLogout(BuildContext context, AuthProvider auth) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radiusMd),
        title: const Text('Cerrar sesión', style: TextStyle(color: AppTheme.textPrimary)),
        content: const Text('¿Estás seguro de que deseas cerrar sesión?', style: TextStyle(color: AppTheme.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.danger),
            onPressed: () { Navigator.pop(context); auth.logout(); },
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
  }

  String _initials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return parts[0][0].toUpperCase();
  }
}
