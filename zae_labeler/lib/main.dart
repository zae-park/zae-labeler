import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'src/view_models/configuration_view_model.dart';
import 'src/views/pages/project_list_page.dart';
import 'src/views/pages/configuration_page.dart';
import 'src/views/pages/labeling_page.dart';
import 'src/view_models/project_list_view_model.dart';
import 'src/view_models/locale_view_model.dart';
import 'src/utils/storage_helper.dart'; // ✅ StorageHelper import 추가

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Registering providers for state management
      providers: [
        ChangeNotifierProvider<ProjectListViewModel>(create: (_) => ProjectListViewModel(storageHelper: StorageHelper.instance)),
        ChangeNotifierProvider<LocaleViewModel>(create: (_) => LocaleViewModel()),
        ChangeNotifierProvider<ConfigurationViewModel>(create: (_) => ConfigurationViewModel()), // ✅ 추가
        Provider<StorageHelperInterface>.value(value: StorageHelper.instance),
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
              '/': (context) => const ProjectListPage(),
              '/configuration': (context) => const ConfigureProjectPage(),
              '/labeling': (context) => const LabelingPage(),
            },
          );
        },
      ),
    );
  }
}
