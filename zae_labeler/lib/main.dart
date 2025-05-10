import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'env.dart';
import 'src/models/project_model.dart';
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

  runApp(const ZaeLabeler());
}

class ZaeLabeler extends StatelessWidget {
  const ZaeLabeler({super.key});

  @override
  Widget build(BuildContext context) {
    const bool isWebProd = kIsWeb && kReleaseMode;
    final useCloud = isProd && kIsWeb; // 🔧 dev or local에서는 로컬 저장
    final storageHelper = useCloud ? CloudStorageHelper() : StorageHelper.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectListViewModel>(
          create: (_) => ProjectListViewModel(storageHelper: isWebProd ? CloudStorageHelper() : StorageHelper.instance),
        ),
        ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        Provider<StorageHelperInterface>.value(value: isWebProd ? CloudStorageHelper() : StorageHelper.instance),
      ],
      // providers: [
      //   ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(storageHelper: storageHelper)),
      //   ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
      //   ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
      //   Provider<StorageHelperInterface>.value(value: storageHelper),
      // ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeVM, child) {
          return MaterialApp(
            title: 'Data Labeling App for YOU!',
            theme: ThemeData(primarySwatch: Colors.blue),
            locale: localeVM.currentLocale,
            supportedLocales: const [Locale('en'), Locale('ko')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Initial route when the app is launched
            initialRoute: '/',
            // routes: {
            //   '/': (context) => isProd ? const SplashScreen() : const ProjectListPage(),
            //   // '/onboarding': (context) => const OnboardingPage(),
            //   // '/auth': (context) => isProd ? const AuthGate() : const ProjectListPage(),
            //   '/project_list': (context) => const ProjectListPage(),
            //   '/configuration': (context) => const ConfigureProjectPage(),
            //   '/labeling': (context) => const LabelingPage(),
            // },
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
