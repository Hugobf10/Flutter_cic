import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:ui';

import 'app/providers/app_state_provider.dart';
import 'app/screens/superapp_shell.dart';
import 'config/app_config.dart';
import 'providers/auth_provider.dart';
import 'providers/dashboard_provider.dart';
import 'screens/reservas/reservation_entry_target.dart';
import 'screens/login/login_screen.dart';
import 'services/deep_link_service.dart';
import 'services/app_logger.dart';
import 'services/monitoring_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MonitoringService.init();
  runZonedGuarded(
    () {
      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        AppLogger.error(
          'FlutterError capturado',
          error: details.exception,
          stackTrace: details.stack,
          scope: 'bootstrap',
        );
      };
      PlatformDispatcher.instance.onError = (error, stack) {
        AppLogger.error(
          'Error no controlado de plataforma',
          error: error,
          stackTrace: stack,
          scope: 'bootstrap',
        );
        return true;
      };
      ErrorWidget.builder = (FlutterErrorDetails details) =>
          const _FatalWidget();
      SystemChrome.setSystemUIOverlayStyle(
        const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
      );
      AppLogger.info(
        'App iniciada',
        data: {'app': AppConfig.appName, 'env': AppConfig.odooBaseUrl},
        scope: 'bootstrap',
      );
      runApp(const CicSalamancaApp());
    },
    (error, stack) {
      AppLogger.error(
        'Error de zona no capturado',
        error: error,
        stackTrace: stack,
        scope: 'bootstrap',
      );
    },
  );
}

class CicSalamancaApp extends StatelessWidget {
  const CicSalamancaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => AppStateProvider()),
      ],
      child: Consumer<AppStateProvider>(
        builder: (context, appState, _) {
          return MaterialApp(
            title: AppConfig.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: appState.themeMode,
            home: const _DeepLinkBootstrap(child: AuthGate()),
          );
        },
      ),
    );
  }
}

class _DeepLinkBootstrap extends StatefulWidget {
  const _DeepLinkBootstrap({required this.child});

  final Widget child;

  @override
  State<_DeepLinkBootstrap> createState() => _DeepLinkBootstrapState();
}

class _DeepLinkBootstrapState extends State<_DeepLinkBootstrap> {
  final DeepLinkService _deepLinkService = DeepLinkService();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _deepLinkService.start(_handleIncomingUri);
    });
  }

  @override
  void dispose() {
    _deepLinkService.dispose();
    super.dispose();
  }

  void _handleIncomingUri(Uri uri) {
    final target = ReservationEntryTarget.fromUri(uri);
    if (target == null || !mounted) return;
    context.read<AppStateProvider>().setPendingReservationTarget(target);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().tryAutoLogin();
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.state == AuthState.initial || auth.state == AuthState.loading) {
      return const _SplashScreen();
    }

    if (auth.isAuthenticated) {
      if (!auth.hasAppAccess) {
        return const _NoAppAccessScreen();
      }
      return const SuperAppShell();
    }

    return const LoginScreen();
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.divider),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/branding/cic_logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'CIC Salamanca',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 14),
            const SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 2.6),
            ),
          ],
        ),
      ),
    );
  }
}

class _FatalWidget extends StatelessWidget {
  const _FatalWidget();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(
                Icons.error_outline_rounded,
                color: AppTheme.danger,
                size: 42,
              ),
              SizedBox(height: 10),
              Text(
                'Ha ocurrido un error inesperado.',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              SizedBox(height: 6),
              Text(
                'Reinicia la app o contacta con soporte.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NoAppAccessScreen extends StatelessWidget {
  const _NoAppAccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.lock_person_rounded,
                size: 44,
                color: AppTheme.warning,
              ),
              const SizedBox(height: 10),
              const Text(
                'Sin acceso disponible',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const SizedBox(height: 6),
              const Text(
                'Tu usuario ha iniciado sesión, pero no tiene módulos habilitados para usar la app. Revisa el acceso portal o los permisos asignados en Odoo.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.read<AuthProvider>().logout(),
                child: const Text('Cerrar sesión'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
