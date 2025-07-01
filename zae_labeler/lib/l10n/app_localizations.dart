import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ko.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
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

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
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
    Locale('ko')
  ];

  /// No description provided for @app_title.
  ///
  /// In en, this message translates to:
  /// **'Zae-Labeler: Data Labeling App'**
  String get app_title;

  /// No description provided for @splashPage_start.
  ///
  /// In en, this message translates to:
  /// **'Click to Start'**
  String get splashPage_start;

  /// No description provided for @splashPage_error.
  ///
  /// In en, this message translates to:
  /// **'e-mail is already registered. Please try another authentication method.'**
  String get splashPage_error;

  /// No description provided for @splashPage_google.
  ///
  /// In en, this message translates to:
  /// **'Google Login'**
  String get splashPage_google;

  /// No description provided for @splashPage_github.
  ///
  /// In en, this message translates to:
  /// **'Github Login'**
  String get splashPage_github;

  /// No description provided for @splashPage_guest.
  ///
  /// In en, this message translates to:
  /// **'Guest Login'**
  String get splashPage_guest;

  /// No description provided for @splashPage_guest_guide.
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get splashPage_guest_guide;

  /// No description provided for @splashPage_guest_message.
  ///
  /// In en, this message translates to:
  /// **'Guest mode redirects to external links, which are nightly versions. \nIn guest mode, your work is saved in the web browser, and your work may be deleted. \nDo you want to move?'**
  String get splashPage_guest_message;

  /// No description provided for @splashPage_guest_cancel.
  ///
  /// In en, this message translates to:
  /// **'No'**
  String get splashPage_guest_cancel;

  /// No description provided for @splashPage_guest_confirm.
  ///
  /// In en, this message translates to:
  /// **'Yes'**
  String get splashPage_guest_confirm;

  /// No description provided for @projectList_title.
  ///
  /// In en, this message translates to:
  /// **'Project List'**
  String get projectList_title;

  /// No description provided for @projectList_empty.
  ///
  /// In en, this message translates to:
  /// **'No projects available. Please create a project.'**
  String get projectList_empty;

  /// No description provided for @appbar_onboarding.
  ///
  /// In en, this message translates to:
  /// **'Onboarding Again'**
  String get appbar_onboarding;

  /// No description provided for @appbar_refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get appbar_refresh;

  /// No description provided for @appbar_language.
  ///
  /// In en, this message translates to:
  /// **'Select Language'**
  String get appbar_language;

  /// No description provided for @appbar_project_create.
  ///
  /// In en, this message translates to:
  /// **'Create Project'**
  String get appbar_project_create;

  /// No description provided for @appbar_project_import.
  ///
  /// In en, this message translates to:
  /// **'Import Project'**
  String get appbar_project_import;

  /// No description provided for @projectTile_mode.
  ///
  /// In en, this message translates to:
  /// **'MODE'**
  String get projectTile_mode;

  /// No description provided for @projectTile_label.
  ///
  /// In en, this message translates to:
  /// **'Lageling'**
  String get projectTile_label;

  /// No description provided for @projectTile_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get projectTile_edit;

  /// No description provided for @projectTile_download.
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get projectTile_download;

  /// No description provided for @projectTile_share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get projectTile_share;

  /// No description provided for @projectTile_delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get projectTile_delete;

  /// No description provided for @configPage_title_create.
  ///
  /// In en, this message translates to:
  /// **'Create New Project'**
  String get configPage_title_create;

  /// No description provided for @configPage_title_edit.
  ///
  /// In en, this message translates to:
  /// **'Edit Project'**
  String get configPage_title_edit;

  /// No description provided for @configPage_project_name.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get configPage_project_name;

  /// No description provided for @configPage_labeling_mode.
  ///
  /// In en, this message translates to:
  /// **'Labeling Mode'**
  String get configPage_labeling_mode;

  /// No description provided for @configPage_classes.
  ///
  /// In en, this message translates to:
  /// **'Classes'**
  String get configPage_classes;

  /// No description provided for @configPage_dataList.
  ///
  /// In en, this message translates to:
  /// **'Data List'**
  String get configPage_dataList;

  /// No description provided for @configPage_confirm.
  ///
  /// In en, this message translates to:
  /// **'Confirm'**
  String get configPage_confirm;

  /// No description provided for @project_name.
  ///
  /// In en, this message translates to:
  /// **'Project Name'**
  String get project_name;

  /// No description provided for @labeling_mode.
  ///
  /// In en, this message translates to:
  /// **'Labeling Mode'**
  String get labeling_mode;

  /// No description provided for @add_class.
  ///
  /// In en, this message translates to:
  /// **'Add Class'**
  String get add_class;

  /// No description provided for @class_list.
  ///
  /// In en, this message translates to:
  /// **'Class List'**
  String get class_list;

  /// No description provided for @save_project.
  ///
  /// In en, this message translates to:
  /// **'Save Project'**
  String get save_project;

  /// No description provided for @select_directory.
  ///
  /// In en, this message translates to:
  /// **'Select Directory'**
  String get select_directory;

  /// No description provided for @upload_file.
  ///
  /// In en, this message translates to:
  /// **'Upload File'**
  String get upload_file;
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
      <String>['en', 'ko'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ko':
      return AppLocalizationsKo();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
