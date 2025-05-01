import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';
import 'package:zae_labeler/src/utils/app_configuration.dart';
import 'package:zae_labeler/src/views/widgets/app_setting_modal.dart';
// import 'package:zae_labeler/src/views/widgets/core/layouts.dart'; // 필요한 경로 확인

class MockAppConfiguration extends Mock implements AppConfiguration {}

void main() {
  testWidgets('AppSettingsModal updates settings', (WidgetTester tester) async {
    final mockConfig = MockAppConfiguration();
    when(mockConfig.currentLocale).thenReturn('en');
    when(mockConfig.isDarkMode).thenReturn(false);

    await tester.pumpWidget(
      ChangeNotifierProvider<AppConfiguration>.value(
        value: mockConfig,
        child: const MaterialApp(home: AppSettingsModal()),
      ),
    );

    expect(find.text('App Settings'), findsOneWidget);

    // Toggle Dark Mode
    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    verify(mockConfig.toggleDarkMode()).called(1);
  }, skip: true);
}
