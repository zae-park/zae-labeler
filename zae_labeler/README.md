# Zae-Labeler - Dev Readme (Updated)

## Overview

Zae-Labeler is a Flutter-based cross-platform labeling application supporting multi-mode data annotation. It is designed with modular architecture for maintainability, performance, and testability.

The app runs on **Web**, **Windows**, and **macOS** platforms, and supports local and cloud storage modes.

---

## Key Features

* **Multi-Mode Labeling**: Single classification, multi classification (more planned)
* **Project-Oriented Workflow**: Each project holds its schema, data, and label state
* **Authentication**: Google & GitHub login (Kakao/Naver planned)
* **Storage**: Firebase Cloud & local filesystem I/O
* **Cross-Platform UI**: Adaptive, responsive design for desktop and browser
* **MVVM + Clean Architecture**: Testable, scalable logic

---

## Code Architecture (Clean + Modular Feature-first)

### 1. Feature-First Structure

The codebase is organized around **feature domains** rather than technical layers:

```
lib/
├── features/
│   ├── project/
│   │   ├── models/
│   │   ├── view_models/
│   │   ├── views/
│   │   └── use_cases/
│   ├── label/
│   └── auth/
│
├── core/
│   ├── models/
│   ├── services/
│   ├── use_cases/app_use_cases.dart  // composition root
│   └── repositories/
│
├── shared/
│   ├── widgets/
│   ├── utils/
│   └── helpers/
│
├── l10n/
└── main.dart
```

### 2. Clean Architecture Layers

* **features/**: Contains all feature-specific UI + logic

  * ViewModel, UseCase, and UI scoped per domain

* **core/**: Shared business logic and composition layer

  * `AppUseCases` acts as the DI entrypoint bundling all feature use cases

* **shared/**: Common utilities and components reused across features

* **platform\_helpers/**: Platform-specific logic (e.g. cloud, native, web)

> This approach enables scalable development while preserving separation of concerns, enabling each feature to be modular and self-contained.

---

## Project Lifecycle

* `ConfigureProjectPage`: Setup label schema, modes, and files
* `ProjectListPage`: View, import/export/share/delete projects
* `LabelingPage`: Launch specific labeling mode

### Labeling Modes (Extensible)

* `ClassificationLabelingPage`
* `SegmentationLabelingPage` (planned)

---

## ViewModel Structure

### 1. `LabelingViewModel`

* Drives the labeling session
* Tracks current data, index, status, validation

### 2. `LabelViewModel`

* Controls label logic per data item
* Manages selected classes, label type, etc.

### 3. `ProjectViewModel`

* Handles project-level edits, class list, sharing

### 4. `LocaleViewModel`

* Tracks and updates locale preference

---

## Authentication

* Based on **Firebase Auth**
* Supports Google/GitHub (Kakao/Naver planned)
* Handles provider conflict detection

---

## Storage

* `StorageHelper` → native/local file system
* `CloudStorageHelper` → Firebase-integrated
* `UnifiedData` abstraction handles cross-mode data

---

## Common Widgets

* `AppHeader`: Unified page topbar with back button and actions
* `AutoSeparatedColumn`: Layout helper
* `LabelingProgress`, `NavigatorButtons`: Session progress and navigation

---

## Firebase

* **Authentication**: Google, GitHub login
* **Hosting**: Firebase Web + GitHub Pages

---

## Web Hosting

* 🔐 [https://zae-labeler.firebaseapp.com](https://zae-labeler.firebaseapp.com) → secure, login required
* 🧪 [https://zae-park.github.io/zae-labeler/](https://zae-park.github.io/zae-labeler/) → guest access for demo

---

## Development Notes

* Flutter 3.32.4 recommended
* Run `flutter test --coverage` to ensure coverage
* Run `flutter gen-l10n` after editing `.arb` files
* Feature-first structure helps with scalability & modularity
* Prefer `AppUseCases` injection for use-case orchestration
* Avoid mutable state in widgets, use `ChangeNotifier` + Provider

---

## Planned

* Full segmentation support
* More OAuth providers
* Auto backup/export
* Labeling analytics
