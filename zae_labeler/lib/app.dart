// app.dart
//
// 앱의 **스켈레톤**을 정의합니다.
// - MultiProvider로 전역 의존성 주입
// - MaterialApp (테마, 로케일, 로컬라이제이션, 라우팅)
// - 라우팅은 AppRouter로 위임
//
// A안: 항상 로컬로 시작(SwitchableStorageHelper) → Auth 이벤트로 핫스왑

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'bootstrap.dart';
import 'app_router.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';
import 'src/features/locale/view_models/locale_view_model.dart';
import 'src/features/auth/view_models/auth_view_models.dart';
import 'src/features/project/view_models/project_list_view_model.dart';
import 'src/features/project/view_models/managers/progress_notifier.dart';

import 'src/core/services/user_preference_service.dart';
import 'src/core/use_cases/app_use_cases.dart';

import 'package:zae_labeler/src/platform_helpers/pickers/data_info_picker.dart';
import 'package:zae_labeler/src/platform_helpers/share/interface_share_helper.dart';
import 'package:zae_labeler/src/platform_helpers/storage/switchable_storage_helper.dart';

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
    _boot = bootstrap(systemLocale: widget.systemLocale);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<BootstrapResult>(
      future: _boot,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(body: Center(child: CircularProgressIndicator())),
          );
        }
        final deps = snap.data!;
        final DataInfoPicker picker = createDataInfoPicker();

        // ⚠️ A안: bootstrap()이 SwitchableStorageHelper 인스턴스를 반환한다고 가정.
        // 혹시 아닐 경우를 대비한 안전 캐스팅(필요 없으면 제거 가능)
        final SwitchableStorageHelper switchable =
            deps.storageHelper is SwitchableStorageHelper ? deps.storageHelper as SwitchableStorageHelper : SwitchableStorageHelper(deps.storageHelper);

        return MultiProvider(
          providers: [
            // ---- 전역 의존성 주입 ----
            // 같은 인스턴스를 두 타입으로 노출(편의 + 호환성)
            ChangeNotifierProvider<SwitchableStorageHelper>.value(value: switchable),

            Provider<AppUseCases>.value(value: deps.appUseCases),
            Provider<UserPreferenceService>.value(value: deps.userPrefs),
            Provider<ShareHelperInterface>.value(value: deps.shareHelper),
            Provider<DataInfoPicker>.value(value: picker),

            ChangeNotifierProvider<LocaleViewModel>.value(value: deps.localeViewModel),
            ChangeNotifierProvider<ProjectListViewModel>(
              create: (_) => ProjectListViewModel(
                appUseCases: deps.appUseCases,
                shareHelper: deps.shareHelper,
                picker: picker,
              ),
            ),
            ChangeNotifierProvider<AuthViewModel>(
              create: (_) => AuthViewModel.withDefaultUseCases(deps.firebaseAuth),
            ),
            ChangeNotifierProvider(create: (_) => ProgressNotifier()),
          ],
          // ✅ Auth ↔ Storage 핫스왑 와이어링 위젯
          child: _AuthStorageSync(
            auth: deps.firebaseAuth,
            child: Consumer<LocaleViewModel>(
              builder: (context, localeVM, _) {
                return MaterialApp(
                  title: 'ZAE Labeler',
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
          ),
        );
      },
    );
  }
}

/// 로그인 상태 변화에 맞춰 Storage를 핫스왑해 주는 루트 래퍼
class _AuthStorageSync extends StatefulWidget {
  final FirebaseAuth auth;
  final Widget child;
  const _AuthStorageSync({super.key, required this.auth, required this.child});

  @override
  State<_AuthStorageSync> createState() => _AuthStorageSyncState();
}

class _AuthStorageSyncState extends State<_AuthStorageSync> {
  StreamSubscription<User?>? _sub;

  @override
  void initState() {
    super.initState();
    // ✅ 빌드가 끝난 "첫 프레임 이후"에 스토리지 스위칭을 수행
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final switchable = context.read<SwitchableStorageHelper>();

      // 1) 앱 시작 시 초기 스냅 반영
      final user = widget.auth.currentUser;
      if (user != null) {
        // unawaited(switchable.switchToCloud());
        switchable.switchToCloud();
      } else {
        // unawaited(switchable.switchToLocal());
        switchable.switchToLocal();
      }

      // 2) 이후 인증 상태 변화 반영
      _sub = widget.auth.authStateChanges().listen((u) {
        final s = context.read<SwitchableStorageHelper>();
        if (u != null) {
          s.switchToCloud();
        } else {
          s.switchToLocal();
        }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
