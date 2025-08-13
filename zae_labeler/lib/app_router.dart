/// app_router.dart
///
/// 라우팅 **정책**과 **테이블**을 한 곳에서 관리합니다.
/// - 문자열 라우트 상수 정의
/// - 인증 가드(프로덕션에서 미로그인 시 스플래시로 우회)
/// - 페이지별 arguments 타입 체크
///
/// MaterialApp.onGenerateRoute 에서
///   `onGenerateRoute: (settings) => AppRouter.onGenerateRoute(context, settings)`
/// 로 사용하세요.
import 'package:flutter/material.dart';
import 'env.dart';
import 'package:provider/provider.dart';

import 'src/features/auth/view_models/auth_view_models.dart';
import 'src/features/project/models/project_model.dart';

import 'src/views/pages/not_found_page.dart';
import 'src/views/pages/splash_page.dart';
import 'src/features/project/ui/pages/project_list_page.dart';
import 'src/features/project/ui/pages/configuration_page.dart';
import 'src/features/label/ui/pages/labeling_page.dart';

/// 라우트 이름 상수
class Routes {
  static const root = '/';
  static const projectList = '/project_list';
  static const configuration = '/configuration';
  static const labeling = '/labeling';
  static const auth = '/auth'; // (스플래시/로그인 전용 라우트 예외 허용용)
}

class AppRouter {
  /// 라우팅 가드 + 테이블
  ///
  /// - Prod && 미로그인 상태에서 보호 라우트로 이동할 경우 스플래시로 리다이렉트
  /// - 알려지지 않은 라우트는 NotFoundPage
  static Route<dynamic>? onGenerateRoute(BuildContext context, RouteSettings settings) {
    final isSignedIn = context.read<AuthViewModel>().isSignedIn;

    // ✅ Auth Guard (Prod 한정)
    if (isProd && !isSignedIn && settings.name != Routes.root && settings.name != Routes.auth) {
      return MaterialPageRoute(builder: (_) => const SplashScreen());
    }

    switch (settings.name) {
      case Routes.root:
        // Prod: Splash → 이후 내부에서 로그인/리디렉션 처리
        // Dev: 바로 프로젝트 리스트
        return MaterialPageRoute(builder: (_) => isProd ? const SplashScreen() : const ProjectListPage(), settings: settings);

      case Routes.projectList:
        return MaterialPageRoute(builder: (_) => const ProjectListPage(), settings: settings);

      case Routes.configuration:
        return MaterialPageRoute(builder: (_) => const ConfigureProjectPage(), settings: settings);

      case Routes.labeling:
        final args = settings.arguments;
        if (args is Project) {
          return MaterialPageRoute(builder: (_) => LabelingPage(project: args), settings: settings);
        }
        // 인자 타입 불일치 → 404
        return MaterialPageRoute(builder: (_) => const NotFoundPage(), settings: settings);

      default:
        // unknown route
        return MaterialPageRoute(builder: (_) => const NotFoundPage(), settings: settings);
    }
  }
}
