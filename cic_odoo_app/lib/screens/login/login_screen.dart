import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/providers/app_state_provider.dart';
import '../../app/ui/app_components.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_motion.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController = TextEditingController(text: AppConfig.odooBaseUrl);
  final _databaseController = TextEditingController(
    text: AppConfig.odooDatabaseName,
  );

  bool _obscurePassword = true;
  bool _showAdvanced = false;

  @override
  void dispose() {
    _loginController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await context.read<AuthProvider>().login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
      serverUrl: _serverController.text.trim(),
      database: _databaseController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final appState = context.watch<AppStateProvider>();

    return Scaffold(
      backgroundColor: AppTheme.surfaceFor(context),
      body: Container(
        decoration: BoxDecoration(gradient: AppTheme.heroGradientFor(context)),
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 16,
                child: _ThemeToggle(
                  dark: AppTheme.isDark(context),
                  onTap: appState.toggleThemeMode,
                ),
              ),
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 76, 20, 30),
                  child: AppReveal(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1100),
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth < 760) {
                            return _mobileLayout(auth);
                          }
                          return _desktopLayout(auth);
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mobileLayout(AuthProvider auth) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _BrandHeader(compact: true),
        const SizedBox(height: 24),
        _loginCard(auth),
        const SizedBox(height: 14),
        const _PrivacyNotice(),
        const SizedBox(height: 14),
        const _AccessHelp(),
      ],
    );
  }

  Widget _desktopLayout(AuthProvider auth) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Expanded(flex: 11, child: _BrandPanel()),
        const SizedBox(width: 34),
        Expanded(
          flex: 9,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _loginCard(auth),
              const SizedBox(height: 14),
              const _PrivacyNotice(),
              const SizedBox(height: 14),
              const _AccessHelp(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _loginCard(AuthProvider auth) {
    final loading = auth.state == AuthState.loading;
    return NeumorphicSurface(
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.all(24),
      child: AutofillGroup(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconSurface(
                    icon: Icons.lock_person_rounded,
                    color: AppTheme.primary,
                    size: 54,
                    iconSize: 25,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Accede a tu espacio',
                          style: TextStyle(
                            color: AppTheme.textPrimaryFor(context),
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Usa las mismas credenciales que en Odoo Web.',
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _LoginFieldSurface(
                child: TextFormField(
                  controller: _loginController,
                  enabled: !loading,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [
                    AutofillHints.username,
                    AutofillHints.email,
                  ],
                  decoration: const InputDecoration(
                    labelText: 'Correo corporativo',
                    hintText: 'tu.usuario@cicancer.org',
                    prefixIcon: Icon(Icons.alternate_email_rounded),
                  ),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Introduce tu correo corporativo'
                      : null,
                ),
              ),
              const SizedBox(height: 13),
              _LoginFieldSurface(
                child: TextFormField(
                  controller: _passwordController,
                  enabled: !loading,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: Icon(Icons.password_rounded),
                    suffixIcon: IconButton(
                      tooltip: _obscurePassword
                          ? 'Mostrar contraseña'
                          : 'Ocultar contraseña',
                      onPressed: loading
                          ? null
                          : () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                      ),
                    ),
                  ),
                  validator: (value) => (value == null || value.isEmpty)
                      ? 'Introduce tu contraseña'
                      : null,
                  onFieldSubmitted: (_) => loading ? null : _handleLogin(),
                ),
              ),
              if (AppConfig.allowAdvancedLoginConfig) ...[
                const SizedBox(height: 10),
                _advancedConfig(loading),
              ],
              if (auth.state == AuthState.error &&
                  auth.errorMessage != null) ...[
                const SizedBox(height: 14),
                _ErrorBox(message: auth.errorMessage!),
              ],
              const SizedBox(height: 20),
              SizedBox(
                height: 54,
                child: AppButton.primary(
                  label: loading ? 'Verificando' : 'Entrar',
                  icon: Icons.arrow_forward_rounded,
                  loading: loading,
                  onPressed: loading ? null : _handleLogin,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    size: 15,
                    color: AppTheme.textMutedFor(context),
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Sesión cifrada y permisos sincronizados con Odoo.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppTheme.textMutedFor(context),
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _advancedConfig(bool loading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppChoicePill(
          label: 'Configuración de soporte',
          icon: Icons.tune_rounded,
          selected: _showAdvanced,
          onTap: loading
              ? null
              : () => setState(() => _showAdvanced = !_showAdvanced),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 12),
            child: Column(
              children: [
                _LoginFieldSurface(
                  child: TextFormField(
                    controller: _serverController,
                    enabled: !loading,
                    decoration: const InputDecoration(
                      labelText: 'Servidor autorizado',
                      prefixIcon: Icon(Icons.dns_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Introduce el servidor autorizado'
                        : null,
                  ),
                ),
                const SizedBox(height: 10),
                _LoginFieldSurface(
                  child: TextFormField(
                    controller: _databaseController,
                    enabled: !loading,
                    decoration: const InputDecoration(
                      labelText: 'Entorno autorizado',
                      prefixIcon: Icon(Icons.storage_outlined),
                    ),
                    validator: (value) =>
                        (value == null || value.trim().isEmpty)
                        ? 'Introduce el entorno autorizado'
                        : null,
                  ),
                ),
              ],
            ),
          ),
          crossFadeState: _showAdvanced
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 220),
        ),
      ],
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({required this.dark, required this.onTap});

  final bool dark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: dark ? 'Usar modo claro' : 'Usar modo oscuro',
      child: NeumorphicSurface(
        onTap: onTap,
        subtle: true,
        borderRadius: AppTheme.radiusXl,
        padding: const EdgeInsets.all(11),
        child: Icon(
          dark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
          color: dark ? AppTheme.warning : AppTheme.primaryDark,
          size: 21,
        ),
      ),
    );
  }
}

class _BrandHeader extends StatelessWidget {
  const _BrandHeader({required this.compact});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: compact
          ? CrossAxisAlignment.center
          : CrossAxisAlignment.start,
      children: [
        NeumorphicSurface(
          subtle: true,
          borderRadius: BorderRadius.circular(30),
          padding: const EdgeInsets.all(8),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(23),
            child: Image.asset(
              'assets/branding/cic_logo.png',
              width: compact ? 88 : 108,
              height: compact ? 88 : 108,
              fit: BoxFit.cover,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Tu espacio CIC',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: AppTheme.textPrimaryFor(context),
            fontSize: compact ? 31 : 40,
            height: 1.03,
            fontWeight: FontWeight.w900,
            letterSpacing: -1.2,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          'Información, gestiones y seguimiento conectados con tu perfil.',
          textAlign: compact ? TextAlign.center : TextAlign.left,
          style: TextStyle(
            color: AppTheme.textSecondaryFor(context),
            fontSize: compact ? 14 : 16,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      borderRadius: AppTheme.radiusLg,
      padding: const EdgeInsets.all(32),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _BrandHeader(compact: false),
          SizedBox(height: 26),
          _ValueCard(
            icon: Icons.dashboard_customize_rounded,
            color: AppTheme.primary,
            title: 'Todo lo importante, ordenado',
            subtitle:
                'Documentos, noticias, actividad y accesos en un mismo inicio.',
          ),
          SizedBox(height: 10),
          _ValueCard(
            icon: Icons.task_alt_rounded,
            color: AppTheme.success,
            title: 'Gestiones conectadas',
            subtitle: 'Reservas, incidencias y procesos actualizados con Odoo.',
          ),
          SizedBox(height: 10),
          _ValueCard(
            icon: Icons.shield_outlined,
            color: AppTheme.accent,
            title: 'Acceso según tu perfil',
            subtitle:
                'Cada persona ve únicamente los módulos que tiene autorizados.',
          ),
        ],
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      subtle: true,
      showBorder: false,
      padding: const EdgeInsets.all(13),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(icon: icon, color: color, size: 42, iconSize: 19),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LoginFieldSurface extends StatelessWidget {
  const _LoginFieldSurface({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      subtle: true,
      showBorder: false,
      borderRadius: AppTheme.radiusMd,
      child: ClipRRect(borderRadius: AppTheme.radiusMd, child: child),
    );
  }
}

class _PrivacyNotice extends StatelessWidget {
  const _PrivacyNotice();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconSurface(
            icon: Icons.privacy_tip_outlined,
            color: AppTheme.success,
            size: 42,
            iconSize: 19,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Privacidad desde el primer paso',
                  style: TextStyle(
                    color: AppTheme.textPrimaryFor(context),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Antes de identificarte no cargamos avisos, datos personales ni información de Odoo. Después verás solo lo autorizado para tu perfil.',
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccessHelp extends StatelessWidget {
  const _AccessHelp();

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      subtle: true,
      showBorder: false,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.help_outline_rounded, color: AppTheme.primary, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: '¿Problemas para entrar? ',
                    style: TextStyle(
                      color: AppTheme.textPrimaryFor(context),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextSpan(
                    text:
                        'Comprueba tus credenciales habituales y, si continúa, contacta con el responsable de tu cuenta CIC.',
                    style: TextStyle(color: AppTheme.textSecondaryFor(context)),
                  ),
                ],
              ),
              style: const TextStyle(fontSize: 11, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return NeumorphicSurface(
      subtle: true,
      color: Color.alphaBlend(
        AppTheme.danger.withValues(
          alpha: AppTheme.isDark(context) ? 0.13 : 0.07,
        ),
        AppTheme.cardFor(context),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIconSurface(
            icon: Icons.error_outline_rounded,
            color: AppTheme.danger,
            size: 38,
            iconSize: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No hemos podido verificar el acceso',
                  style: TextStyle(
                    color: AppTheme.danger,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
                    fontSize: 11,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
