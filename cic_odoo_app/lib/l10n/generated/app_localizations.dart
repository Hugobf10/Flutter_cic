import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
  ];

  /// No description provided for @accessibility.
  ///
  /// In es, this message translates to:
  /// **'Accesibilidad'**
  String get accessibility;

  /// No description provided for @readingVision.
  ///
  /// In es, this message translates to:
  /// **'Lectura y visión'**
  String get readingVision;

  /// No description provided for @readingVisionHint.
  ///
  /// In es, this message translates to:
  /// **'Ajusta la interfaz a tus necesidades visuales.'**
  String get readingVisionHint;

  /// No description provided for @textSize.
  ///
  /// In es, this message translates to:
  /// **'Tamaño del texto'**
  String get textSize;

  /// No description provided for @textSizeHint.
  ///
  /// In es, this message translates to:
  /// **'Se combina con el ajuste del dispositivo.'**
  String get textSizeHint;

  /// No description provided for @boldText.
  ///
  /// In es, this message translates to:
  /// **'Texto reforzado'**
  String get boldText;

  /// No description provided for @boldTextHint.
  ///
  /// In es, this message translates to:
  /// **'Aumenta el grosor del texto para facilitar la lectura.'**
  String get boldTextHint;

  /// No description provided for @highContrast.
  ///
  /// In es, this message translates to:
  /// **'Alto contraste'**
  String get highContrast;

  /// No description provided for @highContrastHint.
  ///
  /// In es, this message translates to:
  /// **'Refuerza fondos, bordes y textos.'**
  String get highContrastHint;

  /// No description provided for @movement.
  ///
  /// In es, this message translates to:
  /// **'Movimiento'**
  String get movement;

  /// No description provided for @movementHint.
  ///
  /// In es, this message translates to:
  /// **'Reduce efectos que puedan causar mareo o distracción.'**
  String get movementHint;

  /// No description provided for @reduceMotion.
  ///
  /// In es, this message translates to:
  /// **'Reducir animaciones'**
  String get reduceMotion;

  /// No description provided for @reduceMotionHint.
  ///
  /// In es, this message translates to:
  /// **'Desactiva las transiciones y las entradas animadas.'**
  String get reduceMotionHint;

  /// No description provided for @preview.
  ///
  /// In es, this message translates to:
  /// **'Vista previa'**
  String get preview;

  /// No description provided for @previewSuccess.
  ///
  /// In es, this message translates to:
  /// **'Completado'**
  String get previewSuccess;

  /// No description provided for @previewWarning.
  ///
  /// In es, this message translates to:
  /// **'Pendiente'**
  String get previewWarning;

  /// No description provided for @previewText.
  ///
  /// In es, this message translates to:
  /// **'Comprueba aquí el tamaño, el grosor y el contraste seleccionados.'**
  String get previewText;

  /// No description provided for @resetAccessibility.
  ///
  /// In es, this message translates to:
  /// **'Restablecer accesibilidad'**
  String get resetAccessibility;

  /// No description provided for @colorSupport.
  ///
  /// In es, this message translates to:
  /// **'Distinción de colores'**
  String get colorSupport;

  /// No description provided for @colorSupportHint.
  ///
  /// In es, this message translates to:
  /// **'Los estados incluyen texto e iconos. Puedes activar una paleta azul y naranja si te cuesta distinguir el rojo y el verde.'**
  String get colorSupportHint;

  /// No description provided for @alternativeColors.
  ///
  /// In es, this message translates to:
  /// **'Paleta azul y naranja'**
  String get alternativeColors;

  /// No description provided for @screenReader.
  ///
  /// In es, this message translates to:
  /// **'Lector de pantalla'**
  String get screenReader;

  /// No description provided for @screenReaderHint.
  ///
  /// In es, this message translates to:
  /// **'Para navegación hablada, activa VoiceOver en los ajustes de accesibilidad de iPhone o TalkBack en Android. No necesitas activar un modo especial en esta app.'**
  String get screenReaderHint;

  /// No description provided for @language.
  ///
  /// In es, this message translates to:
  /// **'Idioma'**
  String get language;

  /// No description provided for @languageHint.
  ///
  /// In es, this message translates to:
  /// **'Idioma de la interfaz. Los contenidos enviados por otras personas conservan su idioma original.'**
  String get languageHint;

  /// No description provided for @systemLanguage.
  ///
  /// In es, this message translates to:
  /// **'Idioma del dispositivo'**
  String get systemLanguage;

  /// No description provided for @languageProgress.
  ///
  /// In es, this message translates to:
  /// **'La traducción al inglés se está completando; algunos módulos todavía aparecen en español.'**
  String get languageProgress;

  /// No description provided for @home.
  ///
  /// In es, this message translates to:
  /// **'Inicio'**
  String get home;

  /// No description provided for @modules.
  ///
  /// In es, this message translates to:
  /// **'Módulos'**
  String get modules;

  /// No description provided for @activity.
  ///
  /// In es, this message translates to:
  /// **'Actividad'**
  String get activity;

  /// No description provided for @profile.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get profile;

  /// No description provided for @myProfile.
  ///
  /// In es, this message translates to:
  /// **'Mi perfil'**
  String get myProfile;

  /// No description provided for @preferences.
  ///
  /// In es, this message translates to:
  /// **'Preferencias'**
  String get preferences;

  /// No description provided for @preferencesHint.
  ///
  /// In es, this message translates to:
  /// **'Apariencia y necesidades de acceso'**
  String get preferencesHint;

  /// No description provided for @accessibilityHint.
  ///
  /// In es, this message translates to:
  /// **'Texto, contraste y reducción de movimiento'**
  String get accessibilityHint;

  /// No description provided for @darkMode.
  ///
  /// In es, this message translates to:
  /// **'Modo oscuro'**
  String get darkMode;

  /// No description provided for @darkModeHint.
  ///
  /// In es, this message translates to:
  /// **'Alternar tema claro / oscuro'**
  String get darkModeHint;

  /// No description provided for @logout.
  ///
  /// In es, this message translates to:
  /// **'Cerrar sesión'**
  String get logout;

  /// No description provided for @personalInfo.
  ///
  /// In es, this message translates to:
  /// **'Información personal'**
  String get personalInfo;

  /// No description provided for @basicProfile.
  ///
  /// In es, this message translates to:
  /// **'Datos básicos del perfil'**
  String get basicProfile;

  /// No description provided for @phone.
  ///
  /// In es, this message translates to:
  /// **'Teléfono'**
  String get phone;

  /// No description provided for @mobile.
  ///
  /// In es, this message translates to:
  /// **'Móvil'**
  String get mobile;

  /// No description provided for @position.
  ///
  /// In es, this message translates to:
  /// **'Puesto'**
  String get position;

  /// No description provided for @documentation.
  ///
  /// In es, this message translates to:
  /// **'Documentación'**
  String get documentation;

  /// No description provided for @retry.
  ///
  /// In es, this message translates to:
  /// **'Reintentar'**
  String get retry;

  /// No description provided for @profileError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el perfil'**
  String get profileError;

  /// No description provided for @view.
  ///
  /// In es, this message translates to:
  /// **'Ver'**
  String get view;

  /// No description provided for @noCv.
  ///
  /// In es, this message translates to:
  /// **'No hay CV cargado'**
  String get noCv;

  /// No description provided for @backToTop.
  ///
  /// In es, this message translates to:
  /// **'Volver arriba'**
  String get backToTop;

  /// No description provided for @quickActions.
  ///
  /// In es, this message translates to:
  /// **'Accesos rápidos'**
  String get quickActions;

  /// No description provided for @editProfile.
  ///
  /// In es, this message translates to:
  /// **'Editar perfil'**
  String get editProfile;

  /// No description provided for @explore.
  ///
  /// In es, this message translates to:
  /// **'Explorar'**
  String get explore;

  /// No description provided for @availableModules.
  ///
  /// In es, this message translates to:
  /// **'Módulos disponibles'**
  String get availableModules;

  /// No description provided for @availableModulesHint.
  ///
  /// In es, this message translates to:
  /// **'Solo ves las áreas habilitadas para tu perfil en Odoo.'**
  String get availableModulesHint;

  /// No description provided for @searchModules.
  ///
  /// In es, this message translates to:
  /// **'Buscar módulos...'**
  String get searchModules;

  /// No description provided for @modulesAvailable.
  ///
  /// In es, this message translates to:
  /// **'{count} módulos disponibles'**
  String modulesAvailable(int count);

  /// No description provided for @modulesLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar el catálogo de módulos para este perfil.'**
  String get modulesLoadError;

  /// No description provided for @all.
  ///
  /// In es, this message translates to:
  /// **'Todas'**
  String get all;

  /// No description provided for @unread.
  ///
  /// In es, this message translates to:
  /// **'No leídas'**
  String get unread;

  /// No description provided for @important.
  ///
  /// In es, this message translates to:
  /// **'Importantes'**
  String get important;

  /// No description provided for @loadingActivity.
  ///
  /// In es, this message translates to:
  /// **'Cargando actividad...'**
  String get loadingActivity;

  /// No description provided for @noActivity.
  ///
  /// In es, this message translates to:
  /// **'Sin actividad'**
  String get noActivity;

  /// No description provided for @noActivityHint.
  ///
  /// In es, this message translates to:
  /// **'No hay notificaciones para este filtro.'**
  String get noActivityHint;

  /// No description provided for @activityCentre.
  ///
  /// In es, this message translates to:
  /// **'Centro de actividad'**
  String get activityCentre;

  /// No description provided for @activityCentreHint.
  ///
  /// In es, this message translates to:
  /// **'Lo reciente, importante y pendiente de revisar.'**
  String get activityCentreHint;

  /// No description provided for @total.
  ///
  /// In es, this message translates to:
  /// **'Total'**
  String get total;

  /// No description provided for @recentActivity.
  ///
  /// In es, this message translates to:
  /// **'Actividad reciente'**
  String get recentActivity;

  /// No description provided for @viewAll.
  ///
  /// In es, this message translates to:
  /// **'Ver todo'**
  String get viewAll;

  /// No description provided for @viewAllModules.
  ///
  /// In es, this message translates to:
  /// **'Ver todos'**
  String get viewAllModules;

  /// No description provided for @summary.
  ///
  /// In es, this message translates to:
  /// **'Aquí tienes un resumen de lo importante.'**
  String get summary;

  /// No description provided for @goodMorning.
  ///
  /// In es, this message translates to:
  /// **'Buenos días'**
  String get goodMorning;

  /// No description provided for @goodAfternoon.
  ///
  /// In es, this message translates to:
  /// **'Buenas tardes'**
  String get goodAfternoon;

  /// No description provided for @goodEvening.
  ///
  /// In es, this message translates to:
  /// **'Buenas noches'**
  String get goodEvening;

  /// No description provided for @incidents.
  ///
  /// In es, this message translates to:
  /// **'Incidencias'**
  String get incidents;

  /// No description provided for @reservations.
  ///
  /// In es, this message translates to:
  /// **'Reservas'**
  String get reservations;

  /// No description provided for @training.
  ///
  /// In es, this message translates to:
  /// **'Formación'**
  String get training;

  /// No description provided for @open.
  ///
  /// In es, this message translates to:
  /// **'Abiertas'**
  String get open;

  /// No description provided for @today.
  ///
  /// In es, this message translates to:
  /// **'Hoy'**
  String get today;

  /// No description provided for @pending.
  ///
  /// In es, this message translates to:
  /// **'Pendientes'**
  String get pending;

  /// No description provided for @upToDate.
  ///
  /// In es, this message translates to:
  /// **'Todo al día'**
  String get upToDate;

  /// No description provided for @upToDateHint.
  ///
  /// In es, this message translates to:
  /// **'No hay indicadores disponibles para este perfil.'**
  String get upToDateHint;

  /// No description provided for @unknownError.
  ///
  /// In es, this message translates to:
  /// **'Error desconocido'**
  String get unknownError;

  /// No description provided for @communications.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones'**
  String get communications;

  /// No description provided for @suggestions.
  ///
  /// In es, this message translates to:
  /// **'Sugerencias'**
  String get suggestions;

  /// No description provided for @couldNotLoadCommunications.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las comunicaciones'**
  String get couldNotLoadCommunications;

  /// No description provided for @createCommunication.
  ///
  /// In es, this message translates to:
  /// **'Crear comunicación'**
  String get createCommunication;

  /// No description provided for @communication.
  ///
  /// In es, this message translates to:
  /// **'Comunicación'**
  String get communication;

  /// No description provided for @suggestion.
  ///
  /// In es, this message translates to:
  /// **'Sugerencia'**
  String get suggestion;

  /// No description provided for @title.
  ///
  /// In es, this message translates to:
  /// **'Título'**
  String get title;

  /// No description provided for @type.
  ///
  /// In es, this message translates to:
  /// **'Tipo'**
  String get type;

  /// No description provided for @date.
  ///
  /// In es, this message translates to:
  /// **'Fecha'**
  String get date;

  /// No description provided for @description.
  ///
  /// In es, this message translates to:
  /// **'Descripción'**
  String get description;

  /// No description provided for @recipientUnits.
  ///
  /// In es, this message translates to:
  /// **'Unidades destinatarias'**
  String get recipientUnits;

  /// No description provided for @recipientRoles.
  ///
  /// In es, this message translates to:
  /// **'Puestos funcionales destinatarios'**
  String get recipientRoles;

  /// No description provided for @unit.
  ///
  /// In es, this message translates to:
  /// **'Unidad'**
  String get unit;

  /// No description provided for @role.
  ///
  /// In es, this message translates to:
  /// **'Puesto funcional'**
  String get role;

  /// No description provided for @couldNotLoadRecipients.
  ///
  /// In es, this message translates to:
  /// **'No se pueden cargar los destinatarios'**
  String get couldNotLoadRecipients;

  /// No description provided for @couldNotRunAction.
  ///
  /// In es, this message translates to:
  /// **'No se pudo ejecutar la acción'**
  String get couldNotRunAction;

  /// No description provided for @analyse.
  ///
  /// In es, this message translates to:
  /// **'Analizar'**
  String get analyse;

  /// No description provided for @markHandled.
  ///
  /// In es, this message translates to:
  /// **'Marcar tratada'**
  String get markHandled;

  /// No description provided for @close.
  ///
  /// In es, this message translates to:
  /// **'Cerrar'**
  String get close;

  /// No description provided for @received.
  ///
  /// In es, this message translates to:
  /// **'Recibida'**
  String get received;

  /// No description provided for @inAnalysis.
  ///
  /// In es, this message translates to:
  /// **'En análisis'**
  String get inAnalysis;

  /// No description provided for @handled.
  ///
  /// In es, this message translates to:
  /// **'Tratada'**
  String get handled;

  /// No description provided for @answered.
  ///
  /// In es, this message translates to:
  /// **'Respondida'**
  String get answered;

  /// No description provided for @closed.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get closed;

  /// No description provided for @newReservation.
  ///
  /// In es, this message translates to:
  /// **'Nueva reserva'**
  String get newReservation;

  /// No description provided for @myReservations.
  ///
  /// In es, this message translates to:
  /// **'Mis reservas'**
  String get myReservations;

  /// No description provided for @dailyAgenda.
  ///
  /// In es, this message translates to:
  /// **'Agenda diaria'**
  String get dailyAgenda;

  /// No description provided for @quickReservation.
  ///
  /// In es, this message translates to:
  /// **'Reserva rápida'**
  String get quickReservation;

  /// No description provided for @quickReservationHint.
  ///
  /// In es, this message translates to:
  /// **'Selecciona servicio, recurso y horario en 4 pasos'**
  String get quickReservationHint;

  /// No description provided for @reservationUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Reserva no disponible'**
  String get reservationUnavailable;

  /// No description provided for @reservationUnavailableHint.
  ///
  /// In es, this message translates to:
  /// **'Este usuario puede consultar reservas, pero no crear nuevas desde la app.'**
  String get reservationUnavailableHint;

  /// No description provided for @couldNotLoadReservations.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las reservas'**
  String get couldNotLoadReservations;

  /// No description provided for @scanReservationQr.
  ///
  /// In es, this message translates to:
  /// **'Escanear QR de sala o equipo'**
  String get scanReservationQr;

  /// No description provided for @records.
  ///
  /// In es, this message translates to:
  /// **'{count} registros'**
  String records(int count);

  /// No description provided for @noReservations.
  ///
  /// In es, this message translates to:
  /// **'Sin reservas'**
  String get noReservations;

  /// No description provided for @noReservationsHint.
  ///
  /// In es, this message translates to:
  /// **'No tienes reservas registradas.'**
  String get noReservationsHint;

  /// No description provided for @agendaVisible.
  ///
  /// In es, this message translates to:
  /// **'{count} reservas visibles el {date}'**
  String agendaVisible(int count, String date);

  /// No description provided for @noReservationsDay.
  ///
  /// In es, this message translates to:
  /// **'Sin reservas este día'**
  String get noReservationsDay;

  /// No description provided for @noReservationsDayHint.
  ///
  /// In es, this message translates to:
  /// **'No hay reservas disponibles para consultar en la fecha seleccionada.'**
  String get noReservationsDayHint;

  /// No description provided for @limitedReservations.
  ///
  /// In es, this message translates to:
  /// **'Reservas con acceso limitado'**
  String get limitedReservations;

  /// No description provided for @back.
  ///
  /// In es, this message translates to:
  /// **'Atrás'**
  String get back;

  /// No description provided for @next.
  ///
  /// In es, this message translates to:
  /// **'Siguiente'**
  String get next;

  /// No description provided for @createDraft.
  ///
  /// In es, this message translates to:
  /// **'Crear borrador'**
  String get createDraft;

  /// No description provided for @saveChanges.
  ///
  /// In es, this message translates to:
  /// **'Guardar cambios'**
  String get saveChanges;

  /// No description provided for @creating.
  ///
  /// In es, this message translates to:
  /// **'Creando...'**
  String get creating;

  /// No description provided for @saving.
  ///
  /// In es, this message translates to:
  /// **'Guardando...'**
  String get saving;

  /// No description provided for @edit.
  ///
  /// In es, this message translates to:
  /// **'Editar'**
  String get edit;

  /// No description provided for @confirm.
  ///
  /// In es, this message translates to:
  /// **'Confirmar'**
  String get confirm;

  /// No description provided for @cancel.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancel;

  /// No description provided for @editingDraft.
  ///
  /// In es, this message translates to:
  /// **'Editando borrador'**
  String get editingDraft;

  /// No description provided for @reason.
  ///
  /// In es, this message translates to:
  /// **'Motivo'**
  String get reason;

  /// No description provided for @requester.
  ///
  /// In es, this message translates to:
  /// **'Solicitante'**
  String get requester;

  /// No description provided for @access.
  ///
  /// In es, this message translates to:
  /// **'Acceso'**
  String get access;

  /// No description provided for @limitedReservationsHint.
  ///
  /// In es, this message translates to:
  /// **'Este perfil está en modo de consulta dentro de la app. Puede revisar sus reservas y la agenda diaria, pero no crear ni editar nuevas reservas con sus permisos actuales.'**
  String get limitedReservationsHint;

  /// No description provided for @service.
  ///
  /// In es, this message translates to:
  /// **'Servicio'**
  String get service;

  /// No description provided for @resource.
  ///
  /// In es, this message translates to:
  /// **'Recurso'**
  String get resource;

  /// No description provided for @schedule.
  ///
  /// In es, this message translates to:
  /// **'Horario'**
  String get schedule;

  /// No description provided for @duration.
  ///
  /// In es, this message translates to:
  /// **'Duración'**
  String get duration;

  /// No description provided for @sessionType.
  ///
  /// In es, this message translates to:
  /// **'Tipo de sesión'**
  String get sessionType;

  /// No description provided for @reasonOptional.
  ///
  /// In es, this message translates to:
  /// **'Motivo (opcional)'**
  String get reasonOptional;

  /// No description provided for @availableHours.
  ///
  /// In es, this message translates to:
  /// **'Horas disponibles'**
  String get availableHours;

  /// No description provided for @selectedResource.
  ///
  /// In es, this message translates to:
  /// **'Recurso seleccionado: {name}'**
  String selectedResource(String name);

  /// No description provided for @selectService.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un servicio para continuar.'**
  String get selectService;

  /// No description provided for @selectResource.
  ///
  /// In es, this message translates to:
  /// **'Selecciona un recurso para continuar.'**
  String get selectResource;

  /// No description provided for @selectTimeSlot.
  ///
  /// In es, this message translates to:
  /// **'Selecciona una franja horaria para continuar.'**
  String get selectTimeSlot;

  /// No description provided for @reservationUpdated.
  ///
  /// In es, this message translates to:
  /// **'Reserva actualizada. Confírmala cuando esté lista.'**
  String get reservationUpdated;

  /// No description provided for @draftCreated.
  ///
  /// In es, this message translates to:
  /// **'Reserva creada en borrador. Revísala y confírmala cuando esté lista.'**
  String get draftCreated;

  /// No description provided for @reservationConfirmed.
  ///
  /// In es, this message translates to:
  /// **'Reserva confirmada.'**
  String get reservationConfirmed;

  /// No description provided for @reservationCancelled.
  ///
  /// In es, this message translates to:
  /// **'Reserva cancelada.'**
  String get reservationCancelled;

  /// No description provided for @draft.
  ///
  /// In es, this message translates to:
  /// **'Borrador'**
  String get draft;

  /// No description provided for @confirmed.
  ///
  /// In es, this message translates to:
  /// **'Confirmada'**
  String get confirmed;

  /// No description provided for @cancelled.
  ///
  /// In es, this message translates to:
  /// **'Cancelada'**
  String get cancelled;

  /// No description provided for @reservation.
  ///
  /// In es, this message translates to:
  /// **'Reserva'**
  String get reservation;

  /// No description provided for @billed.
  ///
  /// In es, this message translates to:
  /// **'Facturada'**
  String get billed;

  /// No description provided for @searchDocuments.
  ///
  /// In es, this message translates to:
  /// **'Buscar documentos...'**
  String get searchDocuments;

  /// No description provided for @documentsLimitedAccess.
  ///
  /// In es, this message translates to:
  /// **'Documentos con acceso limitado'**
  String get documentsLimitedAccess;

  /// No description provided for @documentsLimitedAccessHint.
  ///
  /// In es, this message translates to:
  /// **'Este perfil no puede consultar el listado completo de documentos por API con sus permisos actuales.'**
  String get documentsLimitedAccessHint;

  /// No description provided for @couldNotLoadDocuments.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar documentos'**
  String get couldNotLoadDocuments;

  /// No description provided for @noDocuments.
  ///
  /// In es, this message translates to:
  /// **'Sin documentos'**
  String get noDocuments;

  /// No description provided for @noDocumentsHint.
  ///
  /// In es, this message translates to:
  /// **'No se han encontrado resultados para esta búsqueda.'**
  String get noDocumentsHint;

  /// No description provided for @documentsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} documentos'**
  String documentsCount(int count);

  /// No description provided for @versions.
  ///
  /// In es, this message translates to:
  /// **'{count} versiones'**
  String versions(int count);

  /// No description provided for @document.
  ///
  /// In es, this message translates to:
  /// **'Documento'**
  String get document;

  /// No description provided for @documentWithoutAttachment.
  ///
  /// In es, this message translates to:
  /// **'Documento sin versión adjunta.'**
  String get documentWithoutAttachment;

  /// No description provided for @couldNotOpenDocument.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el documento'**
  String get couldNotOpenDocument;

  /// No description provided for @couldNotDownload.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar'**
  String get couldNotDownload;

  /// No description provided for @createIncident.
  ///
  /// In es, this message translates to:
  /// **'Crear incidencia'**
  String get createIncident;

  /// No description provided for @nonConformity.
  ///
  /// In es, this message translates to:
  /// **'No conformidad'**
  String get nonConformity;

  /// No description provided for @improvementOpportunity.
  ///
  /// In es, this message translates to:
  /// **'Oportunidad de mejora'**
  String get improvementOpportunity;

  /// No description provided for @category.
  ///
  /// In es, this message translates to:
  /// **'Categoría'**
  String get category;

  /// No description provided for @quality.
  ///
  /// In es, this message translates to:
  /// **'Calidad'**
  String get quality;

  /// No description provided for @healthSafety.
  ///
  /// In es, this message translates to:
  /// **'PRL'**
  String get healthSafety;

  /// No description provided for @subtype.
  ///
  /// In es, this message translates to:
  /// **'Subtipo'**
  String get subtype;

  /// No description provided for @internal.
  ///
  /// In es, this message translates to:
  /// **'Interna'**
  String get internal;

  /// No description provided for @supplier.
  ///
  /// In es, this message translates to:
  /// **'Proveedor'**
  String get supplier;

  /// No description provided for @audit.
  ///
  /// In es, this message translates to:
  /// **'Auditoría'**
  String get audit;

  /// No description provided for @claim.
  ///
  /// In es, this message translates to:
  /// **'Reclamación'**
  String get claim;

  /// No description provided for @other.
  ///
  /// In es, this message translates to:
  /// **'Otra'**
  String get other;

  /// No description provided for @openPlural.
  ///
  /// In es, this message translates to:
  /// **'Abiertas'**
  String get openPlural;

  /// No description provided for @inProgress.
  ///
  /// In es, this message translates to:
  /// **'En proceso'**
  String get inProgress;

  /// No description provided for @closedPlural.
  ///
  /// In es, this message translates to:
  /// **'Cerradas'**
  String get closedPlural;

  /// No description provided for @noIncidents.
  ///
  /// In es, this message translates to:
  /// **'No hay incidencias.'**
  String get noIncidents;

  /// No description provided for @incidentsCount.
  ///
  /// In es, this message translates to:
  /// **'{count} incidencias'**
  String incidentsCount(int count);

  /// No description provided for @incidentsUnitHint.
  ///
  /// In es, this message translates to:
  /// **'De tu unidad, ordenadas por fecha'**
  String get incidentsUnitHint;

  /// No description provided for @signInTitle.
  ///
  /// In es, this message translates to:
  /// **'Accede a tu espacio'**
  String get signInTitle;

  /// No description provided for @signInHint.
  ///
  /// In es, this message translates to:
  /// **'Usa las mismas credenciales que en Odoo Web.'**
  String get signInHint;

  /// No description provided for @corporateEmail.
  ///
  /// In es, this message translates to:
  /// **'Correo corporativo'**
  String get corporateEmail;

  /// No description provided for @enterCorporateEmail.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu correo corporativo'**
  String get enterCorporateEmail;

  /// No description provided for @password.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get password;

  /// No description provided for @enterPassword.
  ///
  /// In es, this message translates to:
  /// **'Introduce tu contraseña'**
  String get enterPassword;

  /// No description provided for @showPassword.
  ///
  /// In es, this message translates to:
  /// **'Mostrar contraseña'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In es, this message translates to:
  /// **'Ocultar contraseña'**
  String get hidePassword;

  /// No description provided for @verifying.
  ///
  /// In es, this message translates to:
  /// **'Verificando'**
  String get verifying;

  /// No description provided for @signIn.
  ///
  /// In es, this message translates to:
  /// **'Entrar'**
  String get signIn;

  /// No description provided for @encryptedSession.
  ///
  /// In es, this message translates to:
  /// **'Sesión cifrada y permisos sincronizados con Odoo.'**
  String get encryptedSession;

  /// No description provided for @supportConfiguration.
  ///
  /// In es, this message translates to:
  /// **'Configuración de soporte'**
  String get supportConfiguration;

  /// No description provided for @authorisedServer.
  ///
  /// In es, this message translates to:
  /// **'Servidor autorizado'**
  String get authorisedServer;

  /// No description provided for @authorisedEnvironment.
  ///
  /// In es, this message translates to:
  /// **'Entorno autorizado'**
  String get authorisedEnvironment;

  /// No description provided for @enterAuthorisedServer.
  ///
  /// In es, this message translates to:
  /// **'Introduce el servidor autorizado'**
  String get enterAuthorisedServer;

  /// No description provided for @enterAuthorisedEnvironment.
  ///
  /// In es, this message translates to:
  /// **'Introduce el entorno autorizado'**
  String get enterAuthorisedEnvironment;

  /// No description provided for @useLightMode.
  ///
  /// In es, this message translates to:
  /// **'Usar modo claro'**
  String get useLightMode;

  /// No description provided for @useDarkMode.
  ///
  /// In es, this message translates to:
  /// **'Usar modo oscuro'**
  String get useDarkMode;

  /// No description provided for @yourCicSpace.
  ///
  /// In es, this message translates to:
  /// **'Tu espacio CIC'**
  String get yourCicSpace;

  /// No description provided for @brandHint.
  ///
  /// In es, this message translates to:
  /// **'Información, gestiones y seguimiento conectados con tu perfil.'**
  String get brandHint;

  /// No description provided for @privacyTitle.
  ///
  /// In es, this message translates to:
  /// **'Privacidad desde el primer paso'**
  String get privacyTitle;

  /// No description provided for @privacyHint.
  ///
  /// In es, this message translates to:
  /// **'Antes de identificarte no cargamos avisos, datos personales ni información de Odoo. Después verás solo lo autorizado para tu perfil.'**
  String get privacyHint;

  /// No description provided for @signInHelpTitle.
  ///
  /// In es, this message translates to:
  /// **'¿Problemas para entrar? '**
  String get signInHelpTitle;

  /// No description provided for @signInHelpHint.
  ///
  /// In es, this message translates to:
  /// **'Comprueba tus credenciales habituales y, si continúa, contacta con el responsable de tu cuenta CIC.'**
  String get signInHelpHint;

  /// No description provided for @accessVerificationFailed.
  ///
  /// In es, this message translates to:
  /// **'No hemos podido verificar el acceso'**
  String get accessVerificationFailed;

  /// No description provided for @loginValueOneTitle.
  ///
  /// In es, this message translates to:
  /// **'Todo lo importante, ordenado'**
  String get loginValueOneTitle;

  /// No description provided for @loginValueOneHint.
  ///
  /// In es, this message translates to:
  /// **'Documentos, noticias, actividad y accesos en un mismo inicio.'**
  String get loginValueOneHint;

  /// No description provided for @loginValueTwoTitle.
  ///
  /// In es, this message translates to:
  /// **'Gestiones conectadas'**
  String get loginValueTwoTitle;

  /// No description provided for @loginValueTwoHint.
  ///
  /// In es, this message translates to:
  /// **'Reservas, incidencias y procesos actualizados con Odoo.'**
  String get loginValueTwoHint;

  /// No description provided for @loginValueThreeTitle.
  ///
  /// In es, this message translates to:
  /// **'Acceso según tu perfil'**
  String get loginValueThreeTitle;

  /// No description provided for @loginValueThreeHint.
  ///
  /// In es, this message translates to:
  /// **'Cada persona ve únicamente los módulos que tiene autorizados.'**
  String get loginValueThreeHint;

  /// No description provided for @recruitment.
  ///
  /// In es, this message translates to:
  /// **'Reclutamiento'**
  String get recruitment;

  /// No description provided for @error.
  ///
  /// In es, this message translates to:
  /// **'Error'**
  String get error;

  /// No description provided for @vacancies.
  ///
  /// In es, this message translates to:
  /// **'Vacantes'**
  String get vacancies;

  /// No description provided for @applications.
  ///
  /// In es, this message translates to:
  /// **'Candidaturas'**
  String get applications;

  /// No description provided for @noVacancies.
  ///
  /// In es, this message translates to:
  /// **'Sin vacantes'**
  String get noVacancies;

  /// No description provided for @noVacanciesHint.
  ///
  /// In es, this message translates to:
  /// **'No hay posiciones abiertas.'**
  String get noVacanciesHint;

  /// No description provided for @vacancy.
  ///
  /// In es, this message translates to:
  /// **'Vacante'**
  String get vacancy;

  /// No description provided for @department.
  ///
  /// In es, this message translates to:
  /// **'Departamento'**
  String get department;

  /// No description provided for @vacancyCount.
  ///
  /// In es, this message translates to:
  /// **'Vacantes: {count}'**
  String vacancyCount(int count);

  /// No description provided for @noApplications.
  ///
  /// In es, this message translates to:
  /// **'Sin candidaturas'**
  String get noApplications;

  /// No description provided for @noApplicationsHint.
  ///
  /// In es, this message translates to:
  /// **'No hay candidaturas registradas.'**
  String get noApplicationsHint;

  /// No description provided for @candidate.
  ///
  /// In es, this message translates to:
  /// **'Candidato'**
  String get candidate;

  /// No description provided for @job.
  ///
  /// In es, this message translates to:
  /// **'Puesto'**
  String get job;

  /// No description provided for @status.
  ///
  /// In es, this message translates to:
  /// **'Estado'**
  String get status;

  /// No description provided for @linkedApplications.
  ///
  /// In es, this message translates to:
  /// **'{count} candidaturas vinculadas'**
  String linkedApplications(int count);

  /// No description provided for @noVisibleApplicationsHint.
  ///
  /// In es, this message translates to:
  /// **'Esta vacante no tiene candidaturas visibles.'**
  String get noVisibleApplicationsHint;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Correo electrónico'**
  String get email;

  /// No description provided for @providedDocuments.
  ///
  /// In es, this message translates to:
  /// **'Documentación aportada'**
  String get providedDocuments;

  /// No description provided for @documentsReadOnlyHint.
  ///
  /// In es, this message translates to:
  /// **'Consulta en modo lectura. No se permite descargar ni compartir archivos.'**
  String get documentsReadOnlyHint;

  /// No description provided for @noCandidateDocuments.
  ///
  /// In es, this message translates to:
  /// **'Sin documentación'**
  String get noCandidateDocuments;

  /// No description provided for @noCandidateDocumentsHint.
  ///
  /// In es, this message translates to:
  /// **'La candidatura no tiene documentos disponibles.'**
  String get noCandidateDocumentsHint;

  /// No description provided for @couldNotPreviewDocument.
  ///
  /// In es, this message translates to:
  /// **'No se pudo visualizar el documento'**
  String get couldNotPreviewDocument;

  /// No description provided for @trainingHistory.
  ///
  /// In es, this message translates to:
  /// **'Historial'**
  String get trainingHistory;

  /// No description provided for @trainingLoadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar la formación'**
  String get trainingLoadError;

  /// No description provided for @trainingLimitedAccess.
  ///
  /// In es, this message translates to:
  /// **'Formación con acceso limitado'**
  String get trainingLimitedAccess;

  /// No description provided for @trainingLimitedAccessHint.
  ///
  /// In es, this message translates to:
  /// **'Este perfil no puede consultar el historial completo de formaciones por API con sus permisos actuales.'**
  String get trainingLimitedAccessHint;

  /// No description provided for @trainingLimitedModeHint.
  ///
  /// In es, this message translates to:
  /// **'La app sigue disponible en modo limitado. Si este perfil debe consultar el historial o certificados, hay que habilitar permisos API de formación en Odoo.'**
  String get trainingLimitedModeHint;

  /// No description provided for @trainingNormalModeHint.
  ///
  /// In es, this message translates to:
  /// **'Registra una formación externa o completa una formación pendiente desde su ficha.'**
  String get trainingNormalModeHint;

  /// No description provided for @noPendingTraining.
  ///
  /// In es, this message translates to:
  /// **'No tienes formación pendiente'**
  String get noPendingTraining;

  /// No description provided for @noPendingTrainingHint.
  ///
  /// In es, this message translates to:
  /// **'Las formaciones asignadas o los cursos e-learning aparecerán aquí.'**
  String get noPendingTrainingHint;

  /// No description provided for @trainingHistoryUnavailable.
  ///
  /// In es, this message translates to:
  /// **'Historial no disponible'**
  String get trainingHistoryUnavailable;

  /// No description provided for @trainingHistoryUnavailableHint.
  ///
  /// In es, this message translates to:
  /// **'Este perfil no puede cargar asistencias de formación por API con sus permisos actuales.'**
  String get trainingHistoryUnavailableHint;

  /// No description provided for @noTrainingHistory.
  ///
  /// In es, this message translates to:
  /// **'Sin historial'**
  String get noTrainingHistory;

  /// No description provided for @noTrainingHistoryHint.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes asistencias de formación.'**
  String get noTrainingHistoryHint;

  /// No description provided for @scheduled.
  ///
  /// In es, this message translates to:
  /// **'Prevista: {date}'**
  String scheduled(String date);

  /// No description provided for @completedOn.
  ///
  /// In es, this message translates to:
  /// **'Realizada: {date}'**
  String completedOn(String date);

  /// No description provided for @hours.
  ///
  /// In es, this message translates to:
  /// **'{count} horas'**
  String hours(String count);

  /// No description provided for @elearningProgress.
  ///
  /// In es, this message translates to:
  /// **'Progreso e-learning: {progress}%'**
  String elearningProgress(String progress);

  /// No description provided for @certificate.
  ///
  /// In es, this message translates to:
  /// **'Certificado'**
  String get certificate;

  /// No description provided for @openCourse.
  ///
  /// In es, this message translates to:
  /// **'Abrir curso'**
  String get openCourse;

  /// No description provided for @markCompleted.
  ///
  /// In es, this message translates to:
  /// **'Marcar realizada'**
  String get markCompleted;

  /// No description provided for @couldNotOpenCertificate.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el certificado: {error}'**
  String couldNotOpenCertificate(String error);

  /// No description provided for @couldNotOpenElearning.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir el curso e-learning.'**
  String get couldNotOpenElearning;

  /// No description provided for @completeTraining.
  ///
  /// In es, this message translates to:
  /// **'Completar formación'**
  String get completeTraining;

  /// No description provided for @change.
  ///
  /// In es, this message translates to:
  /// **'Cambiar'**
  String get change;

  /// No description provided for @attachOptionalCertificate.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar certificado (opcional)'**
  String get attachOptionalCertificate;

  /// No description provided for @upload.
  ///
  /// In es, this message translates to:
  /// **'Subir'**
  String get upload;

  /// No description provided for @confirmCompletion.
  ///
  /// In es, this message translates to:
  /// **'Confirmar realización'**
  String get confirmCompletion;

  /// No description provided for @couldNotCompleteTraining.
  ///
  /// In es, this message translates to:
  /// **'No se pudo completar la formación: {error}'**
  String couldNotCompleteTraining(String error);

  /// No description provided for @registerExternalTraining.
  ///
  /// In es, this message translates to:
  /// **'Registrar formación externa'**
  String get registerExternalTraining;

  /// No description provided for @trainingName.
  ///
  /// In es, this message translates to:
  /// **'Nombre de la formación'**
  String get trainingName;

  /// No description provided for @entityCentre.
  ///
  /// In es, this message translates to:
  /// **'Entidad / centro'**
  String get entityCentre;

  /// No description provided for @completionDate.
  ///
  /// In es, this message translates to:
  /// **'Fecha de finalización'**
  String get completionDate;

  /// No description provided for @choose.
  ///
  /// In es, this message translates to:
  /// **'Elegir'**
  String get choose;

  /// No description provided for @attachCertificate.
  ///
  /// In es, this message translates to:
  /// **'Adjuntar certificado (PDF)'**
  String get attachCertificate;

  /// No description provided for @sendRequest.
  ///
  /// In es, this message translates to:
  /// **'Enviar solicitud'**
  String get sendRequest;

  /// No description provided for @enterTrainingName.
  ///
  /// In es, this message translates to:
  /// **'Indica el nombre de la formación.'**
  String get enterTrainingName;

  /// No description provided for @enterTrainingCompletionDate.
  ///
  /// In es, this message translates to:
  /// **'Indica la fecha de finalización de la formación.'**
  String get enterTrainingCompletionDate;

  /// No description provided for @trainingSubmitted.
  ///
  /// In es, this message translates to:
  /// **'Formación enviada para validación de Calidad.'**
  String get trainingSubmitted;

  /// No description provided for @couldNotRegister.
  ///
  /// In es, this message translates to:
  /// **'No se pudo registrar: {error}'**
  String couldNotRegister(String error);

  /// No description provided for @available.
  ///
  /// In es, this message translates to:
  /// **'Disponible'**
  String get available;

  /// No description provided for @comingSoon.
  ///
  /// In es, this message translates to:
  /// **'Próximamente'**
  String get comingSoon;

  /// No description provided for @security.
  ///
  /// In es, this message translates to:
  /// **'Seguridad'**
  String get security;

  /// No description provided for @informationDelivered.
  ///
  /// In es, this message translates to:
  /// **'Información entregada'**
  String get informationDelivered;

  /// No description provided for @payroll.
  ///
  /// In es, this message translates to:
  /// **'Nóminas'**
  String get payroll;

  /// No description provided for @planning.
  ///
  /// In es, this message translates to:
  /// **'Planificación'**
  String get planning;

  /// No description provided for @healthSurveillance.
  ///
  /// In es, this message translates to:
  /// **'Vigilancia de la salud'**
  String get healthSurveillance;

  /// No description provided for @normative.
  ///
  /// In es, this message translates to:
  /// **'Normativa'**
  String get normative;

  /// No description provided for @equipment.
  ///
  /// In es, this message translates to:
  /// **'Equipos'**
  String get equipment;

  /// No description provided for @publications.
  ///
  /// In es, this message translates to:
  /// **'Publicaciones'**
  String get publications;

  /// No description provided for @permissionsRoles.
  ///
  /// In es, this message translates to:
  /// **'Permisos y roles'**
  String get permissionsRoles;

  /// No description provided for @suppliers.
  ///
  /// In es, this message translates to:
  /// **'Proveedores'**
  String get suppliers;

  /// No description provided for @organisation.
  ///
  /// In es, this message translates to:
  /// **'Organización'**
  String get organisation;

  /// No description provided for @purchases.
  ///
  /// In es, this message translates to:
  /// **'Compras'**
  String get purchases;

  /// No description provided for @maintenance.
  ///
  /// In es, this message translates to:
  /// **'Mantenimiento'**
  String get maintenance;

  /// No description provided for @moduleIncidentsDescription.
  ///
  /// In es, this message translates to:
  /// **'Registro, seguimiento y cierre de incidencias de tu unidad'**
  String get moduleIncidentsDescription;

  /// No description provided for @moduleTrainingDescription.
  ///
  /// In es, this message translates to:
  /// **'Formación presencial y online'**
  String get moduleTrainingDescription;

  /// No description provided for @moduleDocumentsDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta y descarga de documentos disponibles para ti'**
  String get moduleDocumentsDescription;

  /// No description provided for @moduleSecurityDescription.
  ///
  /// In es, this message translates to:
  /// **'Procedimientos y documentación de seguridad'**
  String get moduleSecurityDescription;

  /// No description provided for @moduleInformationDescription.
  ///
  /// In es, this message translates to:
  /// **'Información y documentación entregada al usuario'**
  String get moduleInformationDescription;

  /// No description provided for @modulePayrollDescription.
  ///
  /// In es, this message translates to:
  /// **'Documentos salariales del portal'**
  String get modulePayrollDescription;

  /// No description provided for @moduleRecruitmentDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta de convocatorias y candidaturas asignadas'**
  String get moduleRecruitmentDescription;

  /// No description provided for @moduleReservationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta disponibilidad y gestiona reservas de servicios y recursos'**
  String get moduleReservationsDescription;

  /// No description provided for @modulePlanningDescription.
  ///
  /// In es, this message translates to:
  /// **'Objetivos, planes de acción, químicos e informes'**
  String get modulePlanningDescription;

  /// No description provided for @moduleHealthDescription.
  ///
  /// In es, this message translates to:
  /// **'Seguimiento de vigilancia de la salud'**
  String get moduleHealthDescription;

  /// No description provided for @moduleNormativeDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta de normativa y documentación aplicable'**
  String get moduleNormativeDescription;

  /// No description provided for @moduleEquipmentDescription.
  ///
  /// In es, this message translates to:
  /// **'Inventario y seguimiento de equipos asociados a calidad'**
  String get moduleEquipmentDescription;

  /// No description provided for @modulePublicationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta de publicaciones y contenidos informativos'**
  String get modulePublicationsDescription;

  /// No description provided for @modulePermissionsDescription.
  ///
  /// In es, this message translates to:
  /// **'Roles y aprobaciones internas'**
  String get modulePermissionsDescription;

  /// No description provided for @moduleCommunicationsDescription.
  ///
  /// In es, this message translates to:
  /// **'Comunicaciones, avisos y sugerencias'**
  String get moduleCommunicationsDescription;

  /// No description provided for @moduleSuppliersDescription.
  ///
  /// In es, this message translates to:
  /// **'Gestión y seguimiento de proveedores'**
  String get moduleSuppliersDescription;

  /// No description provided for @moduleOrganisationDescription.
  ///
  /// In es, this message translates to:
  /// **'Pendiente de integrar con estructura organizativa'**
  String get moduleOrganisationDescription;

  /// No description provided for @modulePurchasesDescription.
  ///
  /// In es, this message translates to:
  /// **'Consulta de productos, códigos y recepción de compras'**
  String get modulePurchasesDescription;

  /// No description provided for @moduleMaintenanceDescription.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes de mantenimiento y equipos enlazados con calidad'**
  String get moduleMaintenanceDescription;

  /// No description provided for @goals.
  ///
  /// In es, this message translates to:
  /// **'Objetivos'**
  String get goals;

  /// No description provided for @actionPlans.
  ///
  /// In es, this message translates to:
  /// **'Planes de acción'**
  String get actionPlans;

  /// No description provided for @chemicals.
  ///
  /// In es, this message translates to:
  /// **'Químicos'**
  String get chemicals;

  /// No description provided for @chemicalReport.
  ///
  /// In es, this message translates to:
  /// **'Informe de químicos'**
  String get chemicalReport;

  /// No description provided for @goalsPlanningHint.
  ///
  /// In es, this message translates to:
  /// **'Consulta y edición de objetivos de calidad y PRL.'**
  String get goalsPlanningHint;

  /// No description provided for @actionPlansPlanningHint.
  ///
  /// In es, this message translates to:
  /// **'Acciones preventivas y planes ligados a objetivos.'**
  String get actionPlansPlanningHint;

  /// No description provided for @chemicalsPlanningHint.
  ///
  /// In es, this message translates to:
  /// **'Inventario, peligrosidad, caducidades y fichas.'**
  String get chemicalsPlanningHint;

  /// No description provided for @chemicalReportPlanningHint.
  ///
  /// In es, this message translates to:
  /// **'Resumen operativo por tipo y peligrosidad.'**
  String get chemicalReportPlanningHint;

  /// No description provided for @noAccess.
  ///
  /// In es, this message translates to:
  /// **'Sin acceso'**
  String get noAccess;

  /// No description provided for @noPlanningAccess.
  ///
  /// In es, this message translates to:
  /// **'No tienes permisos para ver ningún apartado de planificación.'**
  String get noPlanningAccess;

  /// No description provided for @searchPayslips.
  ///
  /// In es, this message translates to:
  /// **'Buscar nóminas...'**
  String get searchPayslips;

  /// No description provided for @couldNotLoadPayslips.
  ///
  /// In es, this message translates to:
  /// **'No se pudieron cargar las nóminas'**
  String get couldNotLoadPayslips;

  /// No description provided for @noPayslips.
  ///
  /// In es, this message translates to:
  /// **'Sin nóminas'**
  String get noPayslips;

  /// No description provided for @noPayslipsHint.
  ///
  /// In es, this message translates to:
  /// **'No hay documentos de nómina disponibles.'**
  String get noPayslipsHint;

  /// No description provided for @payslip.
  ///
  /// In es, this message translates to:
  /// **'Nómina'**
  String get payslip;

  /// No description provided for @noDate.
  ///
  /// In es, this message translates to:
  /// **'sin fecha'**
  String get noDate;

  /// No description provided for @couldNotOpen.
  ///
  /// In es, this message translates to:
  /// **'No se pudo abrir: {error}'**
  String couldNotOpen(String error);

  /// No description provided for @documentDownloaded.
  ///
  /// In es, this message translates to:
  /// **'Documento descargado: {path}'**
  String documentDownloaded(String path);

  /// No description provided for @couldNotDownloadError.
  ///
  /// In es, this message translates to:
  /// **'No se pudo descargar: {error}'**
  String couldNotDownloadError(String error);

  /// No description provided for @noHealthForms.
  ///
  /// In es, this message translates to:
  /// **'Sin formularios'**
  String get noHealthForms;

  /// No description provided for @noHealthFormsHint.
  ///
  /// In es, this message translates to:
  /// **'No hay reconocimientos registrados.'**
  String get noHealthFormsHint;

  /// No description provided for @historicalCicCheckup.
  ///
  /// In es, this message translates to:
  /// **'Reconocimiento histórico CIC'**
  String get historicalCicCheckup;

  /// No description provided for @healthCheckup.
  ///
  /// In es, this message translates to:
  /// **'Reconocimiento'**
  String get healthCheckup;

  /// No description provided for @checkupDate.
  ///
  /// In es, this message translates to:
  /// **'Reconocimiento: {date}'**
  String checkupDate(String date);

  /// No description provided for @realisationDate.
  ///
  /// In es, this message translates to:
  /// **'Realización: {date}'**
  String realisationDate(String date);

  /// No description provided for @couldNotSend.
  ///
  /// In es, this message translates to:
  /// **'No se pudo enviar: {error}'**
  String couldNotSend(String error);

  /// No description provided for @send.
  ///
  /// In es, this message translates to:
  /// **'Enviar'**
  String get send;

  /// No description provided for @healthCheckupStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado del reconocimiento'**
  String get healthCheckupStatus;

  /// No description provided for @observations.
  ///
  /// In es, this message translates to:
  /// **'Observaciones'**
  String get observations;

  /// No description provided for @recommendations.
  ///
  /// In es, this message translates to:
  /// **'Recomendaciones'**
  String get recommendations;

  /// No description provided for @notCompleted.
  ///
  /// In es, this message translates to:
  /// **'No realizado'**
  String get notCompleted;

  /// No description provided for @fit.
  ///
  /// In es, this message translates to:
  /// **'Apto'**
  String get fit;

  /// No description provided for @fitWithLimitations.
  ///
  /// In es, this message translates to:
  /// **'Apto con limitaciones'**
  String get fitWithLimitations;

  /// No description provided for @notFit.
  ///
  /// In es, this message translates to:
  /// **'No apto'**
  String get notFit;

  /// No description provided for @loadingMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Cargando mantenimiento...'**
  String get loadingMaintenance;

  /// No description provided for @couldNotLoadMaintenance.
  ///
  /// In es, this message translates to:
  /// **'No se pudo cargar mantenimiento'**
  String get couldNotLoadMaintenance;

  /// No description provided for @openRequests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes abiertas'**
  String get openRequests;

  /// No description provided for @linkedEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipos vinculados'**
  String get linkedEquipment;

  /// No description provided for @pendingInterventions.
  ///
  /// In es, this message translates to:
  /// **'Pendientes de intervención'**
  String get pendingInterventions;

  /// No description provided for @maintenanceInfo.
  ///
  /// In es, this message translates to:
  /// **'La vista usa las solicitudes de mantenimiento y el enlace real con los equipos de calidad.'**
  String get maintenanceInfo;

  /// No description provided for @editingAllowedInOdoo.
  ///
  /// In es, this message translates to:
  /// **'Edición permitida en Odoo'**
  String get editingAllowedInOdoo;

  /// No description provided for @readOnly.
  ///
  /// In es, this message translates to:
  /// **'Solo lectura'**
  String get readOnly;

  /// No description provided for @requests.
  ///
  /// In es, this message translates to:
  /// **'Solicitudes'**
  String get requests;

  /// No description provided for @noRequests.
  ///
  /// In es, this message translates to:
  /// **'Sin solicitudes'**
  String get noRequests;

  /// No description provided for @noRequestsHint.
  ///
  /// In es, this message translates to:
  /// **'No hay solicitudes de mantenimiento visibles para este usuario.'**
  String get noRequestsHint;

  /// No description provided for @unlinkedEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo no vinculado'**
  String get unlinkedEquipment;

  /// No description provided for @noResponsible.
  ///
  /// In es, this message translates to:
  /// **'Sin responsable'**
  String get noResponsible;

  /// No description provided for @closedFeminine.
  ///
  /// In es, this message translates to:
  /// **'Cerrada'**
  String get closedFeminine;

  /// No description provided for @openFeminine.
  ///
  /// In es, this message translates to:
  /// **'Abierta'**
  String get openFeminine;

  /// No description provided for @maintenanceRequest.
  ///
  /// In es, this message translates to:
  /// **'Solicitud de mantenimiento'**
  String get maintenanceRequest;

  /// No description provided for @qualityEquipment.
  ///
  /// In es, this message translates to:
  /// **'Equipo de calidad: {name}'**
  String qualityEquipment(String name);

  /// No description provided for @responsible.
  ///
  /// In es, this message translates to:
  /// **'Responsable: {name}'**
  String responsible(String name);

  /// No description provided for @requestScheduleClose.
  ///
  /// In es, this message translates to:
  /// **'Solicitud: {request}\nProgramada: {scheduled}\nCierre: {closed}'**
  String requestScheduleClose(String request, String scheduled, String closed);

  /// No description provided for @noLinkedEquipment.
  ///
  /// In es, this message translates to:
  /// **'Sin equipos enlazados'**
  String get noLinkedEquipment;

  /// No description provided for @noLinkedEquipmentHint.
  ///
  /// In es, this message translates to:
  /// **'Todavía no hay equipos de calidad sincronizados con mantenimiento.'**
  String get noLinkedEquipmentHint;

  /// No description provided for @interventionRequired.
  ///
  /// In es, this message translates to:
  /// **'Requiere intervención'**
  String get interventionRequired;

  /// No description provided for @controlled.
  ///
  /// In es, this message translates to:
  /// **'Controlado'**
  String get controlled;

  /// No description provided for @code.
  ///
  /// In es, this message translates to:
  /// **'Código: {code}'**
  String code(String code);

  /// No description provided for @equipmentStatus.
  ///
  /// In es, this message translates to:
  /// **'Estado: {status}'**
  String equipmentStatus(String status);

  /// No description provided for @unitLabel.
  ///
  /// In es, this message translates to:
  /// **'Unidad: {name}'**
  String unitLabel(String name);

  /// No description provided for @linkedToMaintenance.
  ///
  /// In es, this message translates to:
  /// **'Vinculado a mantenimiento'**
  String get linkedToMaintenance;

  /// No description provided for @noLink.
  ///
  /// In es, this message translates to:
  /// **'Sin vínculo'**
  String get noLink;

  /// No description provided for @openCount.
  ///
  /// In es, this message translates to:
  /// **'{count} abiertas'**
  String openCount(String count);

  /// No description provided for @totalCount.
  ///
  /// In es, this message translates to:
  /// **'{count} totales'**
  String totalCount(String count);

  /// No description provided for @lastRequest.
  ///
  /// In es, this message translates to:
  /// **'Última solicitud: {date}'**
  String lastRequest(String date);

  /// No description provided for @preventive.
  ///
  /// In es, this message translates to:
  /// **'Preventivo'**
  String get preventive;

  /// No description provided for @corrective.
  ///
  /// In es, this message translates to:
  /// **'Correctivo'**
  String get corrective;

  /// No description provided for @noType.
  ///
  /// In es, this message translates to:
  /// **'Sin tipo'**
  String get noType;

  /// No description provided for @operational.
  ///
  /// In es, this message translates to:
  /// **'Operativo'**
  String get operational;

  /// No description provided for @broken.
  ///
  /// In es, this message translates to:
  /// **'Averiado'**
  String get broken;

  /// No description provided for @retired.
  ///
  /// In es, this message translates to:
  /// **'Retirado'**
  String get retired;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
