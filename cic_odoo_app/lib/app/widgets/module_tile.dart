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
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: module.color.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(module.icon, color: module.color, size: 22),
            ),
            const Spacer(),
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: module.implemented
                    ? module.color.withValues(alpha: 0.1)
                    : Colors.orange.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                module.implemented ? 'Disponible' : 'Próximamente',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: module.implemented ? module.color : Colors.orange,
                ),
              ),
            ),
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
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  module.description!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
