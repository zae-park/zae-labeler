// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/views/pages/project_list_page.dart';
import 'src/views/pages/configuration_page.dart';
import 'src/views/pages/labeling_page.dart';
import 'src/view_models/project_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => LocaleViewModel(),
      child: Consumer<LocaleViewModel>(
        builder: (context, localeVM, child) {
          return MaterialApp(
            title: 'Data Labeling App',
            theme: ThemeData(primarySwatch: Colors.blue),
            locale: localeVM.currentLocale,
            supportedLocales: const [
              Locale('en'), // English
              Locale('ko') // Korean
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            initialRoute: '/',
            routes: {
              '/': (context) => const ProjectListPage(),
            },
          );
        },
      ),
    );
  }

  // // Root widget of the application
  // @override
  // Widget build(BuildContext context) {
  //   return MultiProvider(
  //     // Registering providers for state management.
  //     //Add other providers here if needed in the future
  //     providers: [
  //       ChangeNotifierProvider<ProjectViewModel>(
  //         create: (_) => ProjectViewModel(),
  //       ),
  //     ],
  //     child: MaterialApp(
  //       // Application title displayed in task switcher or web browser tab
  //       title: 'Data Labeling App for YOU !',
  //       theme: ThemeData(primarySwatch: Colors.blue),
  //       initialRoute: '/', // Initial route when the app is launched
  //       routes: {
  //         '/': (context) => const ProjectListPage(),
  //         '/configuration': (context) => const ConfigureProjectPage(),
  //         '/labeling': (context) => const LabelingPage(),
  //       },
  //     ),
  //   );
  // }
}
