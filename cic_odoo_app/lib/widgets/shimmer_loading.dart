import 'package:flutter/material.dart';

import '../app/ui/app_components.dart';

/// Compatibilidad con las pantallas antiguas: toda carga usa el flequillito.
class ShimmerLoading extends StatelessWidget {
  const ShimmerLoading({
    super.key,
    this.width = double.infinity,
    this.height = 80,
    this.borderRadius,
  });

  final double width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: const AppLoadingView(),
    );
  }
}

/// Conserva la API anterior, mostrando un único indicador de carga de marca.
class ShimmerList extends StatelessWidget {
  const ShimmerList({super.key, this.count = 5, this.itemHeight = 72});

  final int count;
  final double itemHeight;

  @override
  Widget build(BuildContext context) => const AppLoadingView();
}
