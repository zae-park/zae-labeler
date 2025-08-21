# Zae-Labeler - Dev Readme

## 애플 개요
Flutter 기반의 이 데이터 레이블링 애플은 프로젝트 기본의 연결적 구조에 따른 데이터 포함/수정/삭제 및 레이블링 가능 패턴을 제공합니다. Windows과 Web을 모두 지원하며, MVVM (Model-ViewModel-View) 구조를 기본으로 구현되어 있습니다.

## 기능 가이드
- 복수 레이블링: 다중 레이블 목록(단일/모든 레이블)
- 프로젝트 관리: 정의, 수정, 삭제, 공유, 다운로드 기능
- Firebase 인증: Google, GitHub 인증 (기존 인증자가 있을 경우 반환 안내)
- 클랜드 및 노트 바이오: Web과 Native 모드 구분 구현
- 각 페이지에 적용되는 패턴시 UI 요소 AppHeader 구현

---

## 사용자 인증
Firebase Authentication을 통해 로그인 기능을 제공합니다. 현재 지원하는 인증 목록:

- Google
- GitHub
- (TODO) Kakao, Naver

또한 같은 이메일을 기반으로 다른 인증 방식으로 로그인을 할 경우, 이전에 사용한 방식으로 다시 로그인하도록 안내가 지시됩니다.

---

## 애플 코드 구조 (MVVM)

### 1. 구조 개요
- **Model**: `Project`, `LabelModel`, `UnifiedData` 같은 기본 데이터 형식
- **ViewModel**: View의 시작 사이트를 수행하는 시스템 가이드
- **View**: 페이지, 위젯, 버튼 등의 UI 요소

### 2. 프로젝트 생성/관리
- `ConfigureProjectPage`: 프로젝트 생성/수정, 목록 지정, 데이터 경로 선택
- `ProjectListPage`: 프로젝트 목록 관리, 공유/가져오기 가능
- `LabelingPage`: 모드에 따른 레이블링 페이지 등입

### 3. 레이블링 모드
- `ClassificationLabelingPage`: 단일/모든 레이블
- *(계획)* `SegmentationLabelingPage`: 일반 segmentation 및 multi-class segmentation

모드별 페이지는 `BaseLabelingPage`를 기반으로 합니다:
- 계정 방향화
- 뷰어 (e.g., 차트, grid)
- 키보드 추가 작업

### 4. 레이블 관리 ViewModel
- `LabelViewModel`: 한 개의 데이터에 대한 레이블 값을 관리. 목록, 레이블 시간, isLabeled/같은 판단 규칙 등 관리.
- `LabelingViewModel`: 데이터 목록과 현재 정보 (index, grid, 버튼 상황) 등을 관리합니다.

`LabelingViewModel`은 `currentLabelVM` (`LabelViewModel`의 instance)을 각 데이터별으로 관리하며, 이는 유저에 의해 업데이트됩니다.

---

## 공용 UI Component
`lib/views/widgets/`를 기준으로 UI 요소를 구현합니다:

- `AppHeader`: 페이지 제목, 왼쪽 버튼(방향 버튼) 및 오른쪽 메뉴 버튼 포함
- `SocialLoginButton`: 개발되는 인증 구분 버튼 (logo/컬럼 모두 포함)
- `LabelingKeyPad`: 클래스 목록을 버튼으로 구성
- `TimeSeriesChart`: fl_chart을 통해 시계열 데이터 시각화

→ *일반 요소들도 직접 View에서 widgets/으로 매핑 중입니다.*

---

## 파일 & 저장 시스템
- `UnifiedData`: 여러 모드에 공통적인 데이터 세트 사이드 포맷
- `StorageHelper`: 파일에 I/O 담당
- `CloudStorageHelper`: Firebase Firestore 사용

→ *web vs. native의 구현은 분류되지만, ViewModel의 인터페이스는 공통입니다.*

---

## Web 호스팅

- **Production (Firebase Hosting)**
  회원 로그인 필요: [https://zae-labeler.firebaseapp.com](https://zae-labeler.firebaseapp.com)

- **Development (GitHub Pages)**
  비회원/Dev 보조용: [https://zae-park.github.io/zae-labeler/](https://zae-park.github.io/zae-labeler/)

---

## Planned Features
- Segmentation Labeling (classification base보다 고려된 편집/기능)
- Kakao & Naver OAuth 로그인

---

## 개발 주의사항
- `flutter test --coverage`를 통해 테스트 효율 검사
- 모든 mutable state는 ViewModel에서 관리합니다.
- Platform 의존적인 구현은 `utils/`, `helpers/`에 구현됩니다. (but, 공통된 인터페이스를 가져야 함.)
- View에서의 UI 다양성/재사용성을 고려한 reusable widget을 구현해야합니다.
- 각 page에서는 공통 AppHeader를 사용하여 일관성을 유지합니다.


### FSD

```
lib/src/core/models/data/           # ✅ 코어: 값(모델)만, IO/라벨/플랫폼 모름
├─ file_type.dart                   # 파일 확장자→유형 판정 유틸
├─ data_info.dart                   # 원본 데이터 메타(파일명, base64, 경로)
└─ unified_data.dart                # 파싱 결과 컨테이너(값만 보관)

lib/src/features/data/              # ✅ 피처: IO, 파싱, 조합(상태 합성)
├─ services/
│  ├─ data_loader_interface.dart    # DataInfo → raw 로딩 인터페이스
│  ├─ data_loader.dart              # createDataLoader() 팩토리(조건부 import)
│  ├─ data_loader_io_impl.dart      # (io) 파일/바이트 읽기→텍스트/베이스64
│  ├─ data_loader_web_impl.dart     # (web) base64 그대로 사용
│  ├─ data_parser.dart              # raw → UnifiedData 변환(csv/json/image)
│  ├─ unified_data_service.dart     # fromDataInfo / fromDataId / toDataInfo(집약)
│  └─ adaptive_unified_data_loader.dart # 프로젝트 단위 일괄 로딩 + 라벨 상태 합성
└─ models/
   └─ data_with_status.dart         # (선택) UI용 DTO: UnifiedData + LabelStatus

```

```
ViewModel/UseCase
  └─ AdaptiveUnifiedDataLoader.load(Project)
       ├─ StorageHelper.loadAllLabelModels(project.id)  // 상태 합성용
       └─ UnifiedDataService.fromDataInfo(DataInfo)
            ├─ DataLoader.loadRaw(info)                 // 웹/네이티브 분기
            └─ DataParser.parse(info, type, raw)        // csv/json/image 파싱

```

```
src/
├─ core/
│  └─ models/
│     └─ auth/
│        ├─ auth_user.dart              // 앱에서 쓰는 User(표준화된 도메인 모델)
│        ├─ auth_credentials.dart       // 이메일/패스워드, OAuth code 등 로그인 입력 DTO
│        ├─ auth_token.dart             // access/refresh 토큰, 만료 시각
│        └─ auth_failure.dart           // 로그인 실패/네트워크 오류 등 에러 타입
│
└─ features/
   └─ auth/
      ├─ repository/
      │  ├─ auth_repository.dart        // 추상화(인터페이스)
      │  ├─ rest_auth_repository.dart   // REST 백엔드 구현(선택)
      │  └─ firebase_auth_repository.dart // FirebaseAuth 구현(선택)
      │
      ├─ services/
      │  ├─ auth_service.dart           // 저수준 API 호출/SDK 래퍼(플랫폼별)
      │  ├─ token_storage.dart          // 토큰 영속화(secure storage/web localStorage)
      │  └─ session_manager.dart        // 메모리 세션/자동 갱신/로그아웃 브로커
      │
      ├─ use_cases/
      │  └─ auth_use_cases.dart         // signIn/signOut/refresh/currentUser 등 파사드
      │
      ├─ view_models/
      │  ├─ auth_view_model.dart        // 로그인/회원가입 화면 VM
      │  └─ session_notifier.dart       // 전역 인증 상태(로그인/로그아웃) Notifier
      │
      └─ ui/
         ├─ pages/
         │  ├─ sign_in_page.dart
         │  ├─ sign_up_page.dart
         │  ├─ forgot_password_page.dart
         │  └─ auth_gate.dart           // AuthGuard 위젯: 로그인 여부에 따라 라우팅
         └─ widgets/
            ├─ email_field.dart
            ├─ password_field.dart
            └─ social_buttons.dart
```
