// app.dart
//
// 앱의 **스켈레톤**을 정의합니다.
// - bootstrap() 완료 후 루트 ProviderScope에 런타임 핸들을 override로 주입
// - MaterialApp (테마, 로케일, 로컬라이제이션, 라우팅)
// - 라우팅은 AppRouter로 위임
//
// 스토리지는 항상 로컬로 시작하며, authStorageSyncProvider가 로그인 상태에 따라 핫스왑합니다.

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:zae_labeler/l10n/app_localizations.dart';

import 'app_router.dart';
import 'bootstrap.dart';
import 'src/core/di/providers.dart';
import 'src/features/auth/providers/auth_provider.dart';
import 'src/features/locale/providers/locale_provider.dart';

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
        if (snap.hasError) {
          return MaterialApp(
            home: Scaffold(body: Center(child: Text('Failed to start: ${snap.error}'))),
          );
        }
        return ProviderScope(overrides: snap.data!.overrides, child: const _App());
      },
    );
  }
}

class _App extends ConsumerWidget {
  const _App();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ✅ Auth ↔ Storage 핫스왑 구독 유지
    ref.watch(authStorageSyncProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp(
      title: 'ZAE Labeler',
      theme: ThemeData(primarySwatch: Colors.blue),

      // 🌐 로케일
      locale: locale,
      supportedLocales: [for (final code in supportedLanguageCodes) Locale(code)],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // 🧭 라우팅 (가드 판단 시점의 로그인 상태를 읽음)
      onGenerateRoute: (settings) => AppRouter.onGenerateRoute(settings, isSignedIn: ref.read(authProvider).isSignedIn),
      onUnknownRoute: (settings) => AppRouter.onGenerateRoute(settings, isSignedIn: ref.read(authProvider).isSignedIn),
    );
  }
}
