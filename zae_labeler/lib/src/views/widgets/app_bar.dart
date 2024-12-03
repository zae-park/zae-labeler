import 'package:flutter/material.dart';
import './app_setting_modal.dart';
import './buttons.dart';

AppBar buildAppBar(BuildContext context) {
  return AppBar(
    leading: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/'),
        child: Image.asset('assets/favicon.png')),
    title: const Text('Data Labeling App'),
    actions: [
      AppButton.settings(
          onPressed: () => showDialog(
              context: context, builder: (context) => const AppSettingsModal()))
    ],
  );
}
