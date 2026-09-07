// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get accessibility => 'Accesibilidad';

  @override
  String get readingVision => 'Lectura y visión';

  @override
  String get readingVisionHint =>
      'Ajusta la interfaz a tus necesidades visuales.';

  @override
  String get textSize => 'Tamaño del texto';

  @override
  String get textSizeHint => 'Se combina con el ajuste del dispositivo.';

  @override
  String get boldText => 'Texto reforzado';

  @override
  String get boldTextHint =>
      'Aumenta el grosor del texto para facilitar la lectura.';

  @override
  String get highContrast => 'Alto contraste';

  @override
  String get highContrastHint => 'Refuerza fondos, bordes y textos.';

  @override
  String get movement => 'Movimiento';

  @override
  String get movementHint =>
      'Reduce efectos que puedan causar mareo o distracción.';

  @override
  String get reduceMotion => 'Reducir animaciones';

  @override
  String get reduceMotionHint =>
      'Desactiva las transiciones y las entradas animadas.';

  @override
  String get preview => 'Vista previa';

  @override
  String get previewSuccess => 'Completado';

  @override
  String get previewWarning => 'Pendiente';

  @override
  String get previewText =>
      'Comprueba aquí el tamaño, el grosor y el contraste seleccionados.';

  @override
  String get resetAccessibility => 'Restablecer accesibilidad';

  @override
  String get colorSupport => 'Distinción de colores';

  @override
  String get colorSupportHint =>
      'Los estados incluyen texto e iconos. Puedes activar una paleta azul y naranja si te cuesta distinguir el rojo y el verde.';

  @override
  String get alternativeColors => 'Paleta azul y naranja';

  @override
  String get screenReader => 'Lector de pantalla';

  @override
  String get screenReaderHint =>
      'Para navegación hablada, activa VoiceOver en los ajustes de accesibilidad de iPhone o TalkBack en Android. No necesitas activar un modo especial en esta app.';

  @override
  String get language => 'Idioma';

  @override
  String get languageHint =>
      'Idioma de la interfaz. Los contenidos enviados por otras personas conservan su idioma original.';

  @override
  String get systemLanguage => 'Idioma del dispositivo';

  @override
  String get languageProgress =>
      'La traducción al inglés se está completando; algunos módulos todavía aparecen en español.';

  @override
  String get home => 'Inicio';

  @override
  String get modules => 'Módulos';

  @override
  String get activity => 'Actividad';

  @override
  String get profile => 'Perfil';

  @override
  String get myProfile => 'Mi perfil';

  @override
  String get preferences => 'Preferencias';

  @override
  String get preferencesHint => 'Apariencia y necesidades de acceso';

  @override
  String get accessibilityHint => 'Texto, contraste y reducción de movimiento';

  @override
  String get darkMode => 'Modo oscuro';

  @override
  String get darkModeHint => 'Alternar tema claro / oscuro';

  @override
  String get logout => 'Cerrar sesión';

  @override
  String get personalInfo => 'Información personal';

  @override
  String get basicProfile => 'Datos básicos del perfil';

  @override
  String get phone => 'Teléfono';

  @override
  String get mobile => 'Móvil';

  @override
  String get position => 'Puesto';

  @override
  String get documentation => 'Documentación';

  @override
  String get retry => 'Reintentar';

  @override
  String get profileError => 'No se pudo cargar el perfil';

  @override
  String get view => 'Ver';

  @override
  String get noCv => 'No hay CV cargado';

  @override
  String get backToTop => 'Volver arriba';

  @override
  String get quickActions => 'Accesos rápidos';

  @override
  String get editProfile => 'Editar perfil';

  @override
  String get explore => 'Explorar';

  @override
  String get availableModules => 'Módulos disponibles';

  @override
  String get availableModulesHint =>
      'Solo ves las áreas habilitadas para tu perfil en Odoo.';

  @override
  String get searchModules => 'Buscar módulos...';

  @override
  String modulesAvailable(int count) {
    return '$count módulos disponibles';
  }

  @override
  String get modulesLoadError =>
      'No se pudo cargar el catálogo de módulos para este perfil.';

  @override
  String get all => 'Todas';

  @override
  String get unread => 'No leídas';

  @override
  String get important => 'Importantes';

  @override
  String get loadingActivity => 'Cargando actividad...';

  @override
  String get noActivity => 'Sin actividad';

  @override
  String get noActivityHint => 'No hay notificaciones para este filtro.';

  @override
  String get activityCentre => 'Centro de actividad';

  @override
  String get activityCentreHint =>
      'Lo reciente, importante y pendiente de revisar.';

  @override
  String get total => 'Total';

  @override
  String get recentActivity => 'Actividad reciente';

  @override
  String get viewAll => 'Ver todo';

  @override
  String get viewAllModules => 'Ver todos';

  @override
  String get summary => 'Aquí tienes un resumen de lo importante.';

  @override
  String get goodMorning => 'Buenos días';

  @override
  String get goodAfternoon => 'Buenas tardes';

  @override
  String get goodEvening => 'Buenas noches';

  @override
  String get incidents => 'Incidencias';

  @override
  String get reservations => 'Reservas';

  @override
  String get training => 'Formación';

  @override
  String get open => 'Abiertas';

  @override
  String get today => 'Hoy';

  @override
  String get pending => 'Pendientes';

  @override
  String get upToDate => 'Todo al día';

  @override
  String get upToDateHint => 'No hay indicadores disponibles para este perfil.';

  @override
  String get unknownError => 'Error desconocido';

  @override
  String get communications => 'Comunicaciones';

  @override
  String get suggestions => 'Sugerencias';

  @override
  String get couldNotLoadCommunications =>
      'No se pudieron cargar las comunicaciones';

  @override
  String get createCommunication => 'Crear comunicación';

  @override
  String get communication => 'Comunicación';

  @override
  String get suggestion => 'Sugerencia';

  @override
  String get title => 'Título';

  @override
  String get type => 'Tipo';

  @override
  String get date => 'Fecha';

  @override
  String get description => 'Descripción';

  @override
  String get recipientUnits => 'Unidades destinatarias';

  @override
  String get recipientRoles => 'Puestos funcionales destinatarios';

  @override
  String get unit => 'Unidad';

  @override
  String get role => 'Puesto funcional';

  @override
  String get couldNotLoadRecipients => 'No se pueden cargar los destinatarios';

  @override
  String get couldNotRunAction => 'No se pudo ejecutar la acción';

  @override
  String get analyse => 'Analizar';

  @override
  String get markHandled => 'Marcar tratada';

  @override
  String get close => 'Cerrar';

  @override
  String get received => 'Recibida';

  @override
  String get inAnalysis => 'En análisis';

  @override
  String get handled => 'Tratada';

  @override
  String get answered => 'Respondida';

  @override
  String get closed => 'Cerrada';

  @override
  String get newReservation => 'Nueva reserva';

  @override
  String get myReservations => 'Mis reservas';

  @override
  String get dailyAgenda => 'Agenda diaria';

  @override
  String get quickReservation => 'Reserva rápida';

  @override
  String get quickReservationHint =>
      'Selecciona servicio, recurso y horario en 4 pasos';

  @override
  String get reservationUnavailable => 'Reserva no disponible';

  @override
  String get reservationUnavailableHint =>
      'Este usuario puede consultar reservas, pero no crear nuevas desde la app.';

  @override
  String get couldNotLoadReservations => 'No se pudieron cargar las reservas';

  @override
  String get scanReservationQr => 'Escanear QR de sala o equipo';

  @override
  String records(int count) {
    return '$count registros';
  }

  @override
  String get noReservations => 'Sin reservas';

  @override
  String get noReservationsHint => 'No tienes reservas registradas.';

  @override
  String agendaVisible(int count, String date) {
    return '$count reservas visibles el $date';
  }

  @override
  String get noReservationsDay => 'Sin reservas este día';

  @override
  String get noReservationsDayHint =>
      'No hay reservas disponibles para consultar en la fecha seleccionada.';

  @override
  String get limitedReservations => 'Reservas con acceso limitado';

  @override
  String get back => 'Atrás';

  @override
  String get next => 'Siguiente';

  @override
  String get createDraft => 'Crear borrador';

  @override
  String get saveChanges => 'Guardar cambios';

  @override
  String get creating => 'Creando...';

  @override
  String get saving => 'Guardando...';

  @override
  String get edit => 'Editar';

  @override
  String get confirm => 'Confirmar';

  @override
  String get cancel => 'Cancelar';

  @override
  String get editingDraft => 'Editando borrador';

  @override
  String get reason => 'Motivo';

  @override
  String get requester => 'Solicitante';

  @override
  String get access => 'Acceso';

  @override
  String get limitedReservationsHint =>
      'Este perfil está en modo de consulta dentro de la app. Puede revisar sus reservas y la agenda diaria, pero no crear ni editar nuevas reservas con sus permisos actuales.';

  @override
  String get service => 'Servicio';

  @override
  String get resource => 'Recurso';

  @override
  String get schedule => 'Horario';

  @override
  String get duration => 'Duración';

  @override
  String get sessionType => 'Tipo de sesión';

  @override
  String get reasonOptional => 'Motivo (opcional)';

  @override
  String get availableHours => 'Horas disponibles';

  @override
  String selectedResource(String name) {
    return 'Recurso seleccionado: $name';
  }

  @override
  String get selectService => 'Selecciona un servicio para continuar.';

  @override
  String get selectResource => 'Selecciona un recurso para continuar.';

  @override
  String get selectTimeSlot => 'Selecciona una franja horaria para continuar.';

  @override
  String get reservationUpdated =>
      'Reserva actualizada. Confírmala cuando esté lista.';

  @override
  String get draftCreated =>
      'Reserva creada en borrador. Revísala y confírmala cuando esté lista.';

  @override
  String get reservationConfirmed => 'Reserva confirmada.';

  @override
  String get reservationCancelled => 'Reserva cancelada.';

  @override
  String get draft => 'Borrador';

  @override
  String get confirmed => 'Confirmada';

  @override
  String get cancelled => 'Cancelada';

  @override
  String get reservation => 'Reserva';

  @override
  String get billed => 'Facturada';

  @override
  String get searchDocuments => 'Buscar documentos...';

  @override
  String get documentsLimitedAccess => 'Documentos con acceso limitado';

  @override
  String get documentsLimitedAccessHint =>
      'Este perfil no puede consultar el listado completo de documentos por API con sus permisos actuales.';

  @override
  String get couldNotLoadDocuments => 'No se pudieron cargar documentos';

  @override
  String get noDocuments => 'Sin documentos';

  @override
  String get noDocumentsHint =>
      'No se han encontrado resultados para esta búsqueda.';

  @override
  String documentsCount(int count) {
    return '$count documentos';
  }

  @override
  String versions(int count) {
    return '$count versiones';
  }

  @override
  String get document => 'Documento';

  @override
  String get documentWithoutAttachment => 'Documento sin versión adjunta.';

  @override
  String get couldNotOpenDocument => 'No se pudo abrir el documento';

  @override
  String get couldNotDownload => 'No se pudo descargar';

  @override
  String get createIncident => 'Crear incidencia';

  @override
  String get nonConformity => 'No conformidad';

  @override
  String get improvementOpportunity => 'Oportunidad de mejora';

  @override
  String get category => 'Categoría';

  @override
  String get quality => 'Calidad';

  @override
  String get healthSafety => 'PRL';

  @override
  String get subtype => 'Subtipo';

  @override
  String get internal => 'Interna';

  @override
  String get supplier => 'Proveedor';

  @override
  String get audit => 'Auditoría';

  @override
  String get claim => 'Reclamación';

  @override
  String get other => 'Otra';

  @override
  String get openPlural => 'Abiertas';

  @override
  String get inProgress => 'En proceso';

  @override
  String get closedPlural => 'Cerradas';

  @override
  String get noIncidents => 'No hay incidencias.';

  @override
  String incidentsCount(int count) {
    return '$count incidencias';
  }

  @override
  String get incidentsUnitHint => 'De tu unidad, ordenadas por fecha';

  @override
  String get signInTitle => 'Accede a tu espacio';

  @override
  String get signInHint => 'Usa las mismas credenciales que en Odoo Web.';

  @override
  String get corporateEmail => 'Correo corporativo';

  @override
  String get enterCorporateEmail => 'Introduce tu correo corporativo';

  @override
  String get password => 'Contraseña';

  @override
  String get enterPassword => 'Introduce tu contraseña';

  @override
  String get showPassword => 'Mostrar contraseña';

  @override
  String get hidePassword => 'Ocultar contraseña';

  @override
  String get verifying => 'Verificando';

  @override
  String get signIn => 'Entrar';

  @override
  String get encryptedSession =>
      'Sesión cifrada y permisos sincronizados con Odoo.';

  @override
  String get supportConfiguration => 'Configuración de soporte';

  @override
  String get authorisedServer => 'Servidor autorizado';

  @override
  String get authorisedEnvironment => 'Entorno autorizado';

  @override
  String get enterAuthorisedServer => 'Introduce el servidor autorizado';

  @override
  String get enterAuthorisedEnvironment => 'Introduce el entorno autorizado';

  @override
  String get useLightMode => 'Usar modo claro';

  @override
  String get useDarkMode => 'Usar modo oscuro';

  @override
  String get yourCicSpace => 'Tu espacio CIC';

  @override
  String get brandHint =>
      'Información, gestiones y seguimiento conectados con tu perfil.';

  @override
  String get privacyTitle => 'Privacidad desde el primer paso';

  @override
  String get privacyHint =>
      'Antes de identificarte no cargamos avisos, datos personales ni información de Odoo. Después verás solo lo autorizado para tu perfil.';

  @override
  String get signInHelpTitle => '¿Problemas para entrar? ';

  @override
  String get signInHelpHint =>
      'Comprueba tus credenciales habituales y, si continúa, contacta con el responsable de tu cuenta CIC.';

  @override
  String get accessVerificationFailed => 'No hemos podido verificar el acceso';

  @override
  String get loginValueOneTitle => 'Todo lo importante, ordenado';

  @override
  String get loginValueOneHint =>
      'Documentos, noticias, actividad y accesos en un mismo inicio.';

  @override
  String get loginValueTwoTitle => 'Gestiones conectadas';

  @override
  String get loginValueTwoHint =>
      'Reservas, incidencias y procesos actualizados con Odoo.';

  @override
  String get loginValueThreeTitle => 'Acceso según tu perfil';

  @override
  String get loginValueThreeHint =>
      'Cada persona ve únicamente los módulos que tiene autorizados.';

  @override
  String get recruitment => 'Reclutamiento';

  @override
  String get error => 'Error';

  @override
  String get vacancies => 'Vacantes';

  @override
  String get applications => 'Candidaturas';

  @override
  String get noVacancies => 'Sin vacantes';

  @override
  String get noVacanciesHint => 'No hay posiciones abiertas.';

  @override
  String get vacancy => 'Vacante';

  @override
  String get department => 'Departamento';

  @override
  String vacancyCount(int count) {
    return 'Vacantes: $count';
  }

  @override
  String get noApplications => 'Sin candidaturas';

  @override
  String get noApplicationsHint => 'No hay candidaturas registradas.';

  @override
  String get candidate => 'Candidato';

  @override
  String get job => 'Puesto';

  @override
  String get status => 'Estado';

  @override
  String linkedApplications(int count) {
    return '$count candidaturas vinculadas';
  }

  @override
  String get noVisibleApplicationsHint =>
      'Esta vacante no tiene candidaturas visibles.';

  @override
  String get email => 'Correo electrónico';

  @override
  String get providedDocuments => 'Documentación aportada';

  @override
  String get documentsReadOnlyHint =>
      'Consulta en modo lectura. No se permite descargar ni compartir archivos.';

  @override
  String get noCandidateDocuments => 'Sin documentación';

  @override
  String get noCandidateDocumentsHint =>
      'La candidatura no tiene documentos disponibles.';

  @override
  String get couldNotPreviewDocument => 'No se pudo visualizar el documento';

  @override
  String get trainingHistory => 'Historial';

  @override
  String get trainingLoadError => 'No se pudo cargar la formación';

  @override
  String get trainingLimitedAccess => 'Formación con acceso limitado';

  @override
  String get trainingLimitedAccessHint =>
      'Este perfil no puede consultar el historial completo de formaciones por API con sus permisos actuales.';

  @override
  String get trainingLimitedModeHint =>
      'La app sigue disponible en modo limitado. Si este perfil debe consultar el historial o certificados, hay que habilitar permisos API de formación en Odoo.';

  @override
  String get trainingNormalModeHint =>
      'Registra una formación externa o completa una formación pendiente desde su ficha.';

  @override
  String get noPendingTraining => 'No tienes formación pendiente';

  @override
  String get noPendingTrainingHint =>
      'Las formaciones asignadas o los cursos e-learning aparecerán aquí.';

  @override
  String get trainingHistoryUnavailable => 'Historial no disponible';

  @override
  String get trainingHistoryUnavailableHint =>
      'Este perfil no puede cargar asistencias de formación por API con sus permisos actuales.';

  @override
  String get noTrainingHistory => 'Sin historial';

  @override
  String get noTrainingHistoryHint => 'Aún no tienes asistencias de formación.';

  @override
  String scheduled(String date) {
    return 'Prevista: $date';
  }

  @override
  String completedOn(String date) {
    return 'Realizada: $date';
  }

  @override
  String hours(String count) {
    return '$count horas';
  }

  @override
  String elearningProgress(String progress) {
    return 'Progreso e-learning: $progress%';
  }

  @override
  String get certificate => 'Certificado';

  @override
  String get openCourse => 'Abrir curso';

  @override
  String get markCompleted => 'Marcar realizada';

  @override
  String couldNotOpenCertificate(String error) {
    return 'No se pudo abrir el certificado: $error';
  }

  @override
  String get couldNotOpenElearning => 'No se pudo abrir el curso e-learning.';

  @override
  String get completeTraining => 'Completar formación';

  @override
  String get change => 'Cambiar';

  @override
  String get attachOptionalCertificate => 'Adjuntar certificado (opcional)';

  @override
  String get upload => 'Subir';

  @override
  String get confirmCompletion => 'Confirmar realización';

  @override
  String couldNotCompleteTraining(String error) {
    return 'No se pudo completar la formación: $error';
  }

  @override
  String get registerExternalTraining => 'Registrar formación externa';

  @override
  String get trainingName => 'Nombre de la formación';

  @override
  String get entityCentre => 'Entidad / centro';

  @override
  String get completionDate => 'Fecha de finalización';

  @override
  String get choose => 'Elegir';

  @override
  String get attachCertificate => 'Adjuntar certificado (PDF)';

  @override
  String get sendRequest => 'Enviar solicitud';

  @override
  String get enterTrainingName => 'Indica el nombre de la formación.';

  @override
  String get enterTrainingCompletionDate =>
      'Indica la fecha de finalización de la formación.';

  @override
  String get trainingSubmitted =>
      'Formación enviada para validación de Calidad.';

  @override
  String couldNotRegister(String error) {
    return 'No se pudo registrar: $error';
  }

  @override
  String get available => 'Disponible';

  @override
  String get comingSoon => 'Próximamente';

  @override
  String get security => 'Seguridad';

  @override
  String get informationDelivered => 'Información entregada';

  @override
  String get payroll => 'Nóminas';

  @override
  String get planning => 'Planificación';

  @override
  String get healthSurveillance => 'Vigilancia de la salud';

  @override
  String get normative => 'Normativa';

  @override
  String get equipment => 'Equipos';

  @override
  String get publications => 'Publicaciones';

  @override
  String get permissionsRoles => 'Permisos y roles';

  @override
  String get suppliers => 'Proveedores';

  @override
  String get organisation => 'Organización';

  @override
  String get purchases => 'Compras';

  @override
  String get maintenance => 'Mantenimiento';

  @override
  String get moduleIncidentsDescription =>
      'Registro, seguimiento y cierre de incidencias de tu unidad';

  @override
  String get moduleTrainingDescription => 'Formación presencial y online';

  @override
  String get moduleDocumentsDescription =>
      'Consulta y descarga de documentos disponibles para ti';

  @override
  String get moduleSecurityDescription =>
      'Procedimientos y documentación de seguridad';

  @override
  String get moduleInformationDescription =>
      'Información y documentación entregada al usuario';

  @override
  String get modulePayrollDescription => 'Documentos salariales del portal';

  @override
  String get moduleRecruitmentDescription =>
      'Consulta de convocatorias y candidaturas asignadas';

  @override
  String get moduleReservationsDescription =>
      'Consulta disponibilidad y gestiona reservas de servicios y recursos';

  @override
  String get modulePlanningDescription =>
      'Objetivos, planes de acción, químicos e informes';

  @override
  String get moduleHealthDescription => 'Seguimiento de vigilancia de la salud';

  @override
  String get moduleNormativeDescription =>
      'Consulta de normativa y documentación aplicable';

  @override
  String get moduleEquipmentDescription =>
      'Inventario y seguimiento de equipos asociados a calidad';

  @override
  String get modulePublicationsDescription =>
      'Consulta de publicaciones y contenidos informativos';

  @override
  String get modulePermissionsDescription => 'Roles y aprobaciones internas';

  @override
  String get moduleCommunicationsDescription =>
      'Comunicaciones, avisos y sugerencias';

  @override
  String get moduleSuppliersDescription =>
      'Gestión y seguimiento de proveedores';

  @override
  String get moduleOrganisationDescription =>
      'Pendiente de integrar con estructura organizativa';

  @override
  String get modulePurchasesDescription =>
      'Consulta de productos, códigos y recepción de compras';

  @override
  String get moduleMaintenanceDescription =>
      'Solicitudes de mantenimiento y equipos enlazados con calidad';

  @override
  String get goals => 'Objetivos';

  @override
  String get actionPlans => 'Planes de acción';

  @override
  String get chemicals => 'Químicos';

  @override
  String get chemicalReport => 'Informe de químicos';

  @override
  String get goalsPlanningHint =>
      'Consulta y edición de objetivos de calidad y PRL.';

  @override
  String get actionPlansPlanningHint =>
      'Acciones preventivas y planes ligados a objetivos.';

  @override
  String get chemicalsPlanningHint =>
      'Inventario, peligrosidad, caducidades y fichas.';

  @override
  String get chemicalReportPlanningHint =>
      'Resumen operativo por tipo y peligrosidad.';

  @override
  String get noAccess => 'Sin acceso';

  @override
  String get noPlanningAccess =>
      'No tienes permisos para ver ningún apartado de planificación.';

  @override
  String get searchPayslips => 'Buscar nóminas...';

  @override
  String get couldNotLoadPayslips => 'No se pudieron cargar las nóminas';

  @override
  String get noPayslips => 'Sin nóminas';

  @override
  String get noPayslipsHint => 'No hay documentos de nómina disponibles.';

  @override
  String get payslip => 'Nómina';

  @override
  String get noDate => 'sin fecha';

  @override
  String couldNotOpen(String error) {
    return 'No se pudo abrir: $error';
  }

  @override
  String documentDownloaded(String path) {
    return 'Documento descargado: $path';
  }

  @override
  String couldNotDownloadError(String error) {
    return 'No se pudo descargar: $error';
  }

  @override
  String get noHealthForms => 'Sin formularios';

  @override
  String get noHealthFormsHint => 'No hay reconocimientos registrados.';

  @override
  String get historicalCicCheckup => 'Reconocimiento histórico CIC';

  @override
  String get healthCheckup => 'Reconocimiento';

  @override
  String checkupDate(String date) {
    return 'Reconocimiento: $date';
  }

  @override
  String realisationDate(String date) {
    return 'Realización: $date';
  }

  @override
  String couldNotSend(String error) {
    return 'No se pudo enviar: $error';
  }

  @override
  String get send => 'Enviar';

  @override
  String get healthCheckupStatus => 'Estado del reconocimiento';

  @override
  String get observations => 'Observaciones';

  @override
  String get recommendations => 'Recomendaciones';

  @override
  String get notCompleted => 'No realizado';

  @override
  String get fit => 'Apto';

  @override
  String get fitWithLimitations => 'Apto con limitaciones';

  @override
  String get notFit => 'No apto';

  @override
  String get loadingMaintenance => 'Cargando mantenimiento...';

  @override
  String get couldNotLoadMaintenance => 'No se pudo cargar mantenimiento';

  @override
  String get openRequests => 'Solicitudes abiertas';

  @override
  String get linkedEquipment => 'Equipos vinculados';

  @override
  String get pendingInterventions => 'Pendientes de intervención';

  @override
  String get maintenanceInfo =>
      'La vista usa las solicitudes de mantenimiento y el enlace real con los equipos de calidad.';

  @override
  String get editingAllowedInOdoo => 'Edición permitida en Odoo';

  @override
  String get readOnly => 'Solo lectura';

  @override
  String get requests => 'Solicitudes';

  @override
  String get noRequests => 'Sin solicitudes';

  @override
  String get noRequestsHint =>
      'No hay solicitudes de mantenimiento visibles para este usuario.';

  @override
  String get unlinkedEquipment => 'Equipo no vinculado';

  @override
  String get noResponsible => 'Sin responsable';

  @override
  String get closedFeminine => 'Cerrada';

  @override
  String get openFeminine => 'Abierta';

  @override
  String get maintenanceRequest => 'Solicitud de mantenimiento';

  @override
  String qualityEquipment(String name) {
    return 'Equipo de calidad: $name';
  }

  @override
  String responsible(String name) {
    return 'Responsable: $name';
  }

  @override
  String requestScheduleClose(String request, String scheduled, String closed) {
    return 'Solicitud: $request\nProgramada: $scheduled\nCierre: $closed';
  }

  @override
  String get noLinkedEquipment => 'Sin equipos enlazados';

  @override
  String get noLinkedEquipmentHint =>
      'Todavía no hay equipos de calidad sincronizados con mantenimiento.';

  @override
  String get interventionRequired => 'Requiere intervención';

  @override
  String get controlled => 'Controlado';

  @override
  String code(String code) {
    return 'Código: $code';
  }

  @override
  String equipmentStatus(String status) {
    return 'Estado: $status';
  }

  @override
  String unitLabel(String name) {
    return 'Unidad: $name';
  }

  @override
  String get linkedToMaintenance => 'Vinculado a mantenimiento';

  @override
  String get noLink => 'Sin vínculo';

  @override
  String openCount(String count) {
    return '$count abiertas';
  }

  @override
  String totalCount(String count) {
    return '$count totales';
  }

  @override
  String lastRequest(String date) {
    return 'Última solicitud: $date';
  }

  @override
  String get preventive => 'Preventivo';

  @override
  String get corrective => 'Correctivo';

  @override
  String get noType => 'Sin tipo';

  @override
  String get operational => 'Operativo';

  @override
  String get broken => 'Averiado';

  @override
  String get retired => 'Retirado';
}
