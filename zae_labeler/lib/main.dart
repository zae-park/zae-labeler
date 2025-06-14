import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'firebase_options.dart';
import 'env.dart';
import 'src/domain/app_use_cases.dart';
import 'src/domain/label/label_use_cases.dart';
import 'src/domain/project/project_use_cases.dart';
import 'src/models/project_model.dart';
import 'src/repositories/label_repository.dart';
import 'src/repositories/project_repository.dart';
import 'src/utils/storage_helper.dart';
import 'src/utils/proxy_storage_helper/cloud_storage_helper.dart';
import 'src/view_models/auth_view_model.dart';
import 'src/view_models/project_list_view_model.dart';
import 'src/view_models/locale_view_model.dart';
import 'src/views/pages/splash_page.dart';
// import 'src/views/pages/auth_gate.dart';
import 'src/views/pages/configuration_page.dart';
import 'src/views/pages/labeling_page.dart';
import 'src/views/pages/project_list_page.dart';
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

class ZaeLabeler extends StatelessWidget {
  final Locale systemLocale;
  const ZaeLabeler({super.key, required this.systemLocale});

  @override
  Widget build(BuildContext context) {
    final useCloud = isProd && kIsWeb; // 🔧 dev or local에서는 로컬 저장
    final storageHelper = useCloud ? CloudStorageHelper() : StorageHelper.instance;
    final projectRepo = ProjectRepository(storageHelper: storageHelper);
    final labelRepo = LabelRepository(storageHelper: storageHelper);

    final appUseCases = AppUseCases(project: ProjectUseCases.from(projectRepo), label: LabelUseCases.from(labelRepo));

    return MultiProvider(
      providers: [
        Provider<StorageHelperInterface>.value(value: storageHelper),
        Provider<AppUseCases>.value(value: appUseCases),
        ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(appUseCases: appUseCases)),
        ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
      ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeVM, child) {
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

            // Initial route when the app is launched
            initialRoute: '/',
            onUnknownRoute: (_) => MaterialPageRoute(builder: (_) => const NotFoundPage()),
            onGenerateRoute: (RouteSettings settings) {
              final isSignedIn = context.read<AuthViewModel>().isSignedIn;
              if (isProd && !isSignedIn && settings.name != '/' && settings.name != '/auth') {
                return MaterialPageRoute(builder: (_) => const SplashScreen());
              }
              switch (settings.name) {
                case '/':
                  return MaterialPageRoute(builder: (_) => isProd ? const SplashScreen() : const ProjectListPage());
                case '/project_list':
                  return MaterialPageRoute(builder: (context) => const ProjectListPage());
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
  }
}
