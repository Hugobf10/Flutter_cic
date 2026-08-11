import 'package:flutter/material.dart';

class ModulePlaceholderScreen extends StatelessWidget {
  const ModulePlaceholderScreen({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.construction_rounded, size: 44),
              const SizedBox(height: 12),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text(
                'Módulo en implementación.\nYa está registrado en la app y se activará con su flujo Odoo en la próxima entrega.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
