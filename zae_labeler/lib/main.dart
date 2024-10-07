// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'src/pages/project_list_page.dart';
import 'src/pages/configuration_page.dart';
import 'src/pages/labeling_page.dart';
import 'src/view_models/project_view_model.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱의 루트 위젯
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ProjectViewModel>(
          create: (_) => ProjectViewModel(),
        ),
        // 다른 Provider들이 있다면 여기에 추가
      ],
      child: MaterialApp(
        title: '시계열 데이터 라벨링 앱',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        // 초기 페이지 설정
        initialRoute: '/',
        routes: {
          '/': (context) => const ProjectListPage(),
          '/configuration': (context) => const ConfigureProjectPage(),
          '/labeling': (context) => const LabelingPage(),
        },
      ),
    );
  }
}
