/// 라우팅 정책을 한 곳에서 관리하는 라우터.
/// - Prod에서 미로그인 상태로 보호 라우트 접근 시 Splash로 이동
/// - 각 라우트의 인자 타입 검증
/// - 경로 상수 및 생성 유틸 제공
library app_router;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zae_labeler/env.dart' as Env;

import 'package:zae_labeler/src/features/project/models/project_model.dart';

// Pages
import 'package:zae_labeler/src/views/pages/splash_page.dart';
import 'package:zae_labeler/src/features/label/ui/pages/labeling_page.dart';
import 'package:zae_labeler/src/features/project/ui/pages/configuration_page.dart';
import 'package:zae_labeler/src/features/project/ui/pages/project_list_page.dart';
import 'package:zae_labeler/src/views/pages/not_found_page.dart';

// ViewModels
import 'package:zae_labeler/src/features/auth/view_models/auth_view_models.dart';

/// 앱에서 사용하는 라우트 이름 상수 모음.
abstract class Routes {
  static const root = '/';
  static const auth = '/auth';
  static const projectList = '/project_list';
  static const configuration = '/configuration';
  static const labeling = '/labeling';
}

/// `onGenerateRoute`로 전달할 라우터 엔트리.
/// 기존에 익명 클로저에서 `context.read<AuthViewModel>()`를 사용하던 패턴을
/// 안전하게 캡슐화하기 위해 `BuildContext`를 함께 받는 정적 메서드로 제공한다.
class AppRouter {
  AppRouter._();

  /// 라우트 가드: Prod && 미로그인 && 보호 라우트 접근 시 `SplashScreen`.
  /// - 허용 경로: `/`, `/auth`
  static Route<dynamic> _guardedRoute({
    required BuildContext context,
    required RouteSettings settings,
    required WidgetBuilder builder,
  }) {
    final isProd = Env.isProd; // 또는 bool.fromEnvironment('dart.vm.product')
    final isSignedIn = context.read<AuthViewModel>().isSignedIn;

    final name = settings.name ?? Routes.root;
    final isPublic = name == Routes.root || name == Routes.auth;

    if (isProd && !isSignedIn && !isPublic) {
      return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
    }
    return MaterialPageRoute(builder: builder, settings: settings);
  }

  /// MaterialApp.onGenerateRoute에 그대로 넘겨 쓸 수 있는 시그니처.
  /// 예)
  /// ```dart
  /// onGenerateRoute: (settings) => AppRouter.onGenerateRoute(context, settings)
  /// ```
  static Route<dynamic>? onGenerateRoute(
    BuildContext context,
    RouteSettings settings,
  ) {
    switch (settings.name) {
      case Routes.root:
        // Prod: Splash(로그인 분기용), Dev: 바로 프로젝트 리스트
        return _guardedRoute(context: context, settings: settings, builder: (_) => Env.isProd ? const SplashScreen() : const ProjectListPage());

      // case Routes.auth:
      //   return _guardedRoute(context: context, settings: settings, builder: (_) => const LoginPage());

      case Routes.projectList:
        return _guardedRoute(context: context, settings: settings, builder: (_) => const ProjectListPage());

      case Routes.configuration:
        return _guardedRoute(context: context, settings: settings, builder: (_) => const ConfigureProjectPage());

      case Routes.labeling:
        {
          final args = settings.arguments;
          if (args is Project) {
            return _guardedRoute(context: context, settings: settings, builder: (_) => LabelingPage(project: args));
          }
          // 잘못된 인자 타입/누락
          return MaterialPageRoute(builder: (_) => const NotFoundPage(), settings: settings);
        }

      default:
        // 명시적 404
        return MaterialPageRoute(builder: (_) => const NotFoundPage(), settings: settings);
    }
  }
}
