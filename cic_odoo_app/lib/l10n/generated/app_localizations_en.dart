// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get accessibility => 'Accessibility';

  @override
  String get readingVision => 'Reading and vision';

  @override
  String get readingVisionHint => 'Adjust the interface to your visual needs.';

  @override
  String get textSize => 'Text size';

  @override
  String get textSizeHint => 'Combined with your device setting.';

  @override
  String get boldText => 'Bold text';

  @override
  String get boldTextHint => 'Increase text weight to make reading easier.';

  @override
  String get highContrast => 'High contrast';

  @override
  String get highContrastHint => 'Strengthen backgrounds, borders and text.';

  @override
  String get movement => 'Motion';

  @override
  String get movementHint =>
      'Reduce effects that may cause dizziness or distraction.';

  @override
  String get reduceMotion => 'Reduce animations';

  @override
  String get reduceMotionHint => 'Disable transitions and entrance animations.';

  @override
  String get preview => 'Preview';

  @override
  String get previewSuccess => 'Completed';

  @override
  String get previewWarning => 'Pending';

  @override
  String get previewText =>
      'Check the selected text size, weight and contrast here.';

  @override
  String get resetAccessibility => 'Reset accessibility';

  @override
  String get colorSupport => 'Distinguishing colours';

  @override
  String get colorSupportHint =>
      'Statuses include text and icons. Enable a blue and orange palette if red and green are difficult to distinguish.';

  @override
  String get alternativeColors => 'Blue and orange palette';

  @override
  String get screenReader => 'Screen reader';

  @override
  String get screenReaderHint =>
      'For spoken navigation, enable VoiceOver in iPhone accessibility settings or TalkBack on Android. No special mode is needed in this app.';

  @override
  String get language => 'Language';

  @override
  String get languageHint =>
      'Interface language. Content sent by other people keeps its original language.';

  @override
  String get systemLanguage => 'Device language';

  @override
  String get languageProgress =>
      'English translation is in progress; some modules still appear in Spanish.';

  @override
  String get home => 'Home';

  @override
  String get modules => 'Modules';

  @override
  String get activity => 'Activity';

  @override
  String get profile => 'Profile';

  @override
  String get myProfile => 'My profile';

  @override
  String get preferences => 'Preferences';

  @override
  String get preferencesHint => 'Appearance and accessibility needs';

  @override
  String get accessibilityHint => 'Text, contrast and reduced motion';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get darkModeHint => 'Switch between light and dark themes';

  @override
  String get logout => 'Sign out';

  @override
  String get personalInfo => 'Personal information';

  @override
  String get basicProfile => 'Basic profile details';

  @override
  String get phone => 'Phone';

  @override
  String get mobile => 'Mobile';

  @override
  String get position => 'Position';

  @override
  String get documentation => 'Documents';

  @override
  String get retry => 'Retry';

  @override
  String get profileError => 'Could not load your profile';

  @override
  String get view => 'View';

  @override
  String get noCv => 'No CV uploaded';

  @override
  String get backToTop => 'Back to top';

  @override
  String get quickActions => 'Quick actions';

  @override
  String get editProfile => 'Edit profile';

  @override
  String get explore => 'Explore';

  @override
  String get availableModules => 'Available modules';

  @override
  String get availableModulesHint =>
      'You only see the areas enabled for your Odoo profile.';

  @override
  String get searchModules => 'Search modules...';

  @override
  String modulesAvailable(int count) {
    return '$count modules available';
  }

  @override
  String get modulesLoadError =>
      'Could not load the module catalogue for this profile.';

  @override
  String get all => 'All';

  @override
  String get unread => 'Unread';

  @override
  String get important => 'Important';

  @override
  String get loadingActivity => 'Loading activity...';

  @override
  String get noActivity => 'No activity';

  @override
  String get noActivityHint => 'There are no notifications for this filter.';

  @override
  String get activityCentre => 'Activity centre';

  @override
  String get activityCentreHint =>
      'Recent, important and pending items to review.';

  @override
  String get total => 'Total';

  @override
  String get recentActivity => 'Recent activity';

  @override
  String get viewAll => 'View all';

  @override
  String get viewAllModules => 'View all';

  @override
  String get summary => 'Here is a summary of what matters.';

  @override
  String get goodMorning => 'Good morning';

  @override
  String get goodAfternoon => 'Good afternoon';

  @override
  String get goodEvening => 'Good evening';

  @override
  String get incidents => 'Incidents';

  @override
  String get reservations => 'Reservations';

  @override
  String get training => 'Training';

  @override
  String get open => 'Open';

  @override
  String get today => 'Today';

  @override
  String get pending => 'Pending';

  @override
  String get upToDate => 'All caught up';

  @override
  String get upToDateHint =>
      'There are no indicators available for this profile.';

  @override
  String get unknownError => 'Unknown error';

  @override
  String get communications => 'Communications';

  @override
  String get suggestions => 'Suggestions';

  @override
  String get couldNotLoadCommunications => 'Could not load communications';

  @override
  String get createCommunication => 'Create communication';

  @override
  String get communication => 'Communication';

  @override
  String get suggestion => 'Suggestion';

  @override
  String get title => 'Title';

  @override
  String get type => 'Type';

  @override
  String get date => 'Date';

  @override
  String get description => 'Description';

  @override
  String get recipientUnits => 'Recipient units';

  @override
  String get recipientRoles => 'Recipient functional roles';

  @override
  String get unit => 'Unit';

  @override
  String get role => 'Functional role';

  @override
  String get couldNotLoadRecipients => 'Could not load recipients';

  @override
  String get couldNotRunAction => 'Could not run action';

  @override
  String get analyse => 'Analyse';

  @override
  String get markHandled => 'Mark as handled';

  @override
  String get close => 'Close';

  @override
  String get received => 'Received';

  @override
  String get inAnalysis => 'In analysis';

  @override
  String get handled => 'Handled';

  @override
  String get answered => 'Answered';

  @override
  String get closed => 'Closed';

  @override
  String get newReservation => 'New reservation';

  @override
  String get myReservations => 'My reservations';

  @override
  String get dailyAgenda => 'Daily agenda';

  @override
  String get quickReservation => 'Quick reservation';

  @override
  String get quickReservationHint =>
      'Select a service, resource and time in 4 steps';

  @override
  String get reservationUnavailable => 'Reservation unavailable';

  @override
  String get reservationUnavailableHint =>
      'This user can view reservations but cannot create new ones from the app.';

  @override
  String get couldNotLoadReservations => 'Could not load reservations';

  @override
  String get scanReservationQr => 'Scan room or equipment QR';

  @override
  String records(int count) {
    return '$count records';
  }

  @override
  String get noReservations => 'No reservations';

  @override
  String get noReservationsHint => 'You have no registered reservations.';

  @override
  String agendaVisible(int count, String date) {
    return '$count reservations visible on $date';
  }

  @override
  String get noReservationsDay => 'No reservations on this day';

  @override
  String get noReservationsDayHint =>
      'There are no reservations available to view on the selected date.';

  @override
  String get limitedReservations => 'Reservations with limited access';

  @override
  String get back => 'Back';

  @override
  String get next => 'Next';

  @override
  String get createDraft => 'Create draft';

  @override
  String get saveChanges => 'Save changes';

  @override
  String get creating => 'Creating...';

  @override
  String get saving => 'Saving...';

  @override
  String get edit => 'Edit';

  @override
  String get confirm => 'Confirm';

  @override
  String get cancel => 'Cancel';

  @override
  String get editingDraft => 'Editing draft';

  @override
  String get reason => 'Reason';

  @override
  String get requester => 'Requester';

  @override
  String get access => 'Access';

  @override
  String get limitedReservationsHint =>
      'This profile is in view-only mode in the app. It can review reservations and the daily agenda, but cannot create or edit reservations with its current permissions.';

  @override
  String get service => 'Service';

  @override
  String get resource => 'Resource';

  @override
  String get schedule => 'Schedule';

  @override
  String get duration => 'Duration';

  @override
  String get sessionType => 'Session type';

  @override
  String get reasonOptional => 'Reason (optional)';

  @override
  String get availableHours => 'Available hours';

  @override
  String selectedResource(String name) {
    return 'Selected resource: $name';
  }

  @override
  String get selectService => 'Select a service to continue.';

  @override
  String get selectResource => 'Select a resource to continue.';

  @override
  String get selectTimeSlot => 'Select a time slot to continue.';

  @override
  String get reservationUpdated =>
      'Reservation updated. Confirm it when ready.';

  @override
  String get draftCreated =>
      'Reservation created as a draft. Review and confirm it when ready.';

  @override
  String get reservationConfirmed => 'Reservation confirmed.';

  @override
  String get reservationCancelled => 'Reservation cancelled.';

  @override
  String get draft => 'Draft';

  @override
  String get confirmed => 'Confirmed';

  @override
  String get cancelled => 'Cancelled';

  @override
  String get reservation => 'Reservation';

  @override
  String get billed => 'Billed';

  @override
  String get searchDocuments => 'Search documents...';

  @override
  String get documentsLimitedAccess => 'Documents with limited access';

  @override
  String get documentsLimitedAccessHint =>
      'This profile cannot access the complete document list through the API with its current permissions.';

  @override
  String get couldNotLoadDocuments => 'Could not load documents';

  @override
  String get noDocuments => 'No documents';

  @override
  String get noDocumentsHint => 'No results were found for this search.';

  @override
  String documentsCount(int count) {
    return '$count documents';
  }

  @override
  String versions(int count) {
    return '$count versions';
  }

  @override
  String get document => 'Document';

  @override
  String get documentWithoutAttachment =>
      'Document without an attached version.';

  @override
  String get couldNotOpenDocument => 'Could not open the document';

  @override
  String get couldNotDownload => 'Could not download';

  @override
  String get createIncident => 'Create incident';

  @override
  String get nonConformity => 'Non-conformity';

  @override
  String get improvementOpportunity => 'Improvement opportunity';

  @override
  String get category => 'Category';

  @override
  String get quality => 'Quality';

  @override
  String get healthSafety => 'Health and safety';

  @override
  String get subtype => 'Subtype';

  @override
  String get internal => 'Internal';

  @override
  String get supplier => 'Supplier';

  @override
  String get audit => 'Audit';

  @override
  String get claim => 'Claim';

  @override
  String get other => 'Other';

  @override
  String get openPlural => 'Open';

  @override
  String get inProgress => 'In progress';

  @override
  String get closedPlural => 'Closed';

  @override
  String get noIncidents => 'No incidents.';

  @override
  String incidentsCount(int count) {
    return '$count incidents';
  }

  @override
  String get incidentsUnitHint => 'From your unit, sorted by date';

  @override
  String get signInTitle => 'Sign in to your space';

  @override
  String get signInHint => 'Use the same credentials as in Odoo Web.';

  @override
  String get corporateEmail => 'Corporate email';

  @override
  String get enterCorporateEmail => 'Enter your corporate email';

  @override
  String get password => 'Password';

  @override
  String get enterPassword => 'Enter your password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get verifying => 'Verifying';

  @override
  String get signIn => 'Sign in';

  @override
  String get encryptedSession =>
      'Encrypted session and permissions synced with Odoo.';

  @override
  String get supportConfiguration => 'Support configuration';

  @override
  String get authorisedServer => 'Authorised server';

  @override
  String get authorisedEnvironment => 'Authorised environment';

  @override
  String get enterAuthorisedServer => 'Enter the authorised server';

  @override
  String get enterAuthorisedEnvironment => 'Enter the authorised environment';

  @override
  String get useLightMode => 'Use light mode';

  @override
  String get useDarkMode => 'Use dark mode';

  @override
  String get yourCicSpace => 'Your CIC space';

  @override
  String get brandHint =>
      'Information, tasks and follow-up connected to your profile.';

  @override
  String get privacyTitle => 'Privacy from the first step';

  @override
  String get privacyHint =>
      'Before you sign in, we do not load alerts, personal data or Odoo information. Afterwards you only see what your profile authorises.';

  @override
  String get signInHelpTitle => 'Problems signing in? ';

  @override
  String get signInHelpHint =>
      'Check your usual credentials and, if it continues, contact the person responsible for your CIC account.';

  @override
  String get accessVerificationFailed => 'We could not verify access';

  @override
  String get loginValueOneTitle => 'Everything important, organised';

  @override
  String get loginValueOneHint =>
      'Documents, news, activity and shortcuts in one home screen.';

  @override
  String get loginValueTwoTitle => 'Connected workflows';

  @override
  String get loginValueTwoHint =>
      'Reservations, incidents and processes updated with Odoo.';

  @override
  String get loginValueThreeTitle => 'Access based on your profile';

  @override
  String get loginValueThreeHint =>
      'Everyone sees only the modules they are authorised to use.';

  @override
  String get recruitment => 'Recruitment';

  @override
  String get error => 'Error';

  @override
  String get vacancies => 'Vacancies';

  @override
  String get applications => 'Applications';

  @override
  String get noVacancies => 'No vacancies';

  @override
  String get noVacanciesHint => 'There are no open positions.';

  @override
  String get vacancy => 'Vacancy';

  @override
  String get department => 'Department';

  @override
  String vacancyCount(int count) {
    return 'Vacancies: $count';
  }

  @override
  String get noApplications => 'No applications';

  @override
  String get noApplicationsHint => 'There are no registered applications.';

  @override
  String get candidate => 'Candidate';

  @override
  String get job => 'Position';

  @override
  String get status => 'Status';

  @override
  String linkedApplications(int count) {
    return '$count linked applications';
  }

  @override
  String get noVisibleApplicationsHint =>
      'This vacancy has no visible applications.';

  @override
  String get email => 'Email';

  @override
  String get providedDocuments => 'Documents provided';

  @override
  String get documentsReadOnlyHint =>
      'Read-only view. Downloading and sharing files is not permitted.';

  @override
  String get noCandidateDocuments => 'No documents';

  @override
  String get noCandidateDocumentsHint =>
      'The application has no available documents.';

  @override
  String get couldNotPreviewDocument => 'Could not preview the document';
}
