import 'package:flutter/material.dart';

import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';
import '../models/app_module.dart';
import '../ui/app_components.dart';

class ModuleTile extends StatelessWidget {
  const ModuleTile({
    super.key,
    required this.module,
    required this.onTap,
    this.animationDelay = Duration.zero,
  });

  final AppModule module;
  final VoidCallback onTap;
  final Duration animationDelay;

  @override
  Widget build(BuildContext context) {
    return AppReveal(
      delay: animationDelay,
      offset: const Offset(0, 0.04),
      child: NeumorphicSurface(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppIconSurface(
                  icon: module.icon,
                  color: module.color,
                  size: 52,
                ),
                const Spacer(),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: module.color.withValues(alpha: 0.09),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_outward_rounded,
                    color: module.color,
                    size: 17,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              module.title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
                color: AppTheme.textPrimaryFor(context),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (module.description != null)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    module.description!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              )
            else
              const Spacer(),
            const SizedBox(height: 8),
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: module.implemented ? module.color : Colors.orange,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  module.implemented ? 'Disponible' : 'Próximamente',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: module.implemented
                        ? AppTheme.textSecondaryFor(context)
                        : Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
