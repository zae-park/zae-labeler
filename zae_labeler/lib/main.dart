import 'package:flutter/material.dart';
import 'src/pages/project_list_page.dart';
import 'src/pages/configuration_page.dart';
import 'src/pages/labeling_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // 앱의 루트 위젯
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '시계열 데이터 라벨링 앱',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      // 초기 페이지 설정
      initialRoute: '/',
      routes: {
        '/': (context) => const ProjectListPage(),
        '/configuration': (context) => ConfigurationPage(),
        '/labeling': (context) => const LabelingPage(),
      },
    );
  }
}
