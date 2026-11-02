# 🚀 SyncNest: Production-Grade Offline-First Flutter Application

[![Flutter](https://img.shields.io/badge/Flutter-3.13%2B-blue.svg)](https://flutter.dev)
[![State Management](https://img.shields.io/badge/State-BLoC%20%2F%20flutter__bloc-orange.svg)](https://pub.dev/packages/flutter_bloc)
[![Database](https://img.shields.io/badge/Database-Hive-green.svg)](https://pub.dev/packages/hive)
[![Network](https://img.shields.io/badge/Network-Dio-purple.svg)](https://pub.dev/packages/dio)

**SyncNest** is a production-ready, enterprise-grade **Offline-First Flutter Application** built with a robust, queue-based **Background Sync Engine**. It adheres strictly to industry best standards including **SOLID, DRY, KISS, Separation of Concerns, Clean Architecture, and Dependency Injection**.

---

## 🏗️ Architectural Overview

SyncNest implements a **Feature-First MVC Architecture** coupled with the **Repository Pattern** and **BLoC State Management**. The local database serves as the ultimate source of truth, ensuring the app remains 100% functional offline without depending on internet availability.

```
lib/
├── core/
│   ├── constants/
│   ├── errors/           # Centralized AppException hierarchy
│   ├── network/          # DioClient & ConnectivityService
│   ├── database/         # Hive service & adapters
│   ├── sync/             # SyncEngine, SyncQueue, ConflictResolver, RetryPolicy, SyncScheduler
│   └── di/               # GetIt Dependency Injection container
│
├── features/
│   └── tasks/            # Feature module (Tasks)
│       ├── model/        # TaskModel & SyncOperationModel
│       ├── view/         # TaskPage & UI components
│       ├── controller/   # TaskBloc, TaskEvent, TaskState
│       ├── repository/   # TaskRepository (Offline-First orchestration)
│       └── data/         # Local & Remote data sources
│
├── shared/
│   └── widgets/          # Reusable UI widgets (OfflineIndicator, SyncStatusIndicator, etc.)
│
└── main.dart
```

---

## 🔄 Offline-First & Sync Engine Flow

1. **User Action**: The user performs a mutation (Create, Update, Delete) while offline or online.
2. **Local Persistence**: The mutation is saved immediately to **Hive** local storage.
3. **UI Updates**: The BLoC updates the UI instantly.
4. **Sync Queue**: A persistent background sync operation (`CREATE`, `UPDATE`, `DELETE`) with an idempotency key is enqueued.
5. **Sync Engine**: When connectivity is restored (or via periodic timer / app resume), `SyncEngine` processes pending operations in dependency order using a single-flight mutex lock.
6. **Server Confirmation**: Upon success, local sync metadata is updated. If a conflict occurs, `ConflictResolver` applies deterministic resolution rules.

---

## 🛡️ Key Features & Engineering Standards

- **Local-First Source of Truth**: Never blocks the UI and never loses unsynchronized local data.
- **Persistent Sync Queue**: Survives application restarts and crashes.
- **Conflict Resolution**: Implements Last Write Wins (LWW) with logical revision tracking.
- **Exponential Backoff Retry**: Handles transient network errors with random jitter, respecting rate limits (HTTP 429) and server errors (HTTP 5xx).
- **Connectivity & App Lifecycle Monitoring**: Automatically syncs upon network restoration and app foreground resume.
- **Comprehensive Testing**: Fully tested BLoCs, repositories, and offline workflows.

---

## 🛠️ Technology Stack

- **Framework**: Flutter & Dart (SDK ^3.13.5)
- **State Management**: `flutter_bloc` (`^8.1.6`)
- **Local Database**: `hive` & `hive_flutter` (`^2.2.3`)
- **Networking**: `dio` (`^5.7.0`)
- **Connectivity**: `connectivity_plus` (`^6.1.0`)
- **Dependency Injection**: `get_it` (`^8.3.0`)
- **Identifiers**: `uuid` (`^4.6.0`)

---

## 🏁 Getting Started & Execution

### Prerequisites
- Flutter SDK installed (`^3.13.5` or higher)
- Android Studio / VS Code with Flutter extensions

### Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/sync_nest.git
   cd sync_nest
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

4. **Run tests**:
   ```bash
   flutter test
   ```

---

## 📄 License

This project is licensed under the MIT License.
