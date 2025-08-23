// app.dart
//
// 앱의 **스켈레톤**을 정의합니다.
// - MultiProvider로 전역 의존성 주입
// - MaterialApp (테마, 로케일, 로컬라이제이션, 라우팅)
// - 라우팅은 AppRouter로 위임
//
// 기존 main.dart의 ZaeLabeler StatefullWidget 초기화 로직을 여기로 옮겨
// main.dart는 runApp 만 담당하도록 단순화할 수 있습니다.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/src/platform_helpers/pickers/data_info_picker.dart';
import 'package:zae_labeler/src/platform_helpers/share/interface_share_helper.dart';
import 'package:zae_labeler/src/platform_helpers/storage/interface_storage_helper.dart';

import 'bootstrap.dart';
import 'app_router.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';
import 'src/features/locale/view_models/locale_view_model.dart';
import 'src/features/auth/view_models/auth_view_models.dart';
import 'src/features/project/view_models/project_list_view_model.dart';
import 'src/features/project/view_models/managers/progress_notifier.dart';

import 'src/core/services/user_preference_service.dart';
import 'src/core/use_cases/app_use_cases.dart';

/// 앱 루트 위젯.
///
/// [systemLocale]는 OS 기본 로케일이며, LocaleViewModel이 내부적으로 저장된 설정을
/// 복원하지 못했을 때의 폴백 등에 활용할 수 있습니다.
class ZaeLabeler extends StatefulWidget {
  final Locale systemLocale;
  const ZaeLabeler({super.key, required this.systemLocale});

  @override
  State<ZaeLabeler> createState() => _ZaeLabelerState();
}

class _ZaeLabelerState extends State<ZaeLabeler> {
  late final Future<BootstrapResult> _boot;

  @override
  void initState() {
    super.initState();
    // ✅ main.dart에서 Firebase.initializeApp은 이미 끝났다고 가정
    _boot = bootstrap(systemLocale: widget.systemLocale);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapResult>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
        }
        final deps = snap.data!;
        final DataInfoPicker picker = createDataInfoPicker();

        return MultiProvider(
          providers: [
            // ---- 전역 의존성 주입 (Provider/ChangeNotifier 혼용) ----
            Provider<StorageHelperInterface>.value(value: deps.storageHelper),
            Provider<AppUseCases>.value(value: deps.appUseCases),
            Provider<UserPreferenceService>.value(value: deps.userPrefs),
            Provider<ShareHelperInterface>.value(value: deps.shareHelper),
            Provider<DataInfoPicker>.value(value: picker),

            ChangeNotifierProvider<LocaleViewModel>.value(value: deps.localeViewModel),
            ChangeNotifierProvider<ProjectListViewModel>(
                create: (_) => ProjectListViewModel(appUseCases: deps.appUseCases, shareHelper: deps.shareHelper, picker: picker)),
            ChangeNotifierProvider<AuthViewModel>(create: (_) => AuthViewModel.withDefaultUseCases(deps.firebaseAuth)),
            ChangeNotifierProvider(create: (_) => ProgressNotifier()),
          ],
          child: Consumer<LocaleViewModel>(
            builder: (context, localeVM, _) {
              return MaterialApp(
                title: 'ZAE Labeler',
                // ✅ 테마는 필요 시 M3로 확장 가능
                theme: ThemeData(primarySwatch: Colors.blue),

                // 🌐 로케일
                locale: localeVM.currentLocale,
                supportedLocales: const [Locale('en'), Locale('ko')],
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],

                // 🧭 라우팅
                onGenerateRoute: (settings) => AppRouter.onGenerateRoute(context, settings),
                onUnknownRoute: (settings) => AppRouter.onGenerateRoute(context, settings)!,
              );
            },
          ),
        );
      },
    );
  }
}
