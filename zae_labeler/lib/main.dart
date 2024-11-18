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

  // Root widget of the application
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      // Registering providers for state management.
      //Add other providers here if needed in the future
      providers: [
        ChangeNotifierProvider<ProjectViewModel>(
          create: (_) => ProjectViewModel(),
        ),
      ],
      child: MaterialApp(
        // Application title displayed in task switcher or web browser tab
        title: 'Data Labeling App for YOU !',
        theme: ThemeData(primarySwatch: Colors.blue),
        initialRoute: '/', // Initial route when the app is launched
        routes: {
          '/': (context) => const ProjectListPage(),
          '/configuration': (context) => const ConfigureProjectPage(),
          '/labeling': (context) => const LabelingPage(),
        },
      ),
    );
  }
}
