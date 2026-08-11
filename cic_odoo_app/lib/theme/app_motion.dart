import 'dart:async';

import 'package:flutter/material.dart';

/// Ritmo de movimiento común para mantener la interfaz serena y coherente.
class AppMotion {
  AppMotion._();

  static const Duration quick = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 240);
  static const Duration emphasized = Duration(milliseconds: 380);
  static const Duration stagger = Duration(milliseconds: 36);

  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve emphasizedCurve = Curves.easeOutBack;

  static bool reduceMotion(BuildContext context) {
    return MediaQuery.maybeOf(context)?.disableAnimations ?? false;
  }

  static Duration adaptive(BuildContext context, Duration duration) {
    return reduceMotion(context) ? Duration.zero : duration;
  }
}

/// Transición discreta compartida por todas las rutas Material de la app.
class AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (AppMotion.reduceMotion(context)) return child;

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppMotion.enterCurve,
      reverseCurve: AppMotion.exitCurve,
    );
    return FadeTransition(
      opacity: Tween<double>(begin: 0.88, end: 1).animate(curved),
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0.025, 0.012),
          end: Offset.zero,
        ).animate(curved),
        child: child,
      ),
    );
  }
}

/// Entrada suave reutilizable para cabeceras, tarjetas y elementos de rejilla.
class AppReveal extends StatefulWidget {
  const AppReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.025),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<AppReveal> createState() => _AppRevealState();
}

class _AppRevealState extends State<AppReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.emphasized,
  );
  Timer? _timer;
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;

    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
      return;
    }
    if (widget.delay == Duration.zero) {
      _controller.forward();
    } else {
      _timer = Timer(widget.delay, () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppMotion.enterCurve,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: widget.offset,
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

/// Cambia de sección sin destruir el estado de las pantallas no visibles.
class AppAnimatedIndexedStack extends StatelessWidget {
  const AppAnimatedIndexedStack({
    super.key,
    required this.index,
    required this.children,
  });

  final int index;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final duration = AppMotion.adaptive(context, AppMotion.standard);
    return Stack(
      fit: StackFit.expand,
      children: List.generate(children.length, (i) {
        final selected = i == index;
        final horizontalOffset = i < index ? -0.018 : 0.018;
        return IgnorePointer(
          ignoring: !selected,
          child: ExcludeFocus(
            excluding: !selected,
            child: ExcludeSemantics(
              excluding: !selected,
              child: AnimatedOpacity(
                opacity: selected ? 1 : 0,
                duration: duration,
                curve: selected ? AppMotion.enterCurve : AppMotion.exitCurve,
                child: AnimatedSlide(
                  offset: selected ? Offset.zero : Offset(horizontalOffset, 0),
                  duration: duration,
                  curve: selected ? AppMotion.enterCurve : AppMotion.exitCurve,
                  child: TickerMode(enabled: selected, child: children[i]),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}
