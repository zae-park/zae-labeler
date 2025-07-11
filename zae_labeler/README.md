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

## Code Architecture (Hybrid Feature-Based)

### 🔹 Hybrid Structure (Feature + Layer)

We follow a **hybrid feature-first structure** with layered separation inside each feature module.

```
lib/
├── core/                       # Shared domain logic
│   ├── base/                  # Abstract base classes & interfaces
│   ├── models/                # Shared data models (Project, Label, etc.)
│   ├── services/              # Cross-feature services (e.g. UserPreferenceService)
│   ├── platform/              # Platform-specific helper interfaces
│   └── use_cases/            # Aggregated app-level use case (AppUseCases)
│
├── features/
│   ├── auth/
│   │   ├── ui/
│   │   ├── view_model/
│   │   ├── service/
│   │   └── use_case/
│   │
│   ├── project/
│   │   ├── ui/
│   │   ├── view_model/
│   │   ├── use_case/
│   │   └── repository/
│   │
│   └── labeling/
│       ├── ui/
│       ├── view_model/
│       ├── use_case/
│       ├── model/
│       └── validator/
│
├── shared/                    # Common reusable widgets and helpers
│   ├── widgets/
│   ├── utils/
│   └── helpers/
│
├── l10n/                      # Localization
└── main.dart                  # App entry and routing
```

### ✳ Clean Architecture in Practice

* `features/` → Feature-local presentation, view\_model, domain logic
* `core/` → App-wide shared domain, services, use case composition
* `shared/` → Stateless widgets, utilities
* `AppUseCases` → Bundles all individual feature use cases for injection

This structure balances separation of concerns and scalability, making each feature independently testable and modular.

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
* Hybrid feature-first structure ensures modular scalability
* Use `AppUseCases` for feature orchestration
* Prefer `ChangeNotifier` + Provider for reactive state

---

## Planned

* Full segmentation support
* More OAuth providers
* Auto backup/export
* Labeling analytics
