import 'package:flutter/material.dart';

import '../../features/communications/communications_screen.dart';
import '../../l10n/strings.dart';
import '../../theme/app_theme.dart';

class QualityCenterScreen extends StatelessWidget {
  const QualityCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(context.uiText('Calidad', 'Quality'))),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        children: [
          Text(
            context.uiText('Centro de calidad', 'Quality center'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryFor(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            context.uiText(
              'Gestiona comunicaciones y sugerencias relacionadas con calidad.',
              'Manage quality communications and suggestions.',
            ),
            style: TextStyle(color: AppTheme.textSecondaryFor(context)),
          ),
          const SizedBox(height: 14),
          _entry(
            context,
            icon: Icons.chat_bubble_outline_rounded,
            title: context.l10n.communications,
            subtitle: context.uiText(
              'Gestión de comunicaciones de calidad',
              'Quality communications management',
            ),
            to: const CommunicationsScreen(),
          ),
        ],
      ),
    );
  }

  Widget _entry(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget to,
  }) {
    return InkWell(
      borderRadius: AppTheme.radiusMd,
      onTap: () {
        Navigator.of(context).push(MaterialPageRoute(builder: (_) => to));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.cardFor(context),
          borderRadius: AppTheme.radiusMd,
          border: Border.all(
            color: AppTheme.dividerFor(context).withValues(alpha: 0.6),
          ),
          boxShadow: AppTheme.subtleShadowFor(context),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.12),
                borderRadius: AppTheme.radiusSm,
              ),
              child: Icon(icon, size: 20, color: AppTheme.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryFor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textMutedFor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.textMutedFor(context),
            ),
          ],
        ),
      ),
    );
  }
}
