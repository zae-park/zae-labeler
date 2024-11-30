import 'package:flutter/material.dart';
import './app_setting_modal.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    leading: GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/'); // 로고 클릭 시 메인 페이지로 이동
      },
      child: Image.asset('assets/favicon.png'), // 앱 로고 추가
    ),
    title: const Text('Data Labeling App'),
    actions: [
      IconButton(
        icon: const Icon(Icons.settings),
        tooltip: 'Settings',
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => const AppSettingsModal(),
          );
        },
      ),
    ],
  );
}
