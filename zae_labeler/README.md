# Zae-Labeler - Dev Readme

## Overview
This Flutter-based labeling app supports project-based data annotation with a focus on flexibility, multi-mode labeling, and modern UI/UX. It is designed to work cross-platform (Windows & Web) and uses a modular MVVM (Model-View-ViewModel) architecture.

## Key Features
- **Multi-Mode Labeling**: Single classification, multi classification
- **Project-Oriented Management**: Projects include label schema, data paths, and modes.
- **Firebase Authentication**: Google and GitHub sign-in with provider conflict resolution.
- **Cloud & Local Persistence**: Supports Firebase Firestore and local file-based project/label storage.
- **Cross-Platform UI**: Fully responsive web and Windows interface.

---

## User Authentication

The app supports user authentication using **Firebase Authentication**. Users can sign in with:

- Google
- GitHub
- (Planned) Kakao, Naver

If the user attempts to log in with a provider different from the one originally used for their email, the app will guide them to use the correct method.

---

## Code Architecture

### 1. MVVM Structure
- **Model**: Core data types including `Project`, `LabelModel`, and `UnifiedData`
- **ViewModel**: Centralized business logic layer
- **View**: Pages and widgets that consume ViewModels reactively

### 2. Project Lifecycle
- `ConfigureProjectPage`: Create/edit project, set classes, mode, and data directory
- `ProjectListPage`: View, import, export, share, or delete projects
- `LabelingPage`: Routes to mode-specific pages

### 3. Labeling Modes
Each labeling mode has its own dedicated page:
- `ClassificationLabelingPage`
- *(Planned)* `SegmentationLabelingPage`

They inherit from `BaseLabelingPage`, which handles:
- Navigation logic
- Viewer layout
- Keyboard shortcuts

### 4. Labeling ViewModels
The app uses two layers of labeling state management:

- **`LabelViewModel`**: Represents a single labeled entry. Each entry contains the label value(s), labeled timestamp, and mode-aware logic (e.g., isLabeled, isSelected).
- **`LabelingViewModel`**: Manages the entire session. It maintains the current index, navigates between items, restores saved labels, and handles grid/keypad/class logic depending on mode.

Labeling pages use a `currentLabelVM` (a `LabelViewModel` instance) that is updated dynamically by `LabelingViewModel` as the user navigates.

---

## Common UI Components

Reusable widgets are defined under `lib/views/widgets/`:

- `AppHeader`: Page title, optional leading/back button, and action buttons.
- `SocialLoginButton`: OAuth buttons with logo and color styling.
- `LabelingKeyPad`: Renders class-based buttons dynamically.
- `TimeSeriesChart`: Visualizes sequential or sensor data.

➡️ *Many widgets are in transition to this structure, and more will be modularized going forward.*

---

## File & Storage System

- `StorageHelper`: Native file I/O handler for local mode.
- `CloudStorageHelper`: Firebase-integrated version for web.
- `UnifiedData`: Abstract unit of data per label entry across all modes.

➡️ *Storage system is separated by platform (web vs. native), but shares unified interfaces for ViewModel abstraction.*

---

## Firebase Integration
- **Authentication**: Google/GitHub login
- **Hosting**: Firebase Hosting used for production deployment
- *(Planned)* Firestore-backed project/label persistence

---

## Web Hosting

The app is hosted in two flavors:

- **Production (Firebase Web App)**
  👉 https://zae-labeler.firebaseapp.com
  - Authenticated users (login required)

- **Development (GitHub Pages)**
  👉 https://zae-park.github.io/zae-labeler/
  - No login required (for demo/testing)

---

## Planned Features
- Segmentation Labeling
- Kakao & Naver OAuth login

---

## Development Tips
- Use `flutter test --coverage` to ensure high test quality
- Keep all mutable state inside ViewModels (not in views)
- Place platform-specific logic in `utils/` or `helpers/`
- Follow reusable widget patterns for layout and UI reuse
- Use `AppHeader` for consistent navigation and action structure

