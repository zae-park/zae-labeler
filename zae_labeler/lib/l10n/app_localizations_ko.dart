// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Korean (`ko`).
class AppLocalizationsKo extends AppLocalizations {
  AppLocalizationsKo([String locale = 'ko']) : super(locale);

  @override
  String get app_title => 'Zae-Labeler: 데이터 라벨링 앱';

  @override
  String get splashPage_start => '시작하기';

  @override
  String get splashPage_error => '계정은 이미 가입되어 있었습니다. 다른 방법으로 다시 시도해주세요.';

  @override
  String get splashPage_google => 'Google 로그인';

  @override
  String get splashPage_github => 'Github 로그인';

  @override
  String get splashPage_guest => '비회원 로그인';

  @override
  String get splashPage_guest_guide => '비회원 모드';

  @override
  String get splashPage_guest_message =>
      '비회원 모드는 개발중인 app(외부링크)로 리다이렉팅됩니다. \n비회원 모드에서는 작업 내용이 브라우저에 저장되며, 작업 내용이 삭제될 수 있습니다. 이동할까요?';

  @override
  String get splashPage_guest_cancel => '아뇨';

  @override
  String get splashPage_guest_confirm => '네';

  @override
  String get projectList_title => '프로젝트 목록';

  @override
  String get project_create => '프로젝트 생성';

  @override
  String get project_update => '프로젝트 수정';

  @override
  String get project_name => '프로젝트 이름';

  @override
  String get labeling_mode => '라벨링 모드';

  @override
  String get add_class => '클래스 추가';

  @override
  String get class_list => '클래스 목록';

  @override
  String get save_project => '프로젝트 저장';

  @override
  String get select_directory => '디렉토리 선택';

  @override
  String get upload_file => '파일 업로드';
}
