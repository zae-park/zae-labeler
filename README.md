# Zae-Labeler

## Welcome! 🎉
쉽고 간편한 labeling tool, **Zae-Labeler**입니다.
Image, Time-series, Object 데이터 등을 위한 직관적인 UI를 web, windows, linux 환경에서 제공합니다.

## ✨ 주요 기능
- **프로젝트 관리**: 여러 개의 프로젝트를 만들고 관리할 수 있어요!
- **다양한 라벨링 모드 지원**:
  - **분류** (Classification) - Data별 지정된 class를 할당
    - **단일 분류** (Single Classification) - 한 가지 class의 할당만 허용
    - **다중 분류** (Multi-class Classification) - 여러 class의 할당 허용
    - **쌍 분류** (Pairwise Classification) - 두 data 쌍 사이에 class 할당
  - **세그멘테이션** (Segmentation) - Pixel별 지정된 class를 할당
    - **단일 분류** (Single Class Segmentation) - 한 가지 class의 할당만 허용
    - **다중 분류** (Multi-class Classification) - 여러 class의 할당 허용
- **키보드 단축키 지원**: 단축키를 활용하여 빠르게 작업할 수 있어요.
- **데이터 시각화**: 다양한 형식의 데이터를 쉽게 확인하면서 라벨링 가능!
- **라벨 내보내기**: 작업한 내용을 JSON 또는 ZIP 파일로 저장해서 활용 가능!

## 🌐 웹에서 바로 사용하기
설치 없이 웹 브라우저에서 사용할 수 있어요! 
아래 링크를 클릭해서 바로 시작해 보세요:

[👉 데이터 라벨링 앱 사용하기](https://zae-park.github.io/zae-labeler)

Windows, Linux, macOS 용 독립 실행 프로그램은 곧 출시될 예정이에요! 🚀

## 🏁 시작하기
### 1️⃣ 새로운 프로젝트 만들기
1. **앱 실행** 후 **'프로젝트 생성'** 버튼을 클릭하세요.
2. 프로젝트 이름을 입력하고, **라벨링 모드**를 선택하세요. 하나의 프로젝트에서 하나의 라벨링 모드만 지원합니다. 수정 시 작업물이 삭제됩니다!
3. **클래스 추가**: 사용할 라벨을 입력하세요! (예: "고양이", "강아지", "자동차")
4. **데이터 지정**: JSON, 이미지, 시계열 데이터를 업로드할 수 있어요.
   - JSON 데이터 파일
   - PNG, JPG, JPEG 이미지 파일
   - CSV 또는 JSON 형식의 시계열 데이터

### 2️⃣ 프로젝트 관리
- **프로젝트 수정**: 프로젝트 이름, 라벨링 모드, 클래스 목록을 변경할 수 있어요.
- **프로젝트 삭제**: 필요 없는 프로젝트는 삭제할 수 있어요.
- **프로젝트 공유**:
  - 공동 작업자들에게 프로젝트의 설정을 공유하고 같은 환경에서 작업하세요!
  - JSON 파일로 내보내서 다른 사람과 공유 가능!
  - ZIP 파일로 압축해서 프로젝트 설정과 데이터를 공유 가능!

### 3️⃣ 데이터 라벨링 시작! 🚀
- **프로젝트 선택 후 라벨링을 시작하세요!**
- **방향키(← →)** 로 데이터를 이동하며 확인할 수 있어요.
- **숫자 키 (0-9)** 를 누르면 라벨을 빠르게 지정할 수 있어요.
- **Tab 키** 를 눌러 라벨링 모드를 변경할 수 있어요. (will be deprecated in future)
- **설정 페이지에서 클래스 추가/수정 가능!**
  - 새로운 클래스를 추가하거나 기존 클래스를 수정할 수 있어요. (기존 작업물에는 반영 기능 추가 예정)

### 4️⃣ 저장 및 내보내기
- **라벨은 자동 저장**되니 걱정하지 마세요! 😉
- **ZIP 파일로 다운로드**해서 나중에 활용할 수 있어요.
- **JSON 형식으로 내보내기 가능** (라벨 데이터 포함)

## 🗂 라벨 저장 형식
라벨링된 데이터는 JSON 형식으로 저장됩니다.

예제:
```json
{
  "data_filename": "image1.png",
  "labels": {
    "single_classification": "고양이",
    "multi_classification": ["동물", "애완동물"]
  }
}
```

## ⌨️ 키보드 단축키
| 키            | 동작             |
| ------------- | ---------------- |
| ←             | 이전 데이터      |
| →             | 다음 데이터      |
| Tab           | 라벨링 모드 변경 |
| 0-9           | 라벨 지정        |
| ⌫(백스페이스) | 라벨 제거        |

## 💡 기여하기
이 프로젝트는 오픈 소스로 운영되고 있어요! 
더 나은 앱을 만들기 위해 **Pull Request**를 보내거나, 이슈를 등록해 주세요. 🙌

## 📜 라이선스
이 프로젝트는 **MIT 라이선스**로 제공됩니다. 자유롭게 사용하세요! 😊

