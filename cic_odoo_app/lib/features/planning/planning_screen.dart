import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../action_plans/action_plans_screen.dart';
import '../chemicals/chemical_report_screen.dart';
import '../chemicals/chemicals_screen.dart';
import '../goals/goals_screen.dart';
import '../../providers/auth_provider.dart';

class PlanningScreen extends StatelessWidget {
  const PlanningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final tabs = <Tab>[];
    final screens = <Widget>[];
    if (auth.canViewModule('goals')) {
      tabs.add(const Tab(icon: Icon(Icons.flag_outlined), text: 'Objetivos'));
      screens.add(const GoalsScreen());
    }
    if (auth.canViewModule('action_plans')) {
      tabs.add(const Tab(icon: Icon(Icons.task_alt_rounded), text: 'Planes'));
      screens.add(const ActionPlansScreen());
    }
    if (auth.canViewModule('chemicals')) {
      tabs.add(const Tab(icon: Icon(Icons.science_outlined), text: 'Químicos'));
      screens.add(const ChemicalsScreen());
      tabs.add(const Tab(icon: Icon(Icons.analytics_outlined), text: 'Informe'));
      screens.add(const ChemicalReportScreen());
    }
    if (tabs.isEmpty) {
      return const Scaffold(
        body: Center(child: Text('No tienes permisos para ver Planificación.')),
      );
    }
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Planificación'),
          bottom: TabBar(
            isScrollable: true,
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: screens,
        ),
      ),
    );
  }
}
