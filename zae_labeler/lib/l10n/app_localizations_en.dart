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
  String get common_ok => 'OK';

  @override
  String get common_cancel => 'Cancel';

  @override
  String get common_error => 'Error';

  @override
  String get common_warning => 'Warning';

  @override
  String get common_loading => 'Loading';

  @override
  String get common_success => 'Success';

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
  String get projectList_title => 'Project List';

  @override
  String get projectList_empty =>
      'No projects available. Please create a project.';

  @override
  String get appbar_onboarding => 'Onboarding Again';

  @override
  String get appbar_refresh => 'Refresh';

  @override
  String get appbar_language => 'Select Language';

  @override
  String get appbar_project_create => 'Create Project';

  @override
  String get appbar_project_import => 'Import Project';

  @override
  String get projectTile_mode => 'MODE';

  @override
  String get projectTile_label => 'Labeling';

  @override
  String get projectTile_edit => 'Edit';

  @override
  String get projectTile_download => 'Download';

  @override
  String get projectTile_share => 'Share';

  @override
  String get projectTile_delete => 'Delete';

  @override
  String get projectTile_deleteEnsure =>
      'Are you sure you want to delete the project?';

  @override
  String get projectTile_deleteMessage => 'Project deleted successfully';

  @override
  String get configPage_title_create => 'Create New Project';

  @override
  String get configPage_title_edit => 'Edit Project';

  @override
  String get configPage_project_name => 'Project Name';

  @override
  String get configPage_labeling_mode => 'Labeling Mode';

  @override
  String get configPage_classes => 'Classes';

  @override
  String get configPage_dataList => 'Data List';

  @override
  String get configPage_confirm => 'Confirm';

  @override
  String get progressBar_complete => 'complete';

  @override
  String get progressBar_incomplete => 'incomplete';

  @override
  String get progressBar_warning => 'warning';

  @override
  String labeling_status_summary(
    Object complete,
    Object warning,
    Object incomplete,
  ) {
    return 'Done: $complete  |  Warning: $warning  |  Incomplete: $incomplete';
  }

  @override
  String get navigation_prev => 'Prev';

  @override
  String get navigation_next => 'Next';

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

  @override
  String get message_import_project_failed => 'Failed to import project.';

  @override
  String get message_import_project_success => 'Project imported successfully.';
}
