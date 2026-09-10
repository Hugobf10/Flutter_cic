import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:open_filex/open_filex.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../app/ui/app_components.dart';
import '../../l10n/strings.dart';
import '../../features/purchases/barcode_scanner_screen.dart';
import '../../providers/auth_provider.dart';
import '../../services/attachment_service.dart';
import '../../services/app_logger.dart';
import '../../services/odoo_service.dart';
import '../../services/odoo_values.dart';
import '../../services/portal_api_service.dart';
import '../../theme/app_theme.dart';
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
    final limitedAccessMessage = context.uiText(
      'Este perfil no puede cargar el asistente completo de reservas por API. La app mostrará el modo de consulta con la información disponible.',
      'This profile cannot load the full reservation wizard through the API. The app will show consultation mode with the available information.',
    );
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
        _error = limitedAccessMessage;
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
    final permissionsMessage = context.uiText(
      'Tus reservas no están disponibles para este perfil por permisos API.',
      'Your reservations are not available for this profile due to API permissions.',
    );

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
          ? permissionsMessage
          : OdooService.prettyError(e);
    }
  }

  Future<void> _loadAgendaReservas({DateTime? day}) async {
    final selected = day ?? _agendaDay;
    final startDay = DateTime(selected.year, selected.month, selected.day);
    final endDay = startDay.add(const Duration(days: 1));
    final permissionsMessage = context.uiText(
      'Mostrando solo tus reservas del día por permisos.',
      'Showing only your reservations for the day due to permissions.',
    );
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
          ? permissionsMessage
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
      _showSnack(context.l10n.selectService, isError: true);
      return;
    }
    if (_wizardStep == 1 && _variantId == null) {
      _showSnack(context.l10n.selectResource, isError: true);
      return;
    }
    if (_wizardStep == 2 && _start == null) {
      _showSnack(context.l10n.selectTimeSlot, isError: true);
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
    final t = context.l10n;
    final couldNotCreatePrefix = context.uiText(
      'No se pudo crear',
      'Could not create',
    );
    if (_variantId == null || _start == null || _end == null) return;
    if (!_end!.isAfter(_start!)) {
      _showSnack(
        context.uiText(
          'La fecha fin debe ser mayor que inicio.',
          'The end date must be after the start date.',
        ),
        isError: true,
      );
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
      _showSnack(wasEditing ? t.reservationUpdated : t.draftCreated);
      if (mounted) setState(() {});
    } catch (e) {
      _showSnack(
        '$couldNotCreatePrefix: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }

    if (mounted) setState(() => _isCreating = false);
  }

  Future<void> _confirmarReserva(int id) async {
    final t = context.l10n;
    final couldNotConfirmPrefix = context.uiText(
      'No se pudo confirmar',
      'Could not confirm',
    );
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
      _showSnack(t.reservationConfirmed);
    } catch (e) {
      _showSnack(
        '$couldNotConfirmPrefix: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }
  }

  Future<void> _cancelarReserva(int id) async {
    final t = context.l10n;
    final couldNotCancelPrefix = context.uiText(
      'No se pudo cancelar',
      'Could not cancel',
    );
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
      _showSnack(t.reservationCancelled);
    } catch (e) {
      _showSnack(
        '$couldNotCancelPrefix: ${OdooService.prettyError(e)}',
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
        context.uiText(
          'No se pudo preparar esta reserva para editar.',
          'Could not prepare this reservation for editing.',
        ),
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
      _showSnack(
        context.uiText(
          'El QR no corresponde a una reserva válida.',
          'The QR code does not match a valid reservation.',
        ),
        isError: true,
      );
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
          ? '${context.uiText('Disponibilidad cargada para', 'Availability loaded for')} ${_activeTarget!.resourceLabel}.'
          : context.uiText(
              'Disponibilidad cargada para el recurso escaneado.',
              'Availability loaded for the scanned resource.',
            ),
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
    final t = context.l10n;
    if (_isLoading) {
      return AppScaffold(title: t.reservations, child: const AppLoadingView());
    }

    if (_error != null) {
      if (_limitedAccessMode) {
        return _buildLimitedAccessReservationMode(auth);
      }
      return AppScaffold(
        title: t.reservations,
        child: AppEmptyState(
          title: t.couldNotLoadReservations,
          subtitle: _error!,
          icon: Icons.cloud_off_rounded,
          action: AppButton.primary(label: t.retry, onPressed: _loadInitial),
        ),
      );
    }

    return AppScaffold(
      title: t.reservations,
      padding: EdgeInsets.zero,
      actions: [
        if (auth.isInternalUser || auth.isAdmin)
          IconButton(
            onPressed: _scanReservationQr,
            icon: Icon(Icons.qr_code_scanner_rounded),
            tooltip: t.scanReservationQr,
          ),
        IconButton(onPressed: _loadInitial, icon: Icon(Icons.refresh_rounded)),
      ],
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(
            text: t.newReservation,
            icon: Icon(Icons.add_circle_outline_rounded),
          ),
          Tab(text: t.myReservations, icon: const Icon(Icons.list_alt_rounded)),
          Tab(text: t.dailyAgenda, icon: Icon(Icons.calendar_view_day_rounded)),
        ],
      ),
      child: SizedBox.expand(
        child: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  AppSectionHeader(
                    title: t.quickReservation,
                    subtitle: t.quickReservationHint,
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
                    AppEmptyState(
                      title: t.reservationUnavailable,
                      subtitle: t.reservationUnavailableHint,
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
                  AppSectionHeader(
                    title: t.myReservations,
                    subtitle: t.records(_reservas.length),
                  ),
                  if (_reservasError != null)
                    _buildReservasNotice(_reservasError!),
                  if (_reservas.isEmpty)
                    AppEmptyState(
                      title: t.noReservations,
                      subtitle: t.noReservationsHint,
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
                  AppSectionHeader(
                    title: t.dailyAgenda,
                    subtitle: t.agendaVisible(
                      _agendaReservas.length,
                      _formatAgendaDay(_agendaDay),
                    ),
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
                    AppEmptyState(
                      title: t.noReservationsDay,
                      subtitle: t.noReservationsDayHint,
                      icon: Icons.calendar_today_outlined,
                    )
                  else
                    _buildAgendaTimeline(auth),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitedAccessReservationMode(AuthProvider auth) {
    final t = context.l10n;
    return AppScaffold(
      title: t.reservations,
      padding: EdgeInsets.zero,
      actions: [
        if (auth.isInternalUser || auth.isAdmin)
          IconButton(
            onPressed: _scanReservationQr,
            icon: Icon(Icons.qr_code_scanner_rounded),
            tooltip: t.scanReservationQr,
          ),
        IconButton(onPressed: _loadInitial, icon: Icon(Icons.refresh_rounded)),
      ],
      appBarBottom: TabBar(
        controller: _tabController,
        tabs: [
          Tab(text: t.myReservations, icon: const Icon(Icons.list_alt_rounded)),
          Tab(text: t.dailyAgenda, icon: Icon(Icons.calendar_view_day_rounded)),
          Tab(text: t.access, icon: const Icon(Icons.lock_outline_rounded)),
        ],
      ),
      child: SizedBox.expand(
        child: TabBarView(
          controller: _tabController,
          children: [
            RefreshIndicator(
              onRefresh: _loadInitial,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                children: [
                  AppSectionHeader(
                    title: t.myReservations,
                    subtitle: t.records(_reservas.length),
                  ),
                  if (_reservasError != null)
                    _buildReservasNotice(_reservasError!),
                  if (_reservas.isEmpty)
                    AppEmptyState(
                      title: t.noReservations,
                      subtitle: t.noReservationsHint,
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
                  AppSectionHeader(
                    title: t.dailyAgenda,
                    subtitle: t.agendaVisible(
                      _agendaReservas.length,
                      _formatAgendaDay(_agendaDay),
                    ),
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
                    AppEmptyState(
                      title: t.noReservationsDay,
                      subtitle: t.noReservationsDayHint,
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
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            AppIconSurface(
                              icon: Icons.lock_outline_rounded,
                              color: AppTheme.primary,
                              size: 42,
                              iconSize: 20,
                            ),
                            SizedBox(width: 8),
                            Text(
                              t.limitedReservations,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          t.limitedReservationsHint,
                          style: TextStyle(
                            color: AppTheme.textSecondaryFor(context),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: NeumorphicSurface(
                            padding: const EdgeInsets.all(12),
                            color: AppTheme.elevatedFor(context),
                            borderRadius: AppTheme.radiusSm,
                            subtle: true,
                            child: Text(
                              context.uiText(
                                'Si este usuario debe poder reservar desde la app, hay que habilitar permisos API para su perfil en el flujo de reservas.',
                                'If this user needs to book from the app, API permissions must be enabled for their profile in the reservation flow.',
                              ),
                              style: TextStyle(
                                color: AppTheme.textMutedFor(context),
                                fontSize: 12,
                              ),
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
            ),
          ],
        ),
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
                const AppIconSurface(
                  icon: Icons.qr_code_2_rounded,
                  color: AppTheme.primary,
                  size: 42,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label?.trim().isNotEmpty == true
                        ? context.l10n.selectedResource(label!)
                        : context.l10n.selectedResource(context.l10n.resource),
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: _clearReservationTarget,
                  child: Text(context.uiText('Limpiar', 'Clear')),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              '${context.uiText('Mostrando disponibilidad y agenda para', 'Showing availability and schedule for')} $dayLabel.',
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
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
          Row(
            children: [
              const AppIconSurface(
                icon: Icons.qr_code_2_rounded,
                color: AppTheme.primary,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              Text(
                context.uiText('QR de recurso', 'Resource QR'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            variantId == null
                ? context.uiText(
                    'Selecciona un microservicio o recurso para generar su QR.',
                    'Select a microservice or resource to generate its QR code.',
                  )
                : context.uiText(
                    'Este QR abrirá la app directamente en el recurso seleccionado y mostrará siempre la disponibilidad del día actual.',
                    'This QR code opens the app directly on the selected resource and always shows availability for the current day.',
                  ),
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
            ),
          ),
          if (variantId != null) ...[
            const SizedBox(height: 12),
            Center(
              child: NeumorphicSurface(
                padding: const EdgeInsets.all(16),
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                subtle: true,
                child: Column(
                  children: [
                    QrImageView(
                      data: payload,
                      size: 220,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Colors.black,
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      variantName ?? context.uiText('Recurso', 'Resource'),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${context.uiText('Servicio', 'Service')} ${templateId ?? '-'} · ${context.uiText('Recurso', 'Resource')} $variantId',
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            SelectableText(
              payload,
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMutedFor(context),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isExportingQr ? null : _exportCurrentQrPng,
                    icon: _isExportingQr
                        ? const AppLoadingIndicator(size: 16)
                        : Icon(Icons.download_rounded),
                    label: Text(
                      _isExportingQr
                          ? context.uiText('Exportando...', 'Exporting...')
                          : context.uiText('Exportar PNG', 'Export PNG'),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isExportingQr ? null : _shareCurrentQrPng,
                    icon: Icon(Icons.share_rounded),
                    label: Text(context.uiText('Compartir', 'Share')),
                  ),
                ),
              ],
            ),
          ],
          if (variant != null &&
              (variant['display_name'] ?? '').toString().trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.uiText(
                'Tip: genera el QR después de seleccionar el microservicio exacto en el paso 2.',
                'Tip: generate the QR code after selecting the exact microservice in step 2.',
              ),
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textMutedFor(context),
              ),
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
          Row(
            children: [
              const AppIconSurface(
                icon: Icons.health_and_safety_outlined,
                color: AppTheme.primary,
                size: 42,
                iconSize: 20,
              ),
              const SizedBox(width: 10),
              Text(
                context.uiText('Diagnóstico API', 'API diagnostics'),
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            context.uiText(
              'Comprueba desde la propia app qué partes del flujo de reservas permite este perfil por API.',
              'Check from the app which parts of the reservation flow this profile allows through the API.',
            ),
            style: TextStyle(
              color: AppTheme.textSecondaryFor(context),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: NeumorphicSurface(
              padding: const EdgeInsets.all(12),
              color: AppTheme.elevatedFor(context),
              borderRadius: AppTheme.radiusSm,
              subtle: true,
              child: Text(
                '${context.uiText('Día actual', 'Current day')}: ${_formatAgendaDay(_currentReservationDay())}\n'
                '${context.uiText('Servicio', 'Service')}: ${serviceLabel ?? '-'}\n'
                '${context.uiText('Recurso', 'Resource')}: ${variantLabel ?? '-'}',
                style: TextStyle(
                  color: AppTheme.textMutedFor(context),
                  fontSize: 12,
                ),
              ),
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
                      ? const AppLoadingIndicator(size: 16)
                      : Icon(Icons.playlist_add_check_circle_rounded),
                  label: Text(
                    _isRunningApiChecks
                        ? context.uiText('Comprobando...', 'Checking...')
                        : context.uiText(
                            'Comprobar permisos API',
                            'Check API permissions',
                          ),
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
      child: SizedBox(
        width: double.infinity,
        child: NeumorphicSurface(
          padding: const EdgeInsets.all(12),
          color: AppTheme.elevatedFor(context),
          borderRadius: AppTheme.radiusSm,
          subtle: true,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconSurface(icon: icon, color: color, size: 38, iconSize: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      result.label,
                      style: TextStyle(
                        color: AppTheme.textPrimaryFor(context),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      result.message,
                      style: TextStyle(
                        color: AppTheme.textMutedFor(context),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _runReservationApiDiagnostics() async {
    final auth = context.read<AuthProvider>();
    final today = _currentReservationDay();
    final startDay = today;
    final endDay = startDay.add(const Duration(days: 1));
    final reservableServicesLabel = context.uiText(
      'Servicios reservables',
      'Reservable services',
    );
    final noServicesMessage = context.uiText(
      'Sin servicios visibles para este usuario.',
      'No services are visible for this user.',
    );
    final servicesOkMessage = context.uiText(
      'Lectura OK del catálogo de servicios.',
      'Service catalog read successfully.',
    );
    final serviceResourcesLabel = context.uiText(
      'Recursos del servicio',
      'Service resources',
    );
    final noResourcesMessage = context.uiText(
      'Sin recursos visibles para el servicio seleccionado.',
      'No resources are visible for the selected service.',
    );
    final resourcesOkMessage = context.uiText(
      'Lectura OK de recursos/microservicios.',
      'Resources/microservices read successfully.',
    );
    final sessionTypesLabel = context.uiText(
      'Tipos de sesión',
      'Session types',
    );
    final noSessionTypesMessage = context.uiText(
      'No hay tipos de sesión visibles o no aplican a este servicio.',
      'No session types are visible or applicable to this service.',
    );
    final sessionTypesOkMessage = context.uiText(
      'Lectura OK de tipos de sesión.',
      'Session types read successfully.',
    );
    final myReservationsLabel = context.l10n.myReservations;
    final noOwnReservationsMessage = context.uiText(
      'Consulta OK, pero este usuario no tiene reservas propias visibles.',
      'Query succeeded, but this user has no visible reservations.',
    );
    final ownReservationsOkMessage = context.uiText(
      'Lectura OK de reservas propias.',
      'Own reservations read successfully.',
    );
    final dailyAgendaLabel = context.l10n.dailyAgenda;
    final noDailyAgendaMessage = context.uiText(
      'Consulta OK para la agenda del día, sin reservas visibles hoy.',
      'Daily schedule query succeeded with no visible reservations today.',
    );
    final dailyAgendaOkMessage = context.uiText(
      'Lectura OK de agenda diaria.',
      'Daily schedule read successfully.',
    );
    final createPermissionLabel = context.uiText(
      'Permiso de creación',
      'Create permission',
    );
    final createAllowedMessage = context.uiText(
      'El modelo permite crear reservas por API.',
      'The model allows reservations to be created through the API.',
    );
    final noCreatePermissionMessage = context.uiText(
      'Sin permiso de creación en reserva.reserva.',
      'No create permission on reserva.reserva.',
    );
    final editPermissionLabel = context.uiText(
      'Permiso de edición',
      'Edit permission',
    );
    final editAllowedMessage = context.uiText(
      'El modelo permite editar reservas por API.',
      'The model allows reservations to be edited through the API.',
    );
    final noEditPermissionMessage = context.uiText(
      'Sin permiso de edición en reserva.reserva.',
      'No edit permission on reserva.reserva.',
    );

    setState(() {
      _isRunningApiChecks = true;
      _apiCheckResults = const [];
    });

    final checks = <_ReservationApiCheckResult>[
      await _runApiCheck(reservableServicesLabel, () async {
        final rows = await _odoo.searchRead(
          'product.template',
          domain: [
            ['reservable_cic', '=', true],
            ['detailed_type', '=', 'service'],
          ],
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty ? noServicesMessage : servicesOkMessage;
      }),
      await _runApiCheck(serviceResourcesLabel, () async {
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
        return rows.isEmpty ? noResourcesMessage : resourcesOkMessage;
      }),
      await _runApiCheck(sessionTypesLabel, () async {
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
        return rows.isEmpty ? noSessionTypesMessage : sessionTypesOkMessage;
      }),
      await _runApiCheck(myReservationsLabel, () async {
        final rows = await _odoo.searchRead(
          'reserva.reserva',
          domain: [
            ['contacto_id', '=', auth.partnerId],
          ],
          fields: ['name'],
          limit: 1,
        );
        return rows.isEmpty
            ? noOwnReservationsMessage
            : ownReservationsOkMessage;
      }),
      await _runApiCheck(dailyAgendaLabel, () async {
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
        return rows.isEmpty ? noDailyAgendaMessage : dailyAgendaOkMessage;
      }),
      await _runApiCheck(createPermissionLabel, () async {
        final allowed = await _odoo.callMethod(
          'reserva.reserva',
          'check_access_rights',
          args: ['create'],
          kwargs: const {'raise_exception': false},
        );
        if (allowed == true) {
          return createAllowedMessage;
        }
        throw Exception(noCreatePermissionMessage);
      }),
      await _runApiCheck(editPermissionLabel, () async {
        final allowed = await _odoo.callMethod(
          'reserva.reserva',
          'check_access_rights',
          args: ['write'],
          kwargs: const {'raise_exception': false},
        );
        if (allowed == true) {
          return editAllowedMessage;
        }
        throw Exception(noEditPermissionMessage);
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
    final limitedAccessPrefix = context.uiText(
      'Acceso limitado',
      'Limited access',
    );
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
          e.toString().toLowerCase().contains('sin permiso') ||
          e.toString().toLowerCase().contains('no create permission') ||
          e.toString().toLowerCase().contains('no edit permission');
      return _ReservationApiCheckResult(
        label: label,
        status: limited
            ? _ReservationApiCheckStatus.limited
            : _ReservationApiCheckStatus.error,
        message: limited
            ? '$limitedAccessPrefix: ${OdooService.prettyError(e)}'
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
                icon: Icon(Icons.chevron_left_rounded),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      context.uiText('Día consultado', 'Selected day'),
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
                icon: Icon(Icons.chevron_right_rounded),
              ),
            ],
          ),
          if (_variants.isNotEmpty) ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              initialValue: _agendaVariantFilterId,
              decoration: InputDecoration(
                labelText: context.uiText('Agenda visible', 'Visible schedule'),
                prefixIcon: const Icon(Icons.meeting_room_outlined),
              ),
              items: [
                DropdownMenuItem<int?>(
                  value: null,
                  child: Text(
                    context.uiText('Todos los recursos', 'All resources'),
                  ),
                ),
                ..._variants.map((variant) {
                  final id = (variant['id'] as num?)?.toInt();
                  return DropdownMenuItem<int?>(
                    value: id,
                    child: Text(
                      (variant['display_name'] ??
                              variant['name'] ??
                              context.uiText('Recurso', 'Resource'))
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
                ? context.uiText(
                    'Los QR se generan al seleccionar un microservicio o recurso en la pestaña Nueva.',
                    'QR codes are generated after selecting a microservice or resource on the New tab.',
                  )
                : context.uiText(
                    'La agenda muestra la ocupación de los recursos sin revelar datos de otros usuarios.',
                    'The schedule shows resource occupancy without revealing other users’ data.',
                  ),
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
          fallback: context.uiText('Servicio', 'Service'),
        );
        final contacto = auth.isPortalUser
            ? context.uiText('Reserva ocupada', 'Occupied reservation')
            : OdooValues.many2oneLabel(
                r['contacto_id'],
                fallback: context.uiText('Sin contacto', 'No contact'),
              );
        final estado = OdooValues.string(r['estado']);
        final color = _estadoColor(estado);
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: AppCard(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NeumorphicSurface(
                  width: 78,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 10,
                  ),
                  color: Color.alphaBlend(
                    color.withValues(alpha: 0.10),
                    AppTheme.cardFor(context),
                  ),
                  borderRadius: AppTheme.radiusSm,
                  subtle: true,
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
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondaryFor(context),
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
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimaryFor(context),
                              ),
                            ),
                          ),
                          AppStatusChip(
                            label: _formatEstado(context, estado),
                            color: color,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contacto,
                        style: TextStyle(
                          color: AppTheme.textSecondaryFor(context),
                          fontSize: 12,
                        ),
                      ),
                      if (OdooValues.many2oneId(r['session_type_id']) !=
                          null) ...[
                        const SizedBox(height: 4),
                        Text(
                          '${context.l10n.type}: ${OdooValues.many2oneLabel(r['session_type_id'], fallback: context.uiText('Sesión', 'Session'))}',
                          style: TextStyle(
                            color: AppTheme.textMutedFor(context),
                            fontSize: 12,
                          ),
                        ),
                      ],
                      if (!auth.isPortalUser &&
                          (r['motivo'] ?? '').toString().trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          (r['motivo'] ?? '').toString(),
                          style: TextStyle(
                            color: AppTheme.textMutedFor(context),
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

  String _formatEstado(BuildContext context, String estado) {
    final t = context.l10n;
    switch (estado) {
      case 'confirmada':
        return t.confirmed;
      case 'facturada':
        return t.billed;
      case 'cancelada':
        return t.cancelled;
      case 'borrador':
        return t.draft;
      default:
        return estado.isEmpty ? t.reservation : estado;
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
      child: AppCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const AppIconSurface(
              icon: Icons.info_outline_rounded,
              color: AppTheme.info,
              size: 38,
              iconSize: 18,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: AppTheme.textMutedFor(context),
                  fontSize: 12,
                ),
              ),
            ),
          ],
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
    final label = Uri.encodeComponent(
      _selectedVariantName() ?? context.uiText('Recurso', 'Resource'),
    );
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
    final renderErrorMessage = context.uiText(
      'No se pudo renderizar el PNG del QR.',
      'Could not render the QR PNG.',
    );
    final exportedPrefix = context.uiText(
      'QR exportado en PNG',
      'QR exported as PNG',
    );
    final couldNotExportPrefix = context.uiText(
      'No se pudo exportar el QR',
      'Could not export the QR',
    );
    if (_variantId == null) {
      _showSnack(
        context.uiText(
          'Selecciona antes un microservicio para generar el QR.',
          'Select a microservice before generating the QR code.',
        ),
        isError: true,
      );
      return;
    }

    setState(() => _isExportingQr = true);
    try {
      final bytes = await _generateQrPngBytes(_buildReservationQrPayload());
      if (bytes == null || bytes.isEmpty) {
        throw Exception(renderErrorMessage);
      }

      final name =
          'qr_reserva_${AttachmentService.sanitizeFileName(_selectedVariantName() ?? 'recurso')}_${_variantId!}.png';
      final file = await _attachmentService.writeBytesToDocuments(
        name: name,
        bytes: bytes,
        folderName: 'reservas_qr',
      );
      await OpenFilex.open(file.path);
      _showSnack('$exportedPrefix: ${file.path}');
    } catch (e) {
      _showSnack(
        '$couldNotExportPrefix: ${OdooService.prettyError(e)}',
        isError: true,
      );
    }

    if (mounted) {
      setState(() => _isExportingQr = false);
    }
  }

  Future<void> _shareCurrentQrPng() async {
    final renderErrorMessage = context.uiText(
      'No se pudo renderizar el PNG del QR.',
      'Could not render the QR PNG.',
    );
    final temporaryFileErrorMessage = context.uiText(
      'No se pudo guardar el fichero temporal del QR.',
      'Could not save the temporary QR file.',
    );
    final reservationQrPrefix = context.uiText(
      'QR de reserva',
      'Reservation QR',
    );
    final resourceFallback = context.uiText('recurso', 'resource');
    final couldNotSharePrefix = context.uiText(
      'No se pudo compartir el QR',
      'Could not share the QR',
    );
    if (_variantId == null) {
      _showSnack(
        context.uiText(
          'Selecciona antes un microservicio para generar el QR.',
          'Select a microservice before generating the QR code.',
        ),
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
        throw Exception(renderErrorMessage);
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
        throw Exception(temporaryFileErrorMessage);
      }
      await Share.shareXFiles(
        [XFile(file.path, mimeType: 'image/png', name: fileName)],
        subject:
            '$reservationQrPrefix ${_selectedVariantName() ?? resourceFallback}',
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
        '$couldNotSharePrefix: ${OdooService.prettyError(e)}',
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
        color: Colors.black,
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Colors.black,
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
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_editingReservationId != null) ...[
            Text(
              context.l10n.editingDraft,
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
                    icon: Icon(Icons.arrow_back_rounded),
                    label: Text(context.l10n.back),
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
                            ? const AppLoadingIndicator(size: 16)
                            : Icon(Icons.check_circle_outline_rounded))
                      : Icon(Icons.arrow_forward_rounded),
                  label: Text(
                    _wizardStep == 3
                        ? (_isCreating
                              ? (_editingReservationId == null
                                    ? context.l10n.creating
                                    : context.l10n.saving)
                              : (_editingReservationId == null
                                    ? context.l10n.createDraft
                                    : context.l10n.saveChanges))
                        : context.l10n.next,
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
    final labels = [
      context.l10n.service,
      context.l10n.resource,
      context.l10n.schedule,
      context.l10n.confirm,
    ];
    return Row(
      children: List.generate(labels.length, (i) {
        final active = i == _wizardStep;
        final done = i < _wizardStep;
        return Expanded(
          child: Column(
            children: [
              SizedBox(
                width: 28,
                height: 28,
                child: NeumorphicSurface(
                  color: done || active
                      ? AppTheme.primary
                      : AppTheme.elevatedFor(context),
                  borderRadius: BorderRadius.circular(14),
                  padding: EdgeInsets.zero,
                  subtle: !active,
                  child: Center(
                    child: done
                        ? const Icon(
                            Icons.check_rounded,
                            size: 15,
                            color: Colors.white,
                          )
                        : Text(
                            '${i + 1}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: active
                                  ? Colors.white
                                  : AppTheme.textMutedFor(context),
                            ),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                labels[i],
                style: TextStyle(
                  fontSize: 11,
                  color: active
                      ? AppTheme.primary
                      : AppTheme.textMutedFor(context),
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
              Text(
                context.uiText(
                  'Paso 1: elige el servicio',
                  'Step 1: choose the service',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.category_outlined,
                context.uiText(
                  'Elige el tipo de servicio. En el siguiente paso seleccionarás el recurso concreto que quieres reservar.',
                  'Choose the service type. In the next step you will select the specific resource you want to reserve.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _services.map((s) {
                  final id = s['id'] as int;
                  final selected = _serviceTemplateId == id;
                  return AppChoicePill(
                    label: (s['name'] ?? '').toString(),
                    icon: Icons.category_outlined,
                    selected: selected,
                    onTap: () async {
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
              Text(
                context.uiText(
                  'Paso 2: elige recurso',
                  'Step 2: choose a resource',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.meeting_room_outlined,
                context.uiText(
                  'Selecciona el recurso exacto. Si aparece un tipo de sesión, debes elegir el que corresponda antes de continuar.',
                  'Select the exact resource. If a session type appears, choose the right one before continuing.',
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _variants.map((v) {
                  final id = v['id'] as int;
                  final selected = _variantId == id;
                  return AppChoicePill(
                    label: '${v['display_name']} (${_money(v['lst_price'])}/h)',
                    icon: Icons.meeting_room_outlined,
                    selected: selected,
                    onTap: () async {
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
                  decoration: InputDecoration(
                    labelText: context.l10n.sessionType,
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
              Text(
                context.uiText(
                  'Paso 3: elige horario',
                  'Step 3: choose a time',
                ),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              _buildWizardHint(
                Icons.schedule_outlined,
                context.uiText(
                  'Solo puedes elegir franjas libres. Las reservas se hacen en bloques de 30 minutos y no se permiten horarios pasados ni solapados.',
                  'You can only choose free slots. Reservations use 30-minute blocks and past or overlapping times are not allowed.',
                ),
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
                    return AppChoicePill(
                      label: _dayLabel(d),
                      icon: Icons.calendar_today_outlined,
                      selected: selected,
                      onTap: () async {
                        setState(() => _selectedDay = d);
                        await _loadAvailability();
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Text(
                context.l10n.availableHours,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              if (_isLoadingAvailability)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Center(child: AppLoadingIndicator(size: 30)),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: slots.map((slot) {
                  final selected =
                      _start != null && _start!.isAtSameMomentAs(slot);
                  final busy = _isSlotBusy(slot);
                  return AppChoicePill(
                    label: _slotLabel(slot),
                    icon: busy
                        ? Icons.lock_clock_rounded
                        : Icons.schedule_rounded,
                    selected: selected,
                    onTap: busy
                        ? null
                        : () {
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
              Text(
                context.l10n.duration,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryFor(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [30, 60, 90, 120].map((minutes) {
                  final selected = _durationMinutes == minutes;
                  return AppChoicePill(
                    label: _durationLabel(minutes),
                    icon: Icons.timelapse_rounded,
                    selected: selected,
                    onTap: () {
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
                context.uiText(
                  'Revisa los datos antes de guardar. La reserva quedará en borrador: podrás editarla o confirmarla desde «Mis reservas».',
                  'Review the details before saving. The reservation will stay as a draft so you can edit or confirm it from “My reservations”.',
                ),
              ),
              const SizedBox(height: 12),
              AppInput(
                controller: _motivoCtrl,
                labelText: context.l10n.reasonOptional,
                prefixIcon: Icons.notes_rounded,
              ),
              const SizedBox(height: 10),
              NeumorphicSurface(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                color: AppTheme.elevatedFor(context),
                borderRadius: AppTheme.radiusSm,
                subtle: true,
                child: Text(
                  '${context.uiText('Resumen', 'Summary')}: ${selectedService?['name'] ?? '-'} · ${selectedVariant?['display_name'] ?? '-'}\n'
                  '${_fmt(_start!)} -> ${_fmt(_end!)} · ${_money(((hourlyPrice is num ? hourlyPrice.toDouble() : 0) * (_durationMinutes / 60)))}',
                  style: TextStyle(
                    color: AppTheme.textSecondaryFor(context),
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
    return NeumorphicSurface(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      color: Color.alphaBlend(
        AppTheme.primary.withValues(alpha: 0.08),
        AppTheme.cardFor(context),
      ),
      borderRadius: AppTheme.radiusSm,
      subtle: true,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconSurface(
            icon: icon,
            color: AppTheme.primary,
            size: 38,
            iconSize: 18,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: AppCard(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const AppIconSurface(
                  icon: Icons.event_available_rounded,
                  color: AppTheme.primary,
                  size: 42,
                  iconSize: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    servicio,
                    style: TextStyle(
                      color: AppTheme.textPrimaryFor(context),
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
              style: TextStyle(
                color: AppTheme.textSecondaryFor(context),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${context.l10n.duration}: ${duracion.toStringAsFixed(1)}h  ·  ${context.uiText('Total', 'Total')}: ${_money(total)}',
              style: TextStyle(
                color: AppTheme.textMutedFor(context),
                fontSize: 12,
              ),
            ),
            if (session.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.l10n.type}: $session',
                  style: TextStyle(
                    color: AppTheme.textMutedFor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            if (motivo.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.l10n.reason}: $motivo',
                  style: TextStyle(
                    color: AppTheme.textMutedFor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            if (contacto.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  '${context.l10n.requester}: $contacto',
                  style: TextStyle(
                    color: AppTheme.textMutedFor(context),
                    fontSize: 12,
                  ),
                ),
              ),
            if (estado == 'borrador' && auth.canEditModule('reservas')) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    onPressed: () => _editarReserva(r),
                    icon: Icon(Icons.edit_outlined),
                    label: Text(context.l10n.edit),
                  ),
                  TextButton.icon(
                    onPressed: () => _confirmarReserva(id),
                    icon: Icon(Icons.check_circle_outline_rounded),
                    label: Text(context.l10n.confirm),
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
                  icon: Icon(Icons.cancel_outlined),
                  label: Text(context.l10n.cancel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _estadoBadge(String estado) {
    final color = _estadoColor(estado);
    return AppStatusChip(label: _formatEstado(context, estado), color: color);
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
        backgroundColor: isError
            ? AppTheme.danger
            : Theme.of(context).colorScheme.inverseSurface,
      ),
    );
  }
}
