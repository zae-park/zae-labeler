import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zae_labeler/src/core/services/user_preference_service.dart';
import 'package:zae_labeler/src/features/locale/view_models/locale_view_model.dart';
import 'package:zae_labeler/src/features/project/view_models/managers/progress_notifier.dart';
import '../l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'env.dart';
import 'src/core/use_cases/app_use_cases.dart';
import 'src/features/label/use_cases/label_use_cases.dart';
import 'src/features/project/use_cases/project_use_cases.dart';
import 'src/features/project/models/project_model.dart';
import 'src/features/label/repository/label_repository.dart';
import 'src/features/project/repository/project_repository.dart';
import 'src/platform_helpers/storage/get_storage_helper.dart';
import 'src/platform_helpers/storage/cloud_storage_helper.dart';
import 'package:zae_labeler/src/features/auth/view_models/auth_view_models.dart';
import 'src/features/project/view_models/project_list_view_model.dart';
// import 'src/view_models/locale_view_model.dart';
import 'src/views/pages/splash_page.dart';
// import 'src/views/pages/auth_gate.dart';
import 'src/features/project/ui/pages/configuration_page.dart';
import 'src/features/label/ui/pages/labeling_page.dart';
import 'src/features/project/ui/pages/project_list_page.dart';
import 'src/views/pages/not_found_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // await FirebaseAuth.instance.authStateChanges().firstWhere((u) => u != null);

  runApp(ZaeLabeler(
    systemLocale: WidgetsBinding.instance.platformDispatcher.locales.first,
    // systemLocale: WidgetsBinding.instance.platformDispatcher.locale,
  ));
}

class ZaeLabeler extends StatefulWidget {
  final Locale systemLocale;
  const ZaeLabeler({super.key, required this.systemLocale});

  @override
  State<ZaeLabeler> createState() => _ZaeLabelerState();
}

class _ZaeLabelerState extends State<ZaeLabeler> {
  late final Future<void> _initialization;
  late StorageHelperInterface _storageHelper;
  late AppUseCases _appUseCases;
  late SharedPreferences _prefs;
  // late Locale _initialLocale;
  late UserPreferenceService _userPrefs;
  late LocaleViewModel _localeViewModel;

  @override
  void initState() {
    super.initState();
    _initialization = _initProviders();
  }

  Future<void> _initProviders() async {
    final useCloud = isProd && kIsWeb;
    _storageHelper = useCloud ? CloudStorageHelper() : StorageHelper.instance;

    final projectRepo = ProjectRepository(storageHelper: _storageHelper);
    final labelRepo = LabelRepository(storageHelper: _storageHelper);

    _appUseCases = AppUseCases(project: ProjectUseCases.from(projectRepo), label: LabelUseCases.from(labelRepo));

    _prefs = await SharedPreferences.getInstance();
    _userPrefs = UserPreferenceService(_prefs);
    // _initialLocale = _userPrefs.locale;
    _localeViewModel = await LocaleViewModel.create();
  }

  @override
  Widget build(BuildContext context) {
    final firebaseAuth = FirebaseAuth.instance;

    return FutureBuilder<void>(
      future: _initialization,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }

        return MultiProvider(
          providers: [
            Provider<StorageHelperInterface>.value(value: _storageHelper),
            Provider<AppUseCases>.value(value: _appUseCases),
            Provider<UserPreferenceService>.value(value: _userPrefs),
            ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(appUseCases: _appUseCases)),
            ChangeNotifierProvider<LocaleViewModel>.value(value: _localeViewModel),
            ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel.withDefaultUseCases(firebaseAuth)),
            ChangeNotifierProvider(create: (_) => ProgressNotifier()),
          ],
          child: Consumer<LocaleViewModel>(
            builder: (context, localeVM, _) {
              return MaterialApp(
                title: "ZAE Labeler",
                theme: ThemeData(primarySwatch: Colors.blue),
                locale: localeVM.currentLocale,
                supportedLocales: const [Locale('en'), Locale('ko')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                initialRoute: '/',
                onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const NotFoundPage()),
                onGenerateRoute: (settings) {
                  final isSignedIn = context.read<AuthViewModel>().isSignedIn;
                  if (isProd && !isSignedIn && settings.name != '/' && settings.name != '/auth') {
                    return MaterialPageRoute(builder: (_) => const SplashScreen());
                  }
                  switch (settings.name) {
                    case '/':
                      return MaterialPageRoute(builder: (_) => isProd ? const SplashScreen() : const ProjectListPage());
                    case '/project_list':
                      return MaterialPageRoute(builder: (_) => const ProjectListPage());
                    case '/configuration':
                      return MaterialPageRoute(builder: (_) => const ConfigureProjectPage());
                    case '/labeling':
                      final args = settings.arguments;
                      if (args is Project) {
                        return MaterialPageRoute(builder: (_) => LabelingPage(project: args), settings: settings);
                      } else {
                        return MaterialPageRoute(builder: (_) => const NotFoundPage());
                      }
                    default:
                      return null;
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
