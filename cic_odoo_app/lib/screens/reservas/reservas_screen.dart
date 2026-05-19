import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../config/app_config.dart';
import '../../providers/auth_provider.dart';
import '../../services/odoo_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key});

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservasScreenState extends State<ReservasScreen> {
  final OdooService _odoo = OdooService();
  final TextEditingController _motivoCtrl = TextEditingController();

  bool _isLoading = true;
  bool _isCreating = false;
  bool _isLoadingAvailability = false;
  bool _portalOnlyMode = false;
  String? _error;

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _sessionTypes = [];
  List<Map<String, dynamic>> _reservas = [];

  int? _serviceTemplateId;
  int? _variantId;
  int? _sessionTypeId;
  DateTime? _start;
  DateTime? _end;
  int _durationMinutes = 60;
  int _wizardStep = 0;
  DateTime _selectedDay = DateTime.now();
  List<DateTimeRange> _busyRanges = [];

  @override
  void initState() {
    super.initState();
    _start = _roundNextHalfHour(DateTime.now());
    _end = _start!.add(Duration(minutes: _durationMinutes));
    _loadInitial();
  }

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final services = await _odoo.searchRead(
        'product.template',
        domain: [
          ['reservable_cic', '=', true],
          ['detailed_type', '=', 'service'],
        ],
        fields: ['name'],
        order: 'name',
        limit: 200,
      );
      _services = services.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      if (_services.isNotEmpty) {
        _serviceTemplateId = _services.first['id'] as int;
        await _loadServiceOptions();
      }
      await _loadMisReservas();
    } catch (e) {
      if (OdooService.isAccessError(e)) {
        _portalOnlyMode = true;
        _error = 'Tu usuario portal no tiene acceso al motor interno de reservas.';
      } else {
        _error = OdooService.prettyError(e);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadServiceOptions() async {
    if (_serviceTemplateId == null) return;

    final variants = await _odoo.searchRead(
      'product.product',
      domain: [
        ['product_tmpl_id', '=', _serviceTemplateId],
        ['active', '=', true],
      ],
      fields: ['display_name', 'lst_price'],
      order: 'display_name',
      limit: 200,
    );

    final sessionTypes = await _odoo.searchRead(
      'reserva.session.type',
      domain: [
        ['servicio_template_id', '=', _serviceTemplateId],
        ['active', '=', true],
      ],
      fields: ['name', 'sequence'],
      order: 'sequence, name',
      limit: 100,
    );

    _variants = variants.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _sessionTypes = sessionTypes.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    _variantId = _variants.isNotEmpty ? _variants.first['id'] as int : null;
    _sessionTypeId = _sessionTypes.isNotEmpty ? _sessionTypes.first['id'] as int : null;
    await _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    if (_variantId == null) return;
    final startDay = DateTime(_selectedDay.year, _selectedDay.month, _selectedDay.day, 0, 0);
    final endDay = startDay.add(const Duration(days: 1));
    setState(() => _isLoadingAvailability = true);
    try {
      final rows = await _odoo.searchRead(
        'reserva.reserva',
        domain: [
          ['servicio_id', '=', _variantId],
          ['estado', 'in', ['borrador', 'confirmada', 'facturada']],
          ['fecha_inicio', '<', _formatOdooDateTime(endDay)],
          ['fecha_fin', '>', _formatOdooDateTime(startDay)],
        ],
        fields: ['fecha_inicio', 'fecha_fin'],
        order: 'fecha_inicio asc',
        limit: 400,
      );

      _busyRanges = rows.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        final start = _tryParseOdooDateTime(m['fecha_inicio']?.toString() ?? '');
        final end = _tryParseOdooDateTime(m['fecha_fin']?.toString() ?? '');
        if (start == null || end == null) {
          return DateTimeRange(start: startDay, end: startDay);
        }
        return DateTimeRange(start: start, end: end);
      }).where((r) => r.end.isAfter(r.start)).toList();

      if (_start != null && _isSlotBusy(_start!)) {
        _start = null;
        _end = null;
      }
    } catch (_) {
      _busyRanges = [];
    }
    if (mounted) setState(() => _isLoadingAvailability = false);
  }

  Future<void> _loadMisReservas() async {
    final auth = context.read<AuthProvider>();
    final partnerId = auth.partnerId;

    final result = await _odoo.searchRead(
      'reserva.reserva',
      domain: [
        ['contacto_id', '=', partnerId],
      ],
      fields: [
        'name',
        'servicio_id',
        'session_type_id',
        'fecha_inicio',
        'fecha_fin',
        'duracion',
        'importe_total',
        'estado',
        'motivo',
        'sale_order_id',
      ],
      order: 'fecha_inicio desc',
      limit: 200,
    );

    _reservas = result.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  void _setDurationMinutes(int minutes) {
    setState(() {
      _durationMinutes = minutes;
      if (_start != null) {
        _end = _start!.add(Duration(minutes: _durationMinutes));
      }
    });
  }

  void _nextStep() {
    if (_wizardStep == 0 && _serviceTemplateId == null) {
      _showSnack('Selecciona un servicio para continuar.', isError: true);
      return;
    }
    if (_wizardStep == 1 && _variantId == null) {
      _showSnack('Selecciona un recurso para continuar.', isError: true);
      return;
    }
    if (_wizardStep == 2 && _start == null) {
      _showSnack('Selecciona una franja horaria para continuar.', isError: true);
      return;
    }
    if (_wizardStep < 3) {
      setState(() => _wizardStep += 1);
    }
  }

  void _prevStep() {
    if (_wizardStep > 0) {
      setState(() => _wizardStep -= 1);
    }
  }

  Future<void> _crearReserva() async {
    if (_variantId == null || _start == null || _end == null) return;
    if (!_end!.isAfter(_start!)) {
      _showSnack('La fecha fin debe ser mayor que inicio.', isError: true);
      return;
    }

    setState(() => _isCreating = true);
    try {
      final partnerId = context.read<AuthProvider>().partnerId;
      await _odoo.create('reserva.reserva', {
        'servicio_id': _variantId,
        'contacto_id': partnerId,
        'fecha_inicio': _formatOdooDateTime(_start!),
        'fecha_fin': _formatOdooDateTime(_end!),
        'motivo': _motivoCtrl.text.trim(),
        if (_sessionTypeId != null) 'session_type_id': _sessionTypeId,
      });

      _motivoCtrl.clear();
      await _loadMisReservas();
      _showSnack('Reserva creada correctamente.');
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack('No se pudo crear: $e', isError: true);
    }

    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _confirmarReserva(int id) async {
    try {
      await _odoo.callRecordMethod('reserva.reserva', [id], 'action_confirmar');
      await _loadMisReservas();
      if (mounted) setState(() {});
      _showSnack('Reserva confirmada.');
    } catch (e) {
      _showSnack('No se pudo confirmar: $e', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppTheme.surface,
        body: Padding(
          padding: EdgeInsets.all(16),
          child: ShimmerList(),
        ),
      );
    }

    if (_error != null) {
      if (_portalOnlyMode) {
        return _buildPortalReservationMode();
      }
      return Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(title: const Text('Reservas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(_error!, style: const TextStyle(color: AppTheme.textMuted)),
          ),
        ),
      );
    }

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: AppTheme.surface,
        appBar: AppBar(
          title: const Text('Reservas'),
          actions: [
            IconButton(onPressed: _loadInitial, icon: const Icon(Icons.refresh_rounded)),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Nueva reserva', icon: Icon(Icons.add_circle_outline_rounded)),
              Tab(text: 'Mis reservas', icon: Icon(Icons.list_alt_rounded)),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  const SectionHeader(
                    title: 'Reserva rápida',
                    subtitle: 'Selecciona servicio, recurso y horario en 4 pasos',
                    icon: Icons.calendar_month_rounded,
                  ),
                  _buildNewReservationCard(),
                ],
              ),
            ),
            RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  SectionHeader(
                    title: 'Mis reservas',
                    subtitle: '${_reservas.length} registros',
                    icon: Icons.list_alt_rounded,
                  ),
                  ..._reservas.map(_buildReservaCard),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPortalReservationMode() {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          IconButton(onPressed: _loadInitial, icon: const Icon(Icons.refresh_rounded)),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 560),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: AppTheme.radiusMd,
              border: Border.all(color: AppTheme.divider),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.travel_explore_rounded, color: AppTheme.primary),
                    SizedBox(width: 8),
                    Text('Reservas en modo portal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Este perfil no tiene permisos de backend para crear reservas por RPC. Puedes gestionarlas desde el portal oficial.',
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _openReservationsPortal,
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Abrir portal de reservas'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openReservationsPortal() async {
    final auth = context.read<AuthProvider>();
    final base = (auth.serverUrl.isNotEmpty ? auth.serverUrl : AppConfig.odooBaseUrl).trim();
    final uri = Uri.parse('$base/my/reservas');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildNewReservationCard() {
    final selectedServiceList = _services.where((s) => s['id'] == _serviceTemplateId).toList();
    final selectedVariantList = _variants.where((v) => v['id'] == _variantId).toList();
    final selectedService = selectedServiceList.isEmpty ? null : selectedServiceList.first;
    final selectedVariant = selectedVariantList.isEmpty ? null : selectedVariantList.first;
    final hourlyPrice = selectedVariant?['lst_price'];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildWizardHeader(),
          const SizedBox(height: 12),
          AnimatedSize(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: _buildWizardStepContent(
                _wizardStep,
                selectedService,
                selectedVariant,
                hourlyPrice,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              if (_wizardStep > 0)
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _prevStep,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Atrás'),
                  ),
                ),
              if (_wizardStep > 0) const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _wizardStep == 3
                      ? (_isCreating ? null : _crearReserva)
                      : _nextStep,
                  icon: _wizardStep == 3
                      ? (_isCreating
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check_circle_outline_rounded))
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _wizardStep == 3
                        ? (_isCreating ? 'Creando...' : 'Confirmar y crear')
                        : 'Siguiente',
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWizardHeader() {
    const labels = ['Servicio', 'Recurso', 'Horario', 'Confirmar'];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == _wizardStep;
        final done = i < _wizardStep;
        return Expanded(
          child: Column(
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: done || active ? AppTheme.primary : AppTheme.surfaceElevated,
                child: Text(
                  done ? '✓' : '${i + 1}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: done || active ? Colors.white : AppTheme.textMuted,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: active ? AppTheme.primary : AppTheme.textMuted,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildWizardStepContent(
    int step,
    Map<String, dynamic>? selectedService,
    Map<String, dynamic>? selectedVariant,
    dynamic hourlyPrice,
  ) {
    switch (step) {
      case 0:
        return SingleChildScrollView(
          key: const ValueKey('step_service'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paso 1: elige el servicio', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((s) {
                  final id = s['id'] as int;
                  final selected = _serviceTemplateId == id;
                  return ChoiceChip(
                    label: Text((s['name'] ?? '').toString()),
                    selected: selected,
                    onSelected: (_) async {
                      if (selected) return;
                      setState(() => _serviceTemplateId = id);
                      await _loadServiceOptions();
                      if (mounted) setState(() {});
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      case 1:
        return SingleChildScrollView(
          key: const ValueKey('step_resource'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paso 2: elige recurso', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _variants.map((v) {
                  final id = v['id'] as int;
                  final selected = _variantId == id;
                  return ChoiceChip(
                    label: Text('${v['display_name']} (${_money(v['lst_price'])}/h)'),
                    selected: selected,
                    onSelected: (_) async {
                      if (selected) return;
                      setState(() => _variantId = id);
                      await _loadAvailability();
                    },
                  );
                }).toList(),
              ),
              if (_sessionTypes.isNotEmpty) ...[
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  key: ValueKey<int?>(_sessionTypeId),
                  initialValue: _sessionTypeId,
                  decoration: const InputDecoration(labelText: 'Tipo de sesión'),
                  items: _sessionTypes
                      .map((t) => DropdownMenuItem<int>(
                            value: t['id'] as int,
                            child: Text((t['name'] ?? '').toString()),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _sessionTypeId = v),
                ),
              ],
            ],
          ),
        );
      case 2:
        final days = List.generate(7, (i) => DateTime.now().add(Duration(days: i)));
        final slots = _availableSlotsForDay(_selectedDay);
        return SingleChildScrollView(
          key: const ValueKey('step_time'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Paso 3: elige horario', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              SizedBox(
                height: 44,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: days.length,
                  separatorBuilder: (_, index) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final d = days[i];
                    final selected = _sameDay(d, _selectedDay);
                    return ChoiceChip(
                      label: Text(_dayLabel(d)),
                      selected: selected,
                      onSelected: (_) async {
                        setState(() => _selectedDay = d);
                        await _loadAvailability();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              const Text('Horas disponibles', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              if (_isLoadingAvailability)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
                  final selected = _start != null && _start!.isAtSameMomentAs(slot);
                  final busy = _isSlotBusy(slot);
                  return ChoiceChip(
                    label: Text(_slotLabel(slot)),
                    selected: selected,
                    onSelected: busy
                        ? null
                        : (_) {
                      setState(() {
                        _start = slot;
                        _end = _start!.add(Duration(minutes: _durationMinutes));
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text('Duración', style: TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 60, 90, 120].map((minutes) {
                  final selected = _durationMinutes == minutes;
                  return ChoiceChip(
                    label: Text(_durationLabel(minutes)),
                    selected: selected,
                    onSelected: (_) {
                      _setDurationMinutes(minutes);
                      if (_start != null && _isSlotBusy(_start!)) {
                        setState(() {
                          _start = null;
                          _end = null;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        );
      default:
        return SingleChildScrollView(
          key: const ValueKey('step_confirm'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(labelText: 'Motivo (opcional)'),
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceElevated,
                  borderRadius: AppTheme.radiusSm,
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Text(
                  'Resumen: ${selectedService?['name'] ?? '-'} · ${selectedVariant?['display_name'] ?? '-'}\n'
                  '${_fmt(_start!)} -> ${_fmt(_end!)} · ${_money(((hourlyPrice is num ? hourlyPrice.toDouble() : 0) * (_durationMinutes / 60)))}',
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildReservaCard(Map<String, dynamic> r) {
    final id = (r['id'] as num).toInt();
    final estado = (r['estado'] ?? 'borrador').toString();
    final servicio = _nameFromMany2one(r['servicio_id']);
    final session = _nameFromMany2one(r['session_type_id']);
    final start = (r['fecha_inicio'] ?? '').toString();
    final end = (r['fecha_fin'] ?? '').toString();
    final duracion = (r['duracion'] as num?)?.toDouble() ?? 0;
    final total = (r['importe_total'] as num?)?.toDouble() ?? 0;
    final motivo = (r['motivo'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: AppTheme.radiusMd,
        border: Border.all(color: AppTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  servicio,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _estadoBadge(estado),
            ],
          ),
          const SizedBox(height: 6),
          Text('$start  ->  $end', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
          const SizedBox(height: 4),
          Text('Duración: ${duracion.toStringAsFixed(1)}h  ·  Total: ${_money(total)}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
          if (session.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Tipo: $session', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          if (motivo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('Motivo: $motivo', style: const TextStyle(color: AppTheme.textMuted, fontSize: 12)),
            ),
          if (estado == 'borrador') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _confirmarReserva(id),
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Confirmar'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    Color color;
    switch (estado) {
      case 'confirmada':
        color = AppTheme.info;
        break;
      case 'facturada':
        color = AppTheme.success;
        break;
      default:
        color = AppTheme.warning;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: AppTheme.radiusXl),
      child: Text(estado, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w700)),
    );
  }

  String _nameFromMany2one(dynamic v) {
    if (v is List && v.length >= 2) return v[1].toString();
    return '';
  }

  String _fmt(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$dd/$mm $hh:$mi';
  }

  String _formatOdooDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final h = dt.hour.toString().padLeft(2, '0');
    final mi = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$mi:00';
  }

  String _money(dynamic value) {
    final n = value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;
    return '${n.toStringAsFixed(2)} EUR';
  }

  String _durationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m' 'm';
    if (m == 0) return '$h' 'h';
    return '$h.5h';
  }

  String _slotLabel(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _dayLabel(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    return '$dd/$mm';
  }

  bool _sameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<DateTime> _availableSlotsForDay(DateTime day) {
    final now = DateTime.now();
    final dayStart = DateTime(day.year, day.month, day.day, 8, 0);
    final dayEnd = DateTime(day.year, day.month, day.day, 20, 0);
    final slots = <DateTime>[];
    for (var d = dayStart; !d.isAfter(dayEnd); d = d.add(const Duration(minutes: 30))) {
      if (_sameDay(d, now) && d.isBefore(now.add(const Duration(minutes: 30)))) continue;
      slots.add(d);
    }
    return slots;
  }

  bool _isSlotBusy(DateTime slotStart) {
    final slotEnd = slotStart.add(Duration(minutes: _durationMinutes));
    for (final range in _busyRanges) {
      final overlap = slotStart.isBefore(range.end) && slotEnd.isAfter(range.start);
      if (overlap) return true;
    }
    return false;
  }

  DateTime? _tryParseOdooDateTime(String raw) {
    if (raw.isEmpty) return null;
    final normalized = raw.replaceFirst(' ', 'T');
    return DateTime.tryParse(normalized);
  }

  DateTime _roundNextHalfHour(DateTime now) {
    final m = now.minute;
    final rounded = m < 30 ? 30 : 60;
    final base = DateTime(now.year, now.month, now.day, now.hour, 0);
    return base.add(Duration(minutes: rounded));
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AppTheme.danger : AppTheme.surfaceElevated,
      ),
    );
  }
}
