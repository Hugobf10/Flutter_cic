import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';
import '../action_plans/action_plans_screen.dart';
import '../chemicals/chemical_report_screen.dart';
import '../chemicals/chemicals_screen.dart';
import '../goals/goals_screen.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final entries = auth.canViewModule('planning')
        ? <_PlanningEntry>[
            _PlanningEntry(
              title: context.l10n.goals,
              subtitle: context.l10n.goalsPlanningHint,
              icon: Icons.flag_outlined,
              color: AppTheme.primary,
              builder: () => const GoalsScreen(),
            ),
            _PlanningEntry(
              title: context.l10n.actionPlans,
              subtitle: context.l10n.actionPlansPlanningHint,
              icon: Icons.task_alt_rounded,
              color: AppTheme.warning,
              builder: () => const ActionPlansScreen(),
            ),
            _PlanningEntry(
              title: context.l10n.chemicals,
              subtitle: context.l10n.chemicalsPlanningHint,
              icon: Icons.science_outlined,
              color: AppTheme.success,
              builder: () => const ChemicalsScreen(),
            ),
            _PlanningEntry(
              title: context.l10n.chemicalReport,
              subtitle: context.l10n.chemicalReportPlanningHint,
              icon: Icons.analytics_outlined,
              color: AppTheme.info,
              builder: () => const ChemicalReportScreen(),
            ),
          ]
        : const <_PlanningEntry>[];

    return AppScaffold(
      title: context.l10n.planning,
      child: entries.isEmpty
          ? AppEmptyState(
              title: context.l10n.noAccess,
              subtitle: context.l10n.noPlanningAccess,
              icon: Icons.lock_outline_rounded,
            )
          : ListView.separated(
              padding: const EdgeInsets.only(bottom: 96),
              itemCount: entries.length,
              separatorBuilder: (_, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final entry = entries[index];
                return AppCard(
                  onTap: () => Navigator.of(
                    context,
                  ).push(MaterialPageRoute(builder: (_) => entry.builder())),
                  child: Row(
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: entry.color.withValues(alpha: 0.14),
                          borderRadius: AppTheme.radiusMd,
                        ),
                        child: Icon(entry.icon, color: entry.color),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.title,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryFor(context),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              entry.subtitle,
                              style: TextStyle(
                                color: AppTheme.textSecondaryFor(context),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _PlanningEntry {
  const _PlanningEntry({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.builder,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget Function() builder;
}
