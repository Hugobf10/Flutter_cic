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
import 'screens/login/login_screen.dart';
import 'services/app_logger.dart';
import 'services/monitoring_service.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await MonitoringService.init();
  runZonedGuarded(() {
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
      AppLogger.error('Error no controlado de plataforma', error: error, stackTrace: stack, scope: 'bootstrap');
      return true;
    };
    ErrorWidget.builder = (FlutterErrorDetails details) => const _FatalWidget();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarIconBrightness: Brightness.dark,
    ));
    AppLogger.info('App iniciada', data: {'app': AppConfig.appName, 'env': AppConfig.odooBaseUrl}, scope: 'bootstrap');
    runApp(const CicSuperApp());
  }, (error, stack) {
    AppLogger.error('Error de zona no capturado', error: error, stackTrace: stack, scope: 'bootstrap');
  });
}

class CicSuperApp extends StatelessWidget {
  const CicSuperApp({super.key});

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
            home: const AuthGate(),
          );
        },
      ),
    );
  }
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
      if (!auth.hasIntranetAccess) {
        return const _NoIntranetAccessScreen();
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
              decoration: BoxDecoration(
                gradient: AppTheme.primaryGradient,
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(Icons.hexagon_rounded, color: Colors.white, size: 34),
            ),
            const SizedBox(height: 16),
            Text('CIC SuperApp', style: Theme.of(context).textTheme.headlineMedium),
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
              Icon(Icons.error_outline_rounded, color: AppTheme.danger, size: 42),
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

class _NoIntranetAccessScreen extends StatelessWidget {
  const _NoIntranetAccessScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_person_rounded, size: 44, color: AppTheme.warning),
              const SizedBox(height: 10),
              const Text('Sin acceso a intranet', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              const SizedBox(height: 6),
              const Text(
                'Tu usuario no tiene habilitado el portal de calidad. Contacta con administración.',
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
