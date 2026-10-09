# SWR Playground

A lightweight project to practice the **Stale-While-Revalidate (SWR)** caching strategy alongside **MVVM-C (Model-View-ViewModel-Coordinator)** architecture.

## Key Features & Tech Stack

- **Architecture:** `MVVM-C` (Model-View-ViewModel-Coordinator) for clean business logic separation and decoupled navigation flow.
- **Concurrency & Caching Strategy:** `AsyncThrowingStream` driving the **Stale-While-Revalidate (SWR)** caching pattern with data fetched from the network and cached via NSCache.
- **State Management:** `Combine` for reactive state management.
- **UI & Skeleton Loaders:** `UITableViewDiffableDataSource` for UI updates and paired with custom fixed placeholders while observing data.
- **Testing:** Unit test covering the **Data**, **Domain**, and **Presentation** layers.

## Architecture & Data Flow

```text
[View Controller] ──( Combine State )──> [ViewModel]
                                              │
                                    (AsyncThrowingStream)
                                              ▼
                                         [Repository]
                                         ╱          ╲
                          (Stale Data)  ╱            ╲  (Fresh Data)
                                       ▼              ▼
                                [Local Cache]    [Network API]
                                  (NSCache)      (URLSession)
```

## Prerequisites
- **Xcode:** 15.0 or later
- **iOS Target:** iOS 15.0+
- **Language:** Swift 5.9+

## 📂 Project Structure

```text
SWRPlayground/
├── Application/        # App Delegate, Scene Delegate, App Coordinator
├── Presentation/       # ViewControllers, ViewModels, States, UI Components
├── Domain/             # Entities, Repository Interfaces, Use Cases
├── Data/               # Repository Implementations, Network Client, Cache Manager
└── SWRPlaygroundTests/ # Unit Tests (Data, Domain, Presentation)
```
