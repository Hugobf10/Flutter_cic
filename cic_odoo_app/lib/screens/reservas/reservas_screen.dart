import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/ui/app_components.dart';
import '../../features/purchases/barcode_scanner_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/app_logger.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/section_header.dart';
import '../../widgets/shimmer_loading.dart';
import 'reservation_entry_target.dart';

class ReservasScreen extends StatefulWidget {
  const ReservasScreen({super.key, this.initialTarget});

  final ReservationEntryTarget? initialTarget;

  @override
  State<ReservasScreen> createState() => _ReservasScreenState();
}

class _ReservationApiCheckResult {
  const _ReservationApiCheckResult({
    required this.label,
    required this.status,
    required this.message,
  });

  final String label;
  final _ReservationApiCheckStatus status;
  final String message;
}

enum _ReservationApiCheckStatus { ok, limited, error }

class _ReservasScreenState extends State<ReservasScreen>
    with SingleTickerProviderStateMixin {
  final OdooService _odoo = OdooService();
  final PortalApiService _portalApi = PortalApiService();
  final TextEditingController _motivoCtrl = TextEditingController();
  final AttachmentService _attachmentService = AttachmentService();
  late final TabController _tabController;

  bool _isLoading = true;
  bool _isCreating = false;
  bool _isLoadingAvailability = false;
  bool _isExportingQr = false;
  bool _isRunningApiChecks = false;
  bool _limitedAccessMode = false;
  String? _error;
  String? _agendaError;
  String? _reservasError;
  List<_ReservationApiCheckResult> _apiCheckResults = const [];

  List<Map<String, dynamic>> _services = [];
  List<Map<String, dynamic>> _variants = [];
  List<Map<String, dynamic>> _sessionTypes = [];
  List<Map<String, dynamic>> _reservas = [];
  List<Map<String, dynamic>> _agendaReservas = [];

  int? _serviceTemplateId;
  int? _variantId;
  int? _sessionTypeId;
  DateTime? _start;
  DateTime? _end;
  int _durationMinutes = 60;
  int _wizardStep = 0;
  DateTime _selectedDay = DateTime.now();
  DateTime _agendaDay = DateTime.now();
  List<DateTimeRange> _busyRanges = [];
  ReservationEntryTarget? _activeTarget;
  int? _agendaVariantFilterId;
  int? _editingReservationId;

  @override
  void initState() {
    super.initState();
    _activeTarget = widget.initialTarget;
    final targetDay = _currentReservationDay();
    _selectedDay = targetDay;
    _agendaDay = targetDay;
    _tabController = TabController(
      length: 3,
      vsync: this,
      initialIndex: _activeTarget?.initialTabIndex ?? 0,
    );
    _start = _roundNextHalfHour(DateTime.now());
    _end = _start!.add(Duration(minutes: _durationMinutes));
    _loadInitial();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _motivoCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _agendaError = null;
      _reservasError = null;
      _limitedAccessMode = false;
    });
    await _loadMisReservas();
    try {
      await _hydrateTargetContext();
      final services = _odoo.isPortalSession
          ? await _portalApi.section('reservation_services', limit: 200)
          : await _odoo.searchRead(
              'product.template',
              domain: [
                ['reservable_cic', '=', true],
                ['detailed_type', '=', 'service'],
              ],
              fields: ['name'],
              order: 'name',
              limit: 200,
            );
      _services = services
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      if (_services.isNotEmpty) {
        final desiredTemplateId =
            _activeTarget?.serviceTemplateId ??
            OdooValues.intValue(_services.first['id']);
        _serviceTemplateId =
            desiredTemplateId != null &&
                _services.any(
                  (s) => OdooValues.intValue(s['id']) == desiredTemplateId,
                )
            ? desiredTemplateId
            : OdooValues.intValue(_services.first['id']);
        await _loadServiceOptions(preferredVariantId: _activeTarget?.variantId);
      }
      await _loadAgendaReservas(day: _agendaDay);
    } catch (e) {
      if (OdooService.isAccessError(e)) {
        _limitedAccessMode = true;
        _error =
            'Este perfil no puede cargar el asistente completo de reservas por API. La app mostrará el modo de consulta con la información disponible.';
      } else {
        _error = OdooService.prettyError(e);
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (_activeTarget != null) {
        _tabController.animateTo(_targetTabIndex());
      }
    }
  }

  Future<void> _hydrateTargetContext() async {
    final target = _activeTarget;
    if (target == null ||
        target.variantId == null ||
        target.serviceTemplateId != null) {
      _agendaVariantFilterId = target?.variantId;
      return;
    }

    try {
      final rows = await _odoo.searchRead(
        'product.product',
        domain: [
          ['id', '=', target.variantId],
          ['active', '=', true],
        ],
        fields: ['display_name', 'product_tmpl_id'],
        limit: 1,
      );
      if (rows.isEmpty) return;
      final variant = Map<String, dynamic>.from(rows.first as Map);
      final templateId = OdooValues.many2oneId(variant['product_tmpl_id']);
      _activeTarget = target.copyWith(
        serviceTemplateId: templateId,
        resourceLabel:
            target.resourceLabel ?? variant['display_name']?.toString().trim(),
      );
      _agendaVariantFilterId = target.variantId;
    } catch (_) {
      _agendaVariantFilterId = target.variantId;
    }
  }

  Future<void> _loadServiceOptions({int? preferredVariantId}) async {
    if (_serviceTemplateId == null) return;

    final variants = _odoo.isPortalSession
        ? await _portalApi.section(
            'reservation_variants',
            params: {'service_template_id': _serviceTemplateId},
            limit: 200,
          )
        : await _odoo.searchRead(
            'product.product',
            domain: [
              ['product_tmpl_id', '=', _serviceTemplateId],
              ['active', '=', true],
            ],
            fields: ['display_name', 'lst_price'],
            order: 'display_name',
            limit: 200,
          );

    final sessionTypes = _odoo.isPortalSession
        ? await _portalApi.section(
            'reservation_session_types',
            params: {'service_template_id': _serviceTemplateId},
            limit: 100,
          )
        : await _odoo.searchRead(
            'reserva.session.type',
            domain: [
              ['servicio_template_id', '=', _serviceTemplateId],
              ['active', '=', true],
            ],
            fields: ['name', 'sequence'],
            order: 'sequence, name',
            limit: 100,
          );

    _variants = variants
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    _sessionTypes = sessionTypes
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    final hasPreferredVariant =
        preferredVariantId != null &&
        _variants.any((v) => v['id'] == preferredVariantId);
    _variantId = hasPreferredVariant
        ? preferredVariantId
        : (_variants.isNotEmpty
              ? OdooValues.intValue(_variants.first['id'])
              : null);
    _sessionTypeId = _sessionTypes.isNotEmpty
        ? OdooValues.intValue(_sessionTypes.first['id'])
        : null;
    _agendaVariantFilterId ??= hasPreferredVariant ? preferredVariantId : null;
    await _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    if (_variantId == null) return;
    final startDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
      0,
      0,
    );
    final endDay = startDay.add(const Duration(days: 1));
    setState(() => _isLoadingAvailability = true);
    try {
      final rows = _odoo.isPortalSession
          ? await _portalApi.section(
              'reservation_agenda',
              limit: 400,
              params: {
                'date': _formatOdooDate(startDay),
                'service_id': _variantId,
              },
            )
          : await _odoo.searchRead(
              'reserva.reserva',
              domain: [
                ['servicio_id', '=', _variantId],
                [
                  'estado',
                  'in',
                  ['borrador', 'confirmada', 'facturada'],
                ],
                ['fecha_inicio', '<', _formatOdooDateTime(endDay)],
                ['fecha_fin', '>', _formatOdooDateTime(startDay)],
              ],
              fields: ['fecha_inicio', 'fecha_fin'],
              order: 'fecha_inicio asc',
              limit: 400,
            );

      _busyRanges = rows
          .where(
            (row) =>
                _editingReservationId == null ||
                OdooValues.intValue((row as Map)['id']) !=
                    _editingReservationId,
          )
          .map((e) {
            final m = Map<String, dynamic>.from(e as Map);
            final start = _tryParseOdooDateTime(
              m['fecha_inicio']?.toString() ?? '',
            );
            final end = _tryParseOdooDateTime(m['fecha_fin']?.toString() ?? '');
            if (start == null || end == null) {
              return DateTimeRange(start: startDay, end: startDay);
            }
            return DateTimeRange(start: start, end: end);
          })
          .where((r) => r.end.isAfter(r.start))
          .toList();

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

    try {
      final result = _odoo.isPortalSession
          ? await _portalApi.section('reservas', limit: 200)
          : await _odoo.searchRead(
              'reserva.reserva',
              domain: [
                ['contacto_id', '=', partnerId],
              ],
              fields: [
                'name',
                'servicio_id',
                'servicio_template_id',
                'session_type_id',
                'fecha_inicio',
                'fecha_fin',
                'duracion',
                'importe_total',
                'estado',
                'motivo',
                'sale_order_id',
                'contacto_id',
              ],
              order: 'fecha_inicio desc',
              limit: 200,
            );

      _reservas = result
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
    } catch (e) {
      _reservas = [];
      _reservasError = OdooService.isAccessError(e)
          ? 'Tus reservas no están disponibles para este perfil por permisos API.'
          : OdooService.prettyError(e);
    }
  }

  Future<void> _loadAgendaReservas({DateTime? day}) async {
    final selected = day ?? _agendaDay;
    final startDay = DateTime(selected.year, selected.month, selected.day);
    final endDay = startDay.add(const Duration(days: 1));
    try {
      final domain = <dynamic>[
        ['fecha_inicio', '<', _formatOdooDateTime(endDay)],
        ['fecha_fin', '>=', _formatOdooDateTime(startDay)],
        [
          'estado',
          'in',
          ['borrador', 'confirmada', 'facturada'],
        ],
      ];
      if (_agendaVariantFilterId != null) {
        domain.add(['servicio_id', '=', _agendaVariantFilterId]);
      }
      final result = _odoo.isPortalSession
          ? await _portalApi.section(
              'reservation_agenda',
              limit: 400,
              params: {
                'date': _formatOdooDate(startDay),
                if (_agendaVariantFilterId != null)
                  'service_id': _agendaVariantFilterId,
              },
            )
          : await _odoo.searchRead(
              'reserva.reserva',
              domain: domain,
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
                'contacto_id',
              ],
              order: 'fecha_inicio asc',
              limit: 400,
            );
      _agendaReservas = result
          .map((e) => Map<String, dynamic>.from(e as Map))
          .toList();
      _agendaError = null;
    } catch (e) {
      _agendaReservas = _reservas
          .where((r) {
            final start = _tryParseOdooDateTime(
              r['fecha_inicio']?.toString() ?? '',
            );
            if (start == null) return false;
            return start.year == startDay.year &&
                start.month == startDay.month &&
                start.day == startDay.day;
          })
          .map((e) => Map<String, dynamic>.from(e))
          .toList();
      _agendaError = OdooService.isAccessError(e)
          ? 'Mostrando solo tus reservas del día por permisos.'
          : OdooService.prettyError(e);
    }
  }

  Future<void> _changeAgendaDay(int delta) async {
    setState(() {
      _agendaDay = DateTime(
        _agendaDay.year,
        _agendaDay.month,
        _agendaDay.day + delta,
      );
      _agendaError = null;
    });
    await _loadAgendaReservas(day: _agendaDay);
    if (mounted) setState(() {});
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
      _showSnack(
        'Selecciona una franja horaria para continuar.',
        isError: true,
      );
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
      final values = {
        'servicio_id': _variantId,
        'contacto_id': partnerId,
        'fecha_inicio': _formatOdooDateTime(_start!),
        'fecha_fin': _formatOdooDateTime(_end!),
        'motivo': _motivoCtrl.text.trim(),
        if (_sessionTypeId != null) 'session_type_id': _sessionTypeId,
      };
      if (_odoo.isPortalSession) {
        if (_editingReservationId == null) {
          await _portalApi.action('reservation_create', values: values);
        } else {
          await _portalApi.action(
            'reservation_update',
            recordId: _editingReservationId,
            values: values,
          );
        }
      } else {
        if (_editingReservationId != null) {
          await _odoo.write('reserva.reserva', _editingReservationId!, values);
        } else {
          try {
            await _odoo.callMethod(
              'reserva.reserva',
              'cic_mobile_create_reservation',
              args: [values],
            );
          } catch (e) {
            if (!OdooService.isMethodUnavailable(e)) rethrow;
            await _odoo.create('reserva.reserva', values);
          }
        }
      }

      final wasEditing = _editingReservationId != null;
      _motivoCtrl.clear();
      _editingReservationId = null;
      await _loadMisReservas();
      await _loadAgendaReservas(day: _agendaDay);
      _showSnack(
        wasEditing
            ? 'Reserva actualizada. Confírmala cuando esté lista.'
            : 'Reserva creada en borrador. Revísala y confírmala cuando esté lista.',
      );
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack(
        'No se pudo crear: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }

    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _confirmarReserva(int id) async {
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action('reservation_confirm', recordId: id);
      } else {
        try {
          await _odoo.callRecordMethod('reserva.reserva', [
            id,
          ], 'cic_mobile_confirm_reservation');
        } catch (e) {
          if (!OdooService.isMethodUnavailable(e)) rethrow;
          await _odoo.callRecordMethod('reserva.reserva', [
            id,
          ], 'action_confirmar');
        }
      }
      await _loadMisReservas();
      await _loadAgendaReservas(day: _agendaDay);
      if (mounted) setState(() {});
      _showSnack('Reserva confirmada.');
    } catch (e) {
      _showSnack(
        'No se pudo confirmar: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }
  }

  Future<void> _cancelarReserva(int id) async {
    try {
      if (_odoo.isPortalSession) {
        await _portalApi.action('reservation_cancel', recordId: id);
      } else {
        await _odoo.callRecordMethod('reserva.reserva', [
          id,
        ], 'action_cancelar');
      }
      await _loadMisReservas();
      await _loadAgendaReservas(day: _agendaDay);
      if (mounted) setState(() {});
      _showSnack('Reserva cancelada.');
    } catch (e) {
      _showSnack(
        'No se pudo cancelar: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }
  }

  Future<void> _editarReserva(Map<String, dynamic> reservation) async {
    final id = OdooValues.intValue(reservation['id']);
    final templateId = OdooValues.many2oneId(
      reservation['servicio_template_id'],
    );
    final variantId = OdooValues.many2oneId(reservation['servicio_id']);
    final sessionTypeId = OdooValues.many2oneId(reservation['session_type_id']);
    final start = _tryParseOdooDateTime(
      reservation['fecha_inicio']?.toString() ?? '',
    );
    final end = _tryParseOdooDateTime(
      reservation['fecha_fin']?.toString() ?? '',
    );
    if (id == null ||
        templateId == null ||
        variantId == null ||
        start == null ||
        end == null) {
      _showSnack(
        'No se pudo preparar esta reserva para editar.',
        isError: true,
      );
      return;
    }

    setState(() {
      _editingReservationId = id;
      _serviceTemplateId = templateId;
      _variantId = variantId;
      _sessionTypeId = sessionTypeId;
      _start = start;
      _end = end;
      _selectedDay = DateTime(start.year, start.month, start.day);
      _durationMinutes = end.difference(start).inMinutes;
      _motivoCtrl.text = OdooValues.string(reservation['motivo']);
      _wizardStep = 0;
    });
    await _loadServiceOptions(preferredVariantId: variantId);
    if (!mounted) return;
    if (sessionTypeId != null &&
        _sessionTypes.any(
          (item) => OdooValues.intValue(item['id']) == sessionTypeId,
        )) {
      setState(() => _sessionTypeId = sessionTypeId);
    }
    _tabController.animateTo(0);
    setState(() {});
  }

  Future<void> _scanReservationQr() async {
    final raw = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const BarcodeScannerScreen()),
    );
    if (!mounted || raw == null) return;

    final target = ReservationEntryTarget.parse(raw);
    if (target == null) {
      _showSnack('El QR no corresponde a una reserva válida.', isError: true);
      return;
    }

    await _applyReservationTarget(target);
  }

  Future<void> _applyReservationTarget(ReservationEntryTarget target) async {
    final currentDay = _currentReservationDay();
    setState(() {
      _activeTarget = target;
      _agendaVariantFilterId = target.variantId;
      _selectedDay = currentDay;
      _agendaDay = currentDay;
      _error = null;
      _agendaError = null;
      _reservasError = null;
    });

    await _hydrateTargetContext();
    final templateId = _activeTarget?.serviceTemplateId;
    if (templateId != null) {
      _serviceTemplateId = templateId;
      await _loadServiceOptions(preferredVariantId: _activeTarget?.variantId);
    } else if (target.variantId != null) {
      _variantId = target.variantId;
      await _loadAvailability();
    }
    await _loadAgendaReservas(day: _agendaDay);

    if (!mounted) return;
    _tabController.animateTo(_targetTabIndex());
    setState(() {});
    _showSnack(
      _activeTarget?.resourceLabel?.trim().isNotEmpty == true
          ? 'Disponibilidad cargada para ${_activeTarget!.resourceLabel}.'
          : 'Disponibilidad cargada para el recurso escaneado.',
    );
  }

  Future<void> _clearReservationTarget() async {
    final currentDay = _currentReservationDay();
    setState(() {
      _activeTarget = null;
      _agendaVariantFilterId = null;
      _selectedDay = currentDay;
      _agendaDay = currentDay;
      _wizardStep = 0;
    });
    await _loadInitial();
    if (!mounted) return;
    _tabController.animateTo(0);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.surfaceFor(context),
        body: const Padding(padding: EdgeInsets.all(16), child: ShimmerList()),
      );
    }

    if (_error != null) {
      if (_limitedAccessMode) {
        return _buildLimitedAccessReservationMode(auth);
      }
      return Scaffold(
        backgroundColor: AppTheme.surfaceFor(context),
        appBar: AppBar(title: const Text('Reservas')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Text(
              _error!,
              style: TextStyle(color: AppTheme.textMutedFor(context)),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.surfaceFor(context),
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          if (auth.isInternalUser || auth.isAdmin)
            IconButton(
              onPressed: _scanReservationQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Escanear QR de sala o equipo',
            ),
          IconButton(
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(
              text: 'Nueva reserva',
              icon: Icon(Icons.add_circle_outline_rounded),
            ),
            Tab(text: 'Mis reservas', icon: Icon(Icons.list_alt_rounded)),
            Tab(
              text: 'Agenda diaria',
              icon: Icon(Icons.calendar_view_day_rounded),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
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
                if (_activeTarget != null) _buildResourceContextBanner(),
                if (auth.isInternalUser || auth.isAdmin) ...[
                  _buildAdminQrCard(),
                  const SizedBox(height: 12),
                  _buildApiDiagnosticsCard(),
                  const SizedBox(height: 12),
                ],
                if (auth.canEditModule('reservas'))
                  _buildNewReservationCard()
                else
                  const AppEmptyState(
                    title: 'Reserva no disponible',
                    subtitle:
                        'Este usuario puede consultar reservas, pero no crear nuevas desde la app.',
                    icon: Icons.lock_outline_rounded,
                  ),
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
                if (_reservasError != null)
                  _buildReservasNotice(_reservasError!),
                if (_reservas.isEmpty)
                  const AppEmptyState(
                    title: 'Sin reservas',
                    subtitle: 'No tienes reservas registradas.',
                    icon: Icons.event_busy_outlined,
                  )
                else
                  ..._reservas.map((r) => _buildReservaCard(r, auth: auth)),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadInitial,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                SectionHeader(
                  title: 'Agenda del día',
                  subtitle:
                      '${_agendaReservas.length} reservas visibles el ${_formatAgendaDay(_agendaDay)}',
                  icon: Icons.calendar_view_day_rounded,
                ),
                if (_activeTarget != null) _buildResourceContextBanner(),
                _buildAgendaDaySelector(),
                const SizedBox(height: 12),
                if (_agendaError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _agendaError!,
                      style: TextStyle(
                        color: AppTheme.textMutedFor(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_agendaReservas.isEmpty)
                  const AppEmptyState(
                    title: 'Sin reservas este día',
                    subtitle:
                        'No hay reservas disponibles para consultar en la fecha seleccionada.',
                    icon: Icons.calendar_today_outlined,
                  )
                else
                  _buildAgendaTimeline(auth),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitedAccessReservationMode(AuthProvider auth) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceFor(context),
      appBar: AppBar(
        title: const Text('Reservas'),
        actions: [
          if (auth.isInternalUser || auth.isAdmin)
            IconButton(
              onPressed: _scanReservationQr,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              tooltip: 'Escanear QR de sala o equipo',
            ),
          IconButton(
            onPressed: _loadInitial,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Mis reservas', icon: Icon(Icons.list_alt_rounded)),
            Tab(
              text: 'Agenda diaria',
              icon: Icon(Icons.calendar_view_day_rounded),
            ),
            Tab(text: 'Acceso', icon: Icon(Icons.lock_outline_rounded)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
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
                if (_reservasError != null)
                  _buildReservasNotice(_reservasError!),
                if (_reservas.isEmpty)
                  const AppEmptyState(
                    title: 'Sin reservas',
                    subtitle: 'No tienes reservas registradas.',
                    icon: Icons.event_busy_outlined,
                  )
                else
                  ..._reservas.map((r) => _buildReservaCard(r, auth: auth)),
              ],
            ),
          ),
          RefreshIndicator(
            onRefresh: _loadInitial,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              children: [
                SectionHeader(
                  title: 'Agenda del día',
                  subtitle:
                      '${_agendaReservas.length} reservas visibles el ${_formatAgendaDay(_agendaDay)}',
                  icon: Icons.calendar_view_day_rounded,
                ),
                if (_activeTarget != null) _buildResourceContextBanner(),
                _buildAgendaDaySelector(),
                const SizedBox(height: 12),
                if (_agendaError != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _agendaError!,
                      style: TextStyle(
                        color: AppTheme.textMutedFor(context),
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (_agendaReservas.isEmpty)
                  const AppEmptyState(
                    title: 'Sin reservas este día',
                    subtitle:
                        'No hay reservas visibles en la fecha seleccionada.',
                    icon: Icons.calendar_today_outlined,
                  )
                else
                  _buildAgendaTimeline(auth),
              ],
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 560),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.cardFor(context),
                  borderRadius: AppTheme.radiusMd,
                  border: Border.all(color: AppTheme.dividerFor(context)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: AppTheme.primary,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Reservas con acceso limitado',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Este perfil está en modo de consulta dentro de la app. Puede revisar sus reservas y la agenda diaria, pero no crear ni editar nuevas reservas con sus permisos actuales.',
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.elevatedFor(context),
                        borderRadius: AppTheme.radiusSm,
                        border: Border.all(color: AppTheme.dividerFor(context)),
                      ),
                      child: Text(
                        'Si este usuario debe poder reservar desde la app, hay que habilitar permisos API para su perfil en el flujo de reservas.',
                        style: TextStyle(
                          color: AppTheme.textMutedFor(context),
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildApiDiagnosticsCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourceContextBanner() {
    final label = _activeTarget?.resourceLabel ?? _selectedVariantName();
    final dayLabel = _activeTarget?.day != null
        ? _formatAgendaDay(_activeTarget!.day!)
        : _formatAgendaDay(_agendaDay);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    label?.trim().isNotEmpty == true
                        ? 'Recurso seleccionado: $label'
                        : 'Recurso seleccionado por QR',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: _clearReservationTarget,
                  child: const Text('Limpiar'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Mostrando disponibilidad y agenda para $dayLabel.',
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdminQrCard() {
    final variant = _selectedVariantMap();
    final templateId = _serviceTemplateId;
    final variantId = _variantId;
    final variantName = _selectedVariantName();
    final payload = _buildReservationQrPayload();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.qr_code_2_rounded, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'QR de recurso',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            variantId == null
                ? 'Selecciona un microservicio o recurso para generar su QR.'
                : 'Este QR abrirá la app directamente en el recurso seleccionado y mostrará siempre la disponibilidad del día actual.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          if (variantId != null) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppTheme.divider),
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: payload,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: AppTheme.textPrimary,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      variantName ?? 'Recurso',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Servicio ${templateId ?? '-'} · Recurso $variantId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExportingQr ? null : _exportCurrentQrPng,
                    icon: _isExportingQr
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_rounded),
                    label: Text(
                      _isExportingQr ? 'Exportando...' : 'Exportar PNG',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExportingQr ? null : _shareCurrentQrPng,
                    icon: const Icon(Icons.share_rounded),
                    label: const Text('Compartir'),
                  ),
                ),
              ],
            ),
          ],
          if (variant != null &&
              (variant['display_name'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            const Text(
              'Tip: genera el QR después de seleccionar el microservicio exacto en el paso 2.',
              style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildApiDiagnosticsCard() {
    final serviceLabel = _services
        .where((s) => s['id'] == _serviceTemplateId)
        .map((s) => (s['name'] ?? '').toString())
        .cast<String?>()
        .firstWhere(
          (value) => value != null && value.trim().isNotEmpty,
          orElse: () => null,
        );
    final variantLabel = _activeTarget?.resourceLabel ?? _selectedVariantName();

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.health_and_safety_outlined, color: AppTheme.primary),
              SizedBox(width: 8),
              Text(
                'Diagnóstico API',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Comprueba desde la propia app qué partes del flujo de reservas permite este perfil por API.',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.surfaceElevated,
              borderRadius: AppTheme.radiusSm,
              border: Border.all(color: AppTheme.divider),
            ),
            child: Text(
              'Día actual: ${_formatAgendaDay(_currentReservationDay())}\n'
              'Servicio: ${serviceLabel ?? '-'}\n'
              'Recurso: ${variantLabel ?? '-'}',
              style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isRunningApiChecks
                      ? null
                      : _runReservationApiDiagnostics,
                  icon: _isRunningApiChecks
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.playlist_add_check_circle_rounded),
                  label: Text(
                    _isRunningApiChecks
                        ? 'Comprobando...'
                        : 'Comprobar permisos API',
                  ),
                ),
              ),
            ],
          ),
          if (_apiCheckResults.isNotEmpty) ...[
            const SizedBox(height: 12),
            ..._apiCheckResults.map(_buildApiCheckRow),
          ],
        ],
      ),
    );
  }

  Widget _buildApiCheckRow(_ReservationApiCheckResult result) {
    final (icon, color) = switch (result.status) {
      _ReservationApiCheckStatus.ok => (
        Icons.check_circle_rounded,
        AppTheme.success,
      ),
      _ReservationApiCheckStatus.limited => (
        Icons.lock_outline_rounded,
        AppTheme.warning,
      ),
      _ReservationApiCheckStatus.error => (
        Icons.error_outline_rounded,
        AppTheme.danger,
      ),
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.label,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.message,
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _runReservationApiDiagnostics() async {
    final auth = context.read<AuthProvider>();
    final today = _currentReservationDay();
    final startDay = today;
    final endDay = startDay.add(const Duration(days: 1));

    setState(() {
      _isRunningApiChecks = true;
      _apiCheckResults = const [];
    });

    final checks = <_ReservationApiCheckResult>[
      await _runApiCheck('Servicios reservables', () async {
        final rows = await _odoo.searchRead(
          'product.template',
          domain: [
            ['reservable_cic', '=', true],
            ['detailed_type', '=', 'service'],
          ],
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty
            ? 'Sin servicios visibles para este usuario.'
            : 'Lectura OK del catálogo de servicios.';
      }),
      await _runApiCheck('Recursos del servicio', () async {
        final domain = <dynamic>[
          ['active', '=', true],
        ];
        if (_serviceTemplateId != null) {
          domain.add(['product_tmpl_id', '=', _serviceTemplateId]);
        }
        final rows = await _odoo.searchRead(
          'product.product',
          domain: domain,
          fields: ['display_name'],
          limit: 1,
        );
        return rows.isEmpty
            ? 'Sin recursos visibles para el servicio seleccionado.'
            : 'Lectura OK de recursos/microservicios.';
      }),
      await _runApiCheck('Tipos de sesión', () async {
        final domain = <dynamic>[
          ['active', '=', true],
        ];
        if (_serviceTemplateId != null) {
          domain.add(['servicio_template_id', '=', _serviceTemplateId]);
        }
        final rows = await _odoo.searchRead(
          'reserva.session.type',
          domain: domain,
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty
            ? 'No hay tipos de sesión visibles o no aplican a este servicio.'
            : 'Lectura OK de tipos de sesión.';
      }),
      await _runApiCheck('Mis reservas', () async {
        final rows = await _odoo.searchRead(
          'reserva.reserva',
          domain: [
            ['contacto_id', '=', auth.partnerId],
          ],
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty
            ? 'Consulta OK, pero este usuario no tiene reservas propias visibles.'
            : 'Lectura OK de reservas propias.';
      }),
      await _runApiCheck('Agenda diaria', () async {
        final domain = <dynamic>[
          ['fecha_inicio', '<', _formatOdooDateTime(endDay)],
          ['fecha_fin', '>=', _formatOdooDateTime(startDay)],
          [
            'estado',
            'in',
            ['borrador', 'confirmada', 'facturada'],
          ],
        ];
        if (_agendaVariantFilterId != null) {
          domain.add(['servicio_id', '=', _agendaVariantFilterId]);
        }
        final rows = await _odoo.searchRead(
          'reserva.reserva',
          domain: domain,
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty
            ? 'Consulta OK para la agenda del día, sin reservas visibles hoy.'
            : 'Lectura OK de agenda diaria.';
      }),
      await _runApiCheck('Permiso de creación', () async {
        final allowed = await _odoo.callMethod(
          'reserva.reserva',
          'check_access_rights',
          args: ['create'],
          kwargs: const {'raise_exception': false},
        );
        if (allowed == true) {
          return 'El modelo permite crear reservas por API.';
        }
        throw Exception('Sin permiso de creación en reserva.reserva.');
      }),
      await _runApiCheck('Permiso de edición', () async {
        final allowed = await _odoo.callMethod(
          'reserva.reserva',
          'check_access_rights',
          args: ['write'],
          kwargs: const {'raise_exception': false},
        );
        if (allowed == true) {
          return 'El modelo permite editar reservas por API.';
        }
        throw Exception('Sin permiso de edición en reserva.reserva.');
      }),
    ];

    if (!mounted) return;
    setState(() {
      _isRunningApiChecks = false;
      _apiCheckResults = checks;
    });
  }

  Future<_ReservationApiCheckResult> _runApiCheck(
    String label,
    Future<String> Function() action,
  ) async {
    try {
      final message = await action();
      return _ReservationApiCheckResult(
        label: label,
        status: _ReservationApiCheckStatus.ok,
        message: message,
      );
    } catch (e) {
      final limited =
          OdooService.isAccessError(e) ||
          e.toString().toLowerCase().contains('sin permiso');
      return _ReservationApiCheckResult(
        label: label,
        status: limited
            ? _ReservationApiCheckStatus.limited
            : _ReservationApiCheckStatus.error,
        message: limited
            ? 'Acceso limitado: ${OdooService.prettyError(e)}'
            : OdooService.prettyError(e),
      );
    }
  }

  Widget _buildAgendaDaySelector() {
    return AppCard(
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: () => _changeAgendaDay(-1),
                icon: const Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'Día consultado',
                      style: TextStyle(
                        color: AppTheme.textSecondaryFor(context),
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatAgendaDay(_agendaDay),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryFor(context),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _changeAgendaDay(1),
                icon: const Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          if (_variants.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: _agendaVariantFilterId,
              decoration: const InputDecoration(
                labelText: 'Agenda visible',
                prefixIcon: Icon(Icons.meeting_room_outlined),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Todos los recursos'),
                ),
                ..._variants.map((variant) {
                  final id = (variant['id'] as num?)?.toInt();
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      (variant['display_name'] ?? variant['name'] ?? 'Recurso')
                          .toString(),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
              onChanged: (value) async {
                setState(() {
                  _agendaVariantFilterId = value;
                  _activeTarget = null;
                });
                await _loadAgendaReservas(day: _agendaDay);
                if (mounted) setState(() {});
              },
            ),
          ],
          const SizedBox(height: 8),
          Text(
            (context.watch<AuthProvider>().isInternalUser ||
                    context.watch<AuthProvider>().isAdmin)
                ? 'Los QR se generan al seleccionar un microservicio o recurso en la pestaña Nueva.'
                : 'La agenda muestra la ocupación de los recursos sin revelar datos de otros usuarios.',
            style: TextStyle(
              color: AppTheme.textMutedFor(context),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgendaTimeline(AuthProvider auth) {
    final sorted = List<Map<String, dynamic>>.from(_agendaReservas)
      ..sort((a, b) {
        final aDate = _tryParseOdooDateTime(
          a['fecha_inicio']?.toString() ?? '',
        );
        final bDate = _tryParseOdooDateTime(
          b['fecha_inicio']?.toString() ?? '',
        );
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      });

    return Column(
      children: sorted.map((r) {
        final start = _tryParseOdooDateTime(
          r['fecha_inicio']?.toString() ?? '',
        );
        final end = _tryParseOdooDateTime(r['fecha_fin']?.toString() ?? '');
        final servicio = OdooValues.many2oneLabel(
          r['servicio_id'],
          fallback: 'Servicio',
        );
        final contacto = auth.isPortalUser
            ? 'Reserva ocupada'
            : OdooValues.many2oneLabel(
                r['contacto_id'],
                fallback: 'Sin contacto',
              );
        final estado = OdooValues.string(r['estado']);
        final color = _estadoColor(estado);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 78,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: AppTheme.radiusSm,
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatHour(start),
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatHour(end),
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              servicio,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ),
                          AppStatusChip(
                            label: _formatEstado(estado),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contacto,
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      if (OdooValues.many2oneId(r['session_type_id']) !=
                          null) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Tipo: ${OdooValues.many2oneLabel(r['session_type_id'], fallback: 'Sesión')}',
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (!auth.isPortalUser &&
                          (r['motivo'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          (r['motivo'] ?? '').toString(),
                          style: const TextStyle(
                            color: AppTheme.textMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatAgendaDay(DateTime value) {
    final dd = value.day.toString().padLeft(2, '0');
    final mm = value.month.toString().padLeft(2, '0');
    return '$dd/$mm/${value.year}';
  }

  String _formatHour(DateTime? value) {
    if (value == null) return '--:--';
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'confirmada':
        return AppTheme.success;
      case 'facturada':
        return AppTheme.primary;
      case 'cancelada':
        return AppTheme.danger;
      case 'borrador':
      default:
        return AppTheme.warning;
    }
  }

  String _formatEstado(String estado) {
    switch (estado) {
      case 'confirmada':
        return 'Confirmada';
      case 'facturada':
        return 'Facturada';
      case 'cancelada':
        return 'Cancelada';
      case 'borrador':
        return 'Borrador';
      default:
        return estado.isEmpty ? 'Reserva' : estado;
    }
  }

  DateTime _currentReservationDay() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  int _targetTabIndex() {
    if (_limitedAccessMode) {
      return 1;
    }
    return _activeTarget?.initialTabIndex ?? 0;
  }

  Widget _buildReservasNotice(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          borderRadius: AppTheme.radiusSm,
          border: Border.all(color: AppTheme.divider),
        ),
        child: Text(
          message,
          style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
        ),
      ),
    );
  }

  String? _selectedVariantName() {
    for (final variant in _variants) {
      if (OdooValues.intValue(variant['id']) == _variantId) {
        final name = OdooValues.string(variant['display_name']);
        return name.isEmpty ? null : name;
      }
    }
    return null;
  }

  Map<String, dynamic>? _selectedVariantMap() {
    for (final variant in _variants) {
      if (OdooValues.intValue(variant['id']) == _variantId) {
        return variant;
      }
    }
    return null;
  }

  String _buildReservationQrPayload() {
    final variantId = _variantId;
    final templateId = _serviceTemplateId;
    final label = Uri.encodeComponent(_selectedVariantName() ?? 'Recurso');
    final buffer = StringBuffer('com.cic.flutter://reservas?tab=agenda');
    if (variantId != null) {
      buffer.write('&variantId=$variantId');
    }
    if (templateId != null) {
      buffer.write('&serviceTemplateId=$templateId');
    }
    buffer.write('&label=$label');
    return buffer.toString();
  }

  Future<void> _exportCurrentQrPng() async {
    if (_variantId == null) {
      _showSnack(
        'Selecciona antes un microservicio para generar el QR.',
        isError: true,
      );
      return;
    }

    setState(() => _isExportingQr = true);
    try {
      final bytes = await _generateQrPngBytes(_buildReservationQrPayload());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('No se pudo renderizar el PNG del QR.');
      }

      final name =
          'qr_reserva_${AttachmentService.sanitizeFileName(_selectedVariantName() ?? 'recurso')}_${_variantId!}.png';
      final file = await _attachmentService.writeBytesToDocuments(
        name: name,
        bytes: bytes,
        folderName: 'reservas_qr',
      );
      await OpenFilex.open(file.path);
      _showSnack('QR exportado en PNG: ${file.path}');
    } catch (e) {
      _showSnack(
        'No se pudo exportar el QR: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }

    if (mounted) {
      setState(() => _isExportingQr = false);
    }
  }

  Future<void> _shareCurrentQrPng() async {
    if (_variantId == null) {
      _showSnack(
        'Selecciona antes un microservicio para generar el QR.',
        isError: true,
      );
      return;
    }
    setState(() => _isExportingQr = true);
    try {
      final box = context.findRenderObject();
      final shareOrigin = box is RenderBox
          ? box.localToGlobal(Offset.zero) & box.size
          : Rect.fromCenter(
              center: Offset(
                MediaQuery.sizeOf(context).width / 2,
                MediaQuery.sizeOf(context).height / 2,
              ),
              width: 1,
              height: 1,
            );
      final bytes = await _generateQrPngBytes(_buildReservationQrPayload());
      if (bytes == null || bytes.isEmpty) {
        throw Exception('No se pudo renderizar el PNG del QR.');
      }
      final safeName = AttachmentService.sanitizeFileName(
        _selectedVariantName() ?? 'recurso',
      );
      final fileName = 'qr_reserva_$safeName.png';
      final file = await _attachmentService.writeBytesToTemporary(
        name: fileName,
        bytes: bytes,
        folderName: 'reservas_qr',
      );
      if (!await file.exists()) {
        throw Exception('No se pudo guardar el fichero temporal del QR.');
      }
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject: 'QR de reserva ${_selectedVariantName() ?? 'recurso'}',
        fileNameOverrides: [fileName],
        sharePositionOrigin: shareOrigin,
      );
    } catch (e, stackTrace) {
      AppLogger.error(
        'Error compartiendo QR de reserva',
        error: e,
        stackTrace: stackTrace,
        data: {
          'variantId': _variantId,
          'serviceTemplateId': _serviceTemplateId,
          'platform': Platform.operatingSystem,
        },
        scope: 'reservas.qr',
      );
      _showSnack(
        'No se pudo compartir el QR: ${OdooService.prettyError(e)}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _isExportingQr = false);
    }
  }

  Future<Uint8List?> _generateQrPngBytes(String data) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: AppTheme.textPrimary,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: AppTheme.textPrimary,
      ),
    );
    final byteData = await painter.toImageData(
      1600,
      format: ui.ImageByteFormat.png,
    );
    return byteData?.buffer.asUint8List();
  }

  Widget _buildNewReservationCard() {
    final selectedServiceList = _services
        .where((s) => s['id'] == _serviceTemplateId)
        .toList();
    final selectedVariantList = _variants
        .where((v) => v['id'] == _variantId)
        .toList();
    final selectedService = selectedServiceList.isEmpty
        ? null
        : selectedServiceList.first;
    final selectedVariant = selectedVariantList.isEmpty
        ? null
        : selectedVariantList.first;
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
          if (_editingReservationId != null) ...[
            const Text(
              'Editando borrador',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
          ],
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_circle_outline_rounded))
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _wizardStep == 3
                        ? (_isCreating
                              ? (_editingReservationId == null
                                    ? 'Creando...'
                                    : 'Guardando...')
                              : (_editingReservationId == null
                                    ? 'Crear borrador'
                                    : 'Guardar cambios'))
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
                backgroundColor: done || active
                    ? AppTheme.primary
                    : AppTheme.surfaceElevated,
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
              const Text(
                'Paso 1: elige el servicio',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.category_outlined,
                'Elige el tipo de servicio. En el siguiente paso seleccionarás el recurso concreto que quieres reservar.',
              ),
              const SizedBox(height: 12),
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
              const Text(
                'Paso 2: elige recurso',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.meeting_room_outlined,
                'Selecciona el recurso exacto. Si aparece un tipo de sesión, debes elegir el que corresponda antes de continuar.',
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _variants.map((v) {
                  final id = v['id'] as int;
                  final selected = _variantId == id;
                  return ChoiceChip(
                    label: Text(
                      '${v['display_name']} (${_money(v['lst_price'])}/h)',
                    ),
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
                  decoration: const InputDecoration(
                    labelText: 'Tipo de sesión',
                  ),
                  items: _sessionTypes
                      .map(
                        (t) => DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text((t['name'] ?? '').toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => setState(() => _sessionTypeId = v),
                ),
              ],
            ],
          ),
        );
      case 2:
        final days = List.generate(
          7,
          (i) => DateTime.now().add(Duration(days: i)),
        );
        final slots = _availableSlotsForDay(_selectedDay);
        return SingleChildScrollView(
          key: const ValueKey('step_time'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Paso 3: elige horario',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.schedule_outlined,
                'Solo puedes elegir franjas libres. Las reservas se hacen en bloques de 30 minutos y no se permiten horarios pasados ni solapados.',
              ),
              const SizedBox(height: 12),
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
              const Text(
                'Horas disponibles',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
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
                  final selected =
                      _start != null && _start!.isAtSameMomentAs(slot);
                  final busy = _isSlotBusy(slot);
                  return ChoiceChip(
                    label: Text(_slotLabel(slot)),
                    selected: selected,
                    onSelected: busy
                        ? null
                        : (_) {
                            setState(() {
                              _start = slot;
                              _end = _start!.add(
                                Duration(minutes: _durationMinutes),
                              );
                            });
                          },
                  );
                }).toList(),
              ),
              const SizedBox(height: 10),
              const Text(
                'Duración',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimary,
                ),
              ),
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
              _buildWizardHint(
                Icons.fact_check_outlined,
                'Revisa los datos antes de guardar. La reserva quedará en borrador: podrás editarla o confirmarla desde «Mis reservas».',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _motivoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Motivo (opcional)',
                ),
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
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        );
    }
  }

  Widget _buildWizardHint(IconData icon, String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.08),
        borderRadius: AppTheme.radiusSm,
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservaCard(
    Map<String, dynamic> r, {
    required AuthProvider auth,
  }) {
    final id = (r['id'] as num).toInt();
    final estado = (r['estado'] ?? 'borrador').toString();
    final servicio = _nameFromMany2one(r['servicio_id']);
    final session = _nameFromMany2one(r['session_type_id']);
    final contacto = _nameFromMany2one(r['contacto_id']);
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
          Text(
            '$start  ->  $end',
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            'Duración: ${duracion.toStringAsFixed(1)}h  ·  Total: ${_money(total)}',
            style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
          ),
          if (session.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Tipo: $session',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          if (motivo.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Motivo: $motivo',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          if (contacto.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Solicitante: $contacto',
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 12),
              ),
            ),
          if (estado == 'borrador' && auth.canEditModule('reservas')) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => _editarReserva(r),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar'),
                ),
                TextButton.icon(
                  onPressed: () => _confirmarReserva(id),
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Confirmar'),
                ),
              ],
            ),
          ],
          if (estado == 'confirmada' && auth.canEditModule('reservas')) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => _cancelarReserva(id),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancelar'),
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
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: AppTheme.radiusXl,
      ),
      child: Text(
        estado,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
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

  String _formatOdooDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _money(dynamic value) {
    final n = value is num
        ? value.toDouble()
        : double.tryParse(value.toString()) ?? 0;
    return '${n.toStringAsFixed(2)} EUR';
  }

  String _durationLabel(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) {
      return '$m'
          'm';
    }
    if (m == 0) {
      return '$h'
          'h';
    }
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
    for (
      var d = dayStart;
      !d.isAfter(dayEnd);
      d = d.add(const Duration(minutes: 30))
    ) {
      if (_sameDay(d, now) &&
          d.isBefore(now.add(const Duration(minutes: 30)))) {
        continue;
      }
      slots.add(d);
    }
    return slots;
  }

  bool _isSlotBusy(DateTime slotStart) {
    final slotEnd = slotStart.add(Duration(minutes: _durationMinutes));
    for (final range in _busyRanges) {
      final overlap =
          slotStart.isBefore(range.end) && slotEnd.isAfter(range.start);
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
