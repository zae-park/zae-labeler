// lib/src/utils/interface_storage_helper.dart
import '../../core/models/data/data_info.dart';
import '../../core/models/label/label_model.dart';
import '../../core/models/project/project_model.dart';

/// 앱의 영속 계층(네이티브/웹/클라우드)에서 **프로젝트 구성(설계도)**, **프로젝트 목록(레지스트리)**,
/// **라벨(annotations)**, **라벨 Import/Export**를 처리하는 공통 인터페이스입니다.
///
/// 🔎 데이터 원본(Data, 파일) IO에 대한 철학
/// - **Native**: 원본 데이터는 로컬 파일시스템 경로(`DataInfo.filePath`)를 통해 접근합니다.
///   스토리지 헬퍼는 **원본 파일을 이동/복사하지 않습니다.** (필요 시 *Export*에서만 읽어 ZIP에 포함)
/// - **Web**: 원본 데이터는 브라우저의 private storage(예: IndexedDB/메모리)에 상주합니다.
///   스토리지 헬퍼는 **원본 파일을 별도 저장하지 않습니다.** (필요 시 *Export*에서 `base64Content`를 사용)
/// - **Cloud**: 서버/스토리지에서 원본 데이터에 접근 가능하다는 전제입니다(예: UUID로 리졸브).
///   스토리지 헬퍼는 **UUID 등 참조만 기록**하고, 원본 파일 자체는 업로드하지 않는 것을 기본으로 합니다.
///   (라벨 교환이 목적일 때는 `labels.json`만 주고받는 것이 권장)
///
/// 🧾 라벨 직렬화 표준 스키마(Export/Import/CRUD 공통)
///   {
///     "data_id": "<데이터 고유 ID>",
///     "data_path": "<원본 경로/파일명>",              // optional (web은 주로 null)
///     "labeled_at": "YYYY-MM-DDTHH:mm:ss.sssZ",      // ISO-8601
///     "mode": "<LabelingMode.name>",                 // 예: singleClassification
///     "label_data": { ... }                          // = LabelModel.toJson()
///   }
abstract class StorageHelperInterface {
  // ==============================
  // 📌 Project Configuration IO
  // ==============================

  /// 여러 Project의 **구성(설계도)** 을 저장합니다.
  /// - 목적: 프로젝트의 모드/클래스/데이터 참조(DataInfo) 등 **재현 가능한 설정을 보존**.
  /// - 원본 데이터(바이너리)나 라벨은 포함하지 않는 것이 일반적입니다.
  Future<void> saveProjectConfig(List<Project> projects);

  /// 외부에서 전달된 프로젝트 **구성(JSON 문자열 등)** 을 파싱하여 Project 리스트로 복원합니다.
  /// - 목적: 다른 환경/머신/브라우저에서 **프로젝트 셋업 재현**.
  /// - 반환: 파싱된 Project 리스트(없으면 빈 리스트).
  Future<List<Project>> loadProjectFromConfig(String projectConfig);

  /// 단일 Project의 **구성(설계도) 파일**을 생성하여 다운로드/업로드 경로 또는 URL을 반환합니다.
  /// - Native: 파일 경로 반환(예: `/tmp/foo_project.json`)
  /// - Web: 브라우저 다운로드 트리거 후 논리 파일명 반환
  /// - Cloud: Storage 경로나 다운로드 URL 반환
  Future<String> downloadProjectConfig(Project project);

  // ==============================
  // 📌 Project List Management
  // ==============================

  /// 앱 내부에서 보여줄 **프로젝트 목록(레지스트리)** 을 저장합니다.
  /// - 목적: 홈/최근/핀 고정/정렬 등 **UX 편의용 상태 보존**.
  /// - 공유/백업 목적이 아닌 **로컬(또는 사용자 스코프) 레벨** 데이터.
  Future<void> saveProjectList(List<Project> projects);

  /// 저장된 **프로젝트 목록(레지스트리)** 을 불러옵니다.
  /// - 없으면 빈 리스트 반환.
  Future<List<Project>> loadProjectList();

  // ==============================
  // 📌 Single Label Data IO
  // ==============================

  /// 단일 데이터 항목의 **라벨**을 저장(upsert)합니다.
  /// - [projectId]: 프로젝트 식별자
  /// - [dataId]: 라벨링 대상 데이터 고유 ID
  /// - [dataPath]: 원본 파일 경로/파일명(웹은 주로 null)
  /// - [labelModel]: 저장할 라벨(내부적으로 위 **표준 스키마**로 직렬화)
  /// - Native/Web/Cloud 공통: **원본 데이터 파일은 이동/복사하지 않습니다.**
  Future<void> saveLabelData(
    String projectId,
    String dataId,
    String dataPath,
    LabelModel labelModel,
  );

  /// 단일 데이터 항목의 **라벨**을 로드합니다.
  /// - 저장된 레코드에 `mode`가 있으면 그 값을 우선 사용하고,
  ///   없다면 인자로 받은 [mode]를 힌트로 사용해 복원합니다.
  /// - 존재하지 않으면 구현체가 예외를 던질 수 있습니다.
  Future<LabelModel> loadLabelData(
    String projectId,
    String dataId,
    String dataPath,
    LabelingMode mode,
  );

  // ==============================
  // 📌 Project-wide Label IO
  // ==============================

  /// 프로젝트의 **라벨들을 일괄 저장**합니다.
  /// - 각 라벨은 `data_id` 기준 upsert 권장.
  /// - 원본 데이터 파일은 다루지 않습니다(필요 시 *Export*에서만 처리).
  Future<void> saveAllLabels(String projectId, List<LabelModel> labels);

  /// 프로젝트의 **모든 라벨**을 로드합니다.
  /// - 혼합 모드 데이터가 있을 수 있으므로, 레코드의 `mode`를 우선 사용해 복원해야 합니다.
  Future<List<LabelModel>> loadAllLabelModels(String projectId);

  /// 프로젝트의 **모든 라벨**을 삭제합니다.
  /// - 프로젝트 메타/원본 데이터는 별개입니다.
  Future<void> deleteProjectLabels(String projectId);

  /// 프로젝트 자체(메타/라벨 등)를 삭제합니다.
  /// - 실제 삭제 범위는 구현체 정책에 따릅니다.
  Future<void> deleteProject(String projectId);

  // ==============================
  // 📌 Label Data Import/Export
  // ==============================

  /// 라벨과(선택적으로) 원본 파일들을 **외부로 내보냅니다**.
  /// - 기본 목적: 협업/백업/이식. 일반적으로 `labels.json`(**라벨만**)이 핵심 산출물입니다.
  /// - [fileDataList]는 **Native/Web에서만** 주로 사용합니다:
  ///   - Native: `filePath`로부터 바이트를 읽어 ZIP에 포함할 수 있음.
  ///   - Web: `base64Content`에서 바이트를 복원해 ZIP에 포함할 수 있음.
  /// - Cloud: 서버가 원본에 접근 가능하면 **라벨만(`labels.json`) 업로드**하는 구성이 권장됩니다.
  /// - 반환: 결과물의 경로 또는 URL(플랫폼별 의미 상이).
  Future<String> exportAllLabels(
    Project project,
    List<LabelModel> labelModels,
    List<DataInfo> fileDataList,
  );

  /// 외부로부터 **라벨을 불러옵니다**.
  /// - Native: 파일 피커로 `labels.json`(또는 ZIP 내 JSON)을 선택해 파싱.
  /// - Web: `<input type="file">`로 JSON 선택/파싱.
  /// - Cloud: Storage/DB에서 최신 `labels.json`을 읽어 파싱(프로젝트 컨텍스트가 필요할 수 있음).
  /// - 반환: 복원된 라벨 리스트(없으면 빈 리스트).
  Future<List<LabelModel>> importAllLabels();

  // ==============================
  // 📌 Cache Management
  // ==============================

  /// 구현체가 사용하는 임시 캐시/임시 파일 등을 정리합니다.
  /// - Native: 임시 ZIP/작업 파일 정리
  /// - Web: Blob URL revoke, 인메모리 버퍼 정리
  /// - Cloud: 로컬 캐시가 없다면 보통 no-op
  Future<void> clearAllCache();
}
