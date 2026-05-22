import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _loginController = TextEditingController();
  final _passwordController = TextEditingController();
  final _serverController =
      TextEditingController(text: AppConfig.odooBaseUrl);
  final _databaseController =
      TextEditingController(text: AppConfig.odooDatabaseName);

  bool _obscurePassword = true;
  bool _showAdvanced = false;

  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController.forward();
    _slideController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _loginController.dispose();
    _passwordController.dispose();
    _serverController.dispose();
    _databaseController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    await auth.login(
      login: _loginController.text.trim(),
      password: _passwordController.text,
      serverUrl: _serverController.text.trim(),
      database: _databaseController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // ── Fondo con gradiente y formas decorativas ──
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A0F1C), Color(0xFF121820), Color(0xFF0D1B2A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          // Círculo decorativo superior derecho
          Positioned(
            top: -size.height * 0.12,
            right: -size.width * 0.2,
            child: Container(
              width: size.width * 0.7,
              height: size.width * 0.7,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.primary.withValues(alpha: 0.15),
                    AppTheme.primary.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
          // Círculo decorativo inferior izquierdo
          Positioned(
            bottom: -size.height * 0.08,
            left: -size.width * 0.15,
            child: Container(
              width: size.width * 0.5,
              height: size.width * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppTheme.accent.withValues(alpha: 0.1),
                    AppTheme.accent.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),

          // ── Contenido ──
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // ── Logo / Branding ──
                        _buildLogo(),
                        const SizedBox(height: 40),

                        // ── Formulario glass ──
                        _buildFormCard(auth),
                        const SizedBox(height: 24),

                        // ── Versión ──
                        Text(
                          'v${AppConfig.appVersion}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: AppTheme.radiusLg,
            boxShadow: AppTheme.glowShadow,
          ),
          child: const Icon(
            Icons.science_rounded,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'CIC Odoo',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: AppTheme.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Intranet · Calidad · Gestión',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
            fontWeight: FontWeight.w400,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AuthProvider auth) {
    return ClipRRect(
      borderRadius: AppTheme.radiusLg,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: AppTheme.radiusLg,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Iniciar Sesión',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Accede con tu cuenta corporativa',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textMuted,
                  ),
                ),
                const SizedBox(height: 28),

                TextFormField(
                  controller: _loginController,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon:
                        Icon(Icons.email_outlined, color: AppTheme.textMuted),
                  ),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Introduce tu email' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textMuted),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (v) => (v == null || v.isEmpty)
                      ? 'Introduce tu contraseña'
                      : null,
                  onFieldSubmitted: (_) => _handleLogin(),
                ),
                const SizedBox(height: 12),

                // Configuración avanzada
                GestureDetector(
                  onTap: () =>
                      setState(() => _showAdvanced = !_showAdvanced),
                  child: Row(
                    children: [
                      Icon(
                        _showAdvanced
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        color: AppTheme.textMuted,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      const Text(
                        'Configuración del servidor',
                        style: TextStyle(
                          color: AppTheme.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _serverController,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'URL del servidor',
                            prefixIcon: Icon(Icons.dns_outlined,
                                color: AppTheme.textMuted),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Introduce la URL'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _databaseController,
                          style: const TextStyle(
                              color: AppTheme.textPrimary, fontSize: 13),
                          decoration: const InputDecoration(
                            labelText: 'Base de datos',
                            prefixIcon: Icon(Icons.storage_outlined,
                                color: AppTheme.textMuted),
                          ),
                          validator: (v) => (v == null || v.isEmpty)
                              ? 'Introduce la base de datos'
                              : null,
                        ),
                      ],
                    ),
                  ),
                  crossFadeState: _showAdvanced
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 300),
                ),
                const SizedBox(height: 24),

                // Error
                if (auth.state == AuthState.error &&
                    auth.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.danger.withValues(alpha: 0.1),
                      borderRadius: AppTheme.radiusSm,
                      border: Border.all(
                        color: AppTheme.danger.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppTheme.danger, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            auth.errorMessage!,
                            style: const TextStyle(
                              color: AppTheme.danger,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Botones Login
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: auth.state == AuthState.loading
                        ? null
                        : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppTheme.radiusMd,
                      ),
                    ),
                    child: auth.state == AuthState.loading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Entrar',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
