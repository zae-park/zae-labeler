import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'env.dart';
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
    final useCloud = isProd && kIsWeb; // 🔧 dev or local에서는 로컬 저장
    final storageHelper = useCloud ? CloudStorageHelper() : StorageHelper.instance;

    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(storageHelper: storageHelper)),
        ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
        Provider<StorageHelperInterface>.value(value: storageHelper),
      ],
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
            routes: {
              '/': (context) => isProd ? const SplashScreen() : const ProjectListPage(),
              // '/onboarding': (context) => const OnboardingPage(),
              // '/auth': (context) => isProd ? const AuthGate() : const ProjectListPage(),
              '/project_list': (context) => const ProjectListPage(),
              '/configuration': (context) => const ConfigureProjectPage(),
              '/labeling': (context) => const LabelingPage(),
            },
          );
        },
      ),
    );
  }
}
