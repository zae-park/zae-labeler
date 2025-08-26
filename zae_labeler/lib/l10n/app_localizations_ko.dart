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
  String get common_ok => '확인';

  @override
  String get common_cancel => '취소';

  @override
  String get common_error => '오류';

  @override
  String get common_warning => '경고';

  @override
  String get common_loading => '로딩중';

  @override
  String get common_success => '성공';

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
  String get projectList_empty => '프로젝트가 없습니다. 프로젝트를 생성해주세요.';

  @override
  String get appbar_onboarding => '온보딩 다시보기';

  @override
  String get appbar_refresh => '새로고침';

  @override
  String get appbar_language => '언어 선택';

  @override
  String get appbar_project_create => '프로젝트 생성';

  @override
  String get appbar_project_import => '프로젝트 가져오기';

  @override
  String get projectTile_mode => '모드';

  @override
  String get projectTile_label => '레이블링';

  @override
  String get projectTile_edit => '수정';

  @override
  String get projectTile_download => '다운로드';

  @override
  String get projectTile_share => '공유';

  @override
  String get projectTile_delete => '삭제';

  @override
  String get projectTile_deleteEnsure => '프로젝트를 삭제하시겠습니까?';

  @override
  String get projectTile_deleteMessage => '프로젝트가 성공적으로 삭제되었습니다';

  @override
  String get configPage_title_create => '새 프로젝트 생성';

  @override
  String get configPage_title_edit => '프로젝트 수정';

  @override
  String get configPage_project_name => '프로젝트 이름';

  @override
  String get configPage_labeling_mode => '레이블링 모드';

  @override
  String get configPage_classes => '클래스';

  @override
  String get configPage_dataList => '데이터 목록';

  @override
  String get configPage_confirm => '확인';

  @override
  String get progressBar_complete => '완료';

  @override
  String get progressBar_incomplete => '미완료';

  @override
  String get progressBar_warning => '경고';

  @override
  String labeling_status_summary(
    Object complete,
    Object warning,
    Object incomplete,
  ) {
    return '완료: $complete  |  주의: $warning  |  미완료: $incomplete';
  }

  @override
  String get navigation_prev => '이전';

  @override
  String get navigation_next => '다음';

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

  @override
  String get message_import_project_failed => '프로젝트 가져오기에 실패했습니다.';

  @override
  String get message_import_project_success => '프로젝트 가져오기에 성공했습니다.';
}
