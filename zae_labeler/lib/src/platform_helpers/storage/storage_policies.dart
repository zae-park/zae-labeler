// 저장/읽기 정책 타입 — 공용으로 쓰이므로 독립 파일로 분리
enum StorageMode { local, cloud }

/// 쓰기 정책:
/// - localOnly: 쓰기는 로컬(IndexedDB/세션/캐시)에만 기록
/// - cloudOnly: 쓰기는 클라우드(Firestore/Storage)에만 기록
enum WritePolicy { localOnly, cloudOnly }

/// 읽기 정책:
/// - localFirst: 로컬 캐시 우선, 없으면 클라우드로 보강(read-through)
/// - cloudFirst: 클라우드 우선, 실패 시 로컬
/// - auto: 화면/상황별로 내부에서 판단(예: 진행률 요약=cloudFirst, 에셋=localFirst)
enum ReadPolicy { localFirst, cloudFirst, auto }
