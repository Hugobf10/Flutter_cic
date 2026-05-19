import 'package:flutter/material.dart';

class AppModule {
  const AppModule({
    required this.key,
    required this.title,
    required this.icon,
    required this.color,
    this.implemented = false,
    this.route,
    this.requiredPermission,
    this.description,
  });

  final String key;
  final String title;
  final IconData icon;
  final Color color;
  final bool implemented;
  final String? route;
  final String? requiredPermission;
  final String? description;
}
