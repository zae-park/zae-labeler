// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get app_title => 'Zae-Labeler: Data Labeling App';

  @override
  String get splashPage_start => 'Click to Start';

  @override
  String get splashPage_error =>
      'e-mail is already registered. Please try another authentication method.';

  @override
  String get splashPage_google => 'Google Login';

  @override
  String get splashPage_github => 'Github Login';

  @override
  String get splashPage_guest => 'Guest Login';

  @override
  String get splashPage_guest_guide => 'Guest Mode';

  @override
  String get splashPage_guest_message =>
      'Guest mode redirects to external links, which are nightly versions. \nIn guest mode, your work is saved in the web browser, and your work may be deleted. \nDo you want to move?';

  @override
  String get splashPage_guest_cancel => 'No';

  @override
  String get splashPage_guest_confirm => 'Yes';

  @override
  String get project_create => 'Create Project';

  @override
  String get project_update => 'Update Project';

  @override
  String get project_name => 'Project Name';

  @override
  String get labeling_mode => 'Labeling Mode';

  @override
  String get add_class => 'Add Class';

  @override
  String get class_list => 'Class List';

  @override
  String get save_project => 'Save Project';

  @override
  String get select_directory => 'Select Directory';

  @override
  String get upload_file => 'Upload File';
}
