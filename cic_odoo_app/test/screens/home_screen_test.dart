import 'package:cic_odoo_app/app/models/app_notification.dart';
import 'package:cic_odoo_app/app/providers/app_state_provider.dart';
import 'package:cic_odoo_app/providers/auth_provider.dart';
import 'package:cic_odoo_app/providers/dashboard_provider.dart';
import 'package:cic_odoo_app/screens/home/home_screen.dart';
import 'package:cic_odoo_app/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Inicio sigue la jerarquía visual neumórfica aprobada', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp(ThemeMode.light));
    await tester.pumpAndSettle();

    expect(find.text('CIC'), findsOneWidget);
    expect(find.textContaining('Hugo'), findsOneWidget);
    expect(find.text('Incidencias'), findsOneWidget);
    expect(find.text('Reservas'), findsOneWidget);
    expect(find.text('Formación'), findsOneWidget);
    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('Personal'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
    expect(find.text('Compras'), findsOneWidget);
    expect(find.text('Calidad'), findsOneWidget);
    expect(find.text('Novedades'), findsOneWidget);
    expect(find.text('Tu día'), findsNothing);
  });

  testWidgets('Inicio mantiene la composición y contraste en modo oscuro', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp(ThemeMode.dark));
    await tester.pumpAndSettle();

    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
    expect(materialApp.themeMode, ThemeMode.dark);
    expect(find.textContaining('Hugo'), findsOneWidget);
    expect(find.text('Accesos rápidos'), findsOneWidget);
    expect(find.text('Novedades'), findsOneWidget);
  });

  testWidgets('Inicio portal sustituye Compras por accesos de autoservicio', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_homeApp(ThemeMode.light, auth: _PortalHomeAuth()));
    await tester.pumpAndSettle();

    expect(find.text('Mi espacio'), findsOneWidget);
    expect(find.text('Documentos'), findsOneWidget);
    expect(find.text('Reservas'), findsWidgets);
    expect(find.text('Formación'), findsWidgets);
    expect(find.text('Compras'), findsNothing);
    expect(find.text('Personal'), findsNothing);
  });
}

Widget _homeApp(ThemeMode themeMode, {AuthProvider? auth}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: auth ?? _HomeAuth()),
      ChangeNotifierProvider<DashboardProvider>.value(value: _HomeDashboard()),
      ChangeNotifierProvider<AppStateProvider>.value(value: _HomeState()),
    ],
    child: MaterialApp(
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeScreen(),
    ),
  );
}

class _HomeAuth extends AuthProvider {
  @override
  String get userName => 'Hugo Benítez';

  @override
  bool get isInternalUser => true;

  @override
  String get profileImageBase64 => '';

  @override
  bool canViewModule(String moduleKey) => true;
}

class _PortalHomeAuth extends _HomeAuth {
  static const _portalModules = {
    'portal',
    'documents',
    'reservas',
    'training',
    'communications',
    'payroll',
  };

  @override
  bool get isInternalUser => false;

  @override
  bool get isPortalOnlyUser => true;

  @override
  bool canViewModule(String moduleKey) => _portalModules.contains(moduleKey);
}

class _HomeDashboard extends DashboardProvider {
  static const _items = <Map<String, dynamic>>[
    {
      'title': 'Incidencias abiertas',
      'value': 12,
      'helper': 'Abiertas',
      'module_key': 'incidents',
    },
    {
      'title': 'Reservas de hoy',
      'value': 3,
      'helper': 'Hoy',
      'module_key': 'reservas',
    },
    {
      'title': 'Formación pendiente',
      'value': 2,
      'helper': 'Pendientes',
      'module_key': 'training',
    },
  ];

  @override
  DashboardState get state => DashboardState.loaded;

  @override
  Map<String, dynamic>? get dashboardData => const {'kpis': _items};

  @override
  List<dynamic> get kpis => _items;

  @override
  Future<void> loadDashboard({Map<String, dynamic>? filters}) async {}

  @override
  Future<void> loadFilterOptions() async {}
}

class _HomeState extends AppStateProvider {
  @override
  int get unreadNotifications => 3;

  @override
  List<AppNotification> get notifications => const [];
}
