import 'package:cic_odoo_app/theme/app_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('AppReveal respeta la preferencia de reducir movimiento', (
    tester,
  ) async {
    const contentKey = ValueKey('reveal-content');
    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: true),
          child: AppReveal(child: Text('Contenido', key: contentKey)),
        ),
      ),
    );

    final fadeFinder = find.descendant(
      of: find.byType(AppReveal),
      matching: find.byType(FadeTransition),
    );
    final fade = tester.widget<FadeTransition>(fadeFinder);
    expect(fade.opacity.value, 1);
  });

  testWidgets('el cambio de sección conserva las pantallas en el árbol', (
    tester,
  ) async {
    var selectedIndex = 0;
    late StateSetter updateHost;

    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return const SizedBox.expand(
              child: AppAnimatedIndexedStack(
                key: ValueKey('animated-stack'),
                index: 0,
                children: [Text('Inicio'), Text('Perfil')],
              ),
            );
          },
        ),
      ),
    );

    // Reconstruimos el host con otro índice manteniendo las mismas pantallas.
    await tester.pumpWidget(
      MaterialApp(
        home: StatefulBuilder(
          builder: (context, setState) {
            updateHost = setState;
            return SizedBox.expand(
              child: AppAnimatedIndexedStack(
                key: const ValueKey('animated-stack'),
                index: selectedIndex,
                children: const [Text('Inicio'), Text('Perfil')],
              ),
            );
          },
        ),
      ),
    );
    updateHost(() => selectedIndex = 1);
    await tester.pumpAndSettle();

    expect(find.text('Inicio'), findsOneWidget);
    expect(find.text('Perfil'), findsOneWidget);
    final opacityFinder = find.descendant(
      of: find.byKey(const ValueKey('animated-stack')),
      matching: find.byType(AnimatedOpacity),
    );
    final opacities = tester
        .widgetList<AnimatedOpacity>(opacityFinder)
        .map((widget) => widget.opacity)
        .toList();
    expect(opacities, [0, 1]);
  });
}
