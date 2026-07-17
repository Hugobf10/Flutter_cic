import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_svg/flutter_svg.dart';
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

class _SplashScreen extends StatefulWidget {
  const _SplashScreen();

  @override
  State<_SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<_SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _SplashLogo(animation: _controller),
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

class _SplashLogo extends StatelessWidget {
  const _SplashLogo({required this.animation});

  final Animation<double> animation;

  double _flequilloJump(double phase) {
    if (phase < 0.12) return 0;
    if (phase < 0.28) {
      final progress = Curves.easeOutCubic.transform((phase - 0.12) / 0.16);
      return -18 * progress;
    }
    if (phase < 0.48) {
      final progress = Curves.easeOutBack.transform((phase - 0.28) / 0.20);
      return -18 + 21 * progress;
    }
    if (phase < 0.62) {
      final progress = Curves.easeOutCubic.transform((phase - 0.48) / 0.14);
      return 3 - 3 * progress;
    }
    return 0;
  }

  double _flequilloTilt(double phase) {
    if (phase < 0.28 || phase > 0.62) return 0;
    final progress = (phase - 0.28) / 0.34;
    return math.sin(progress * math.pi * 2) * 0.07;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.divider),
        boxShadow: const [
          BoxShadow(color: Color(0x1A1677FF), blurRadius: 24, spreadRadius: 2),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        fit: StackFit.expand,
        children: [
          Image.asset('assets/branding/cic_logo.png', fit: BoxFit.cover),
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 25,
            child: ColoredBox(color: Colors.white),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: animation,
              builder: (context, child) {
                final phase = animation.value;
                final jump = _flequilloJump(phase);
                final scale = 1 + (-jump / 150);

                return Transform.translate(
                  offset: Offset(0, jump),
                  child: Transform.rotate(
                    angle: _flequilloTilt(phase),
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: child,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.only(left: 3, right: 3, top: 1),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: SvgPicture.asset(
                    'assets/branding/cic_mark.svg',
                    fit: BoxFit.contain,
                    width: 42,
                    height: 31,
                  ),
                ),
              ),
            ),
          ),
        ],
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
