import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'src/utils/proxy_storage_helper/cloud_storage_helper.dart';
import 'src/utils/storage_helper.dart';
import 'src/view_models/auth_view_model.dart';
import 'src/views/pages/auth_gate.dart';
// import 'src/views/pages/project_list_page.dart';
import 'src/views/pages/configuration_page.dart';
import 'src/views/pages/labeling_page.dart';
import 'src/view_models/project_list_view_model.dart';
import 'src/view_models/locale_view_model.dart';
import 'env.dart';

import 'firebase_options.dart';
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
    const bool isWebProd = kIsWeb && kReleaseMode;

    return MultiProvider(
      // Registering providers for state management
      providers: [
        // ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(storageHelper: StorageHelper.instance)),
        ChangeNotifierProvider<ProjectListViewModel>(
          create: (_) => ProjectListViewModel(storageHelper: isWebProd ? CloudStorageHelper() : StorageHelper.instance),
        ),
        ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
        Provider<StorageHelperInterface>.value(value: isWebProd ? CloudStorageHelper() : StorageHelper.instance),
        ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel()),
      ],
      child: Consumer<LocaleViewModel>(
        builder: (context, localeVM, child) {
          return MaterialApp(
            // Application title displayed in task switcher or web browser tab
            title: 'Data Labeling App for YOU!',
            theme: ThemeData(primarySwatch: Colors.blue),

            // Set the current locale dynamically
            locale: localeVM.currentLocale,
            supportedLocales: const [Locale('en'), Locale('ko')],

            // Enable localization delegates
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Initial route when the app is launched
            initialRoute: '/',
            routes: {
              '/': (context) => isProd ? const AuthGate() : const ProjectListPage(),
              // '/': (context) => const ProjectListPage(),
              '/configuration': (context) => const ConfigureProjectPage(),
              '/labeling': (context) => const LabelingPage(),
            },
          );
        },
      ),
    );
  }
}
