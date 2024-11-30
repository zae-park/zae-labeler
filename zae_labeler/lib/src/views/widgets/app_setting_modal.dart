import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../utils/app_configuration.dart';

class AppSettingsModal extends StatelessWidget {
  const AppSettingsModal({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = Provider.of<AppConfiguration>(context, listen: false);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'App Settings',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Language'),
                DropdownButton<String>(
                  value: config.currentLocale,
                  items: const [
                    DropdownMenuItem(value: 'en', child: Text('English')),
                    DropdownMenuItem(value: 'ko', child: Text('한국어')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      config.updateLocale(value);
                    }
                  },
                ),
              ],
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Dark Mode'),
                Switch(
                  value: config.isDarkMode,
                  onChanged: (value) {
                    config.toggleDarkMode();
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 취소 버튼
                  },
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // 설정 저장 후 확인
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Settings Saved'),
                        content: const Text('Returning to Home Page.'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context); // 알림 닫기
                              Navigator.pushNamed(context, '/'); // 홈으로 이동
                            },
                            child: const Text('OK'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Confirm'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
