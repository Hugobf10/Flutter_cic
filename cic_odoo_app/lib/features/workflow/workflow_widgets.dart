import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import 'workflow_stage.dart';

class WorkflowStepperBar extends StatelessWidget {
  const WorkflowStepperBar({
    super.key,
    required this.stages,
    required this.currentKey,
  });

  final List<WorkflowStage> stages;
  final String currentKey;

  @override
  Widget build(BuildContext context) {
    final idx = stages.indexWhere((e) => e.key == currentKey);

    return Row(
      children: List.generate(stages.length, (i) {
        final stage = stages[i];
        final active = i == idx;
        final done = i < idx;

        return Expanded(
          child: Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: done || active ? AppTheme.primary : AppTheme.surfaceElevated,
                  border: Border.all(
                    color: done || active ? AppTheme.primary : AppTheme.divider,
                  ),
                ),
                child: Center(
                  child: Text(
                    done ? '✓' : '${i + 1}',
                    style: TextStyle(
                      color: done || active ? Colors.white : AppTheme.textMuted,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                stage.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  color: active ? AppTheme.primary : AppTheme.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}

class WorkflowStateChip extends StatelessWidget {
  const WorkflowStateChip({
    super.key,
    required this.label,
    required this.color,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: AppTheme.radiusXl,
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}
