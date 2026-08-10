<div align="center">

# 🚌 CoU Bus Tracker

### Comilla University Transport Management System

A comprehensive, real-time bus tracking and transport management application built with Flutter and Spring Boot for the students, teachers, and staff of Comilla University.

[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.5+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00C7B7?logo=riverpod&logoColor=white)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Backend-Spring_Boot_3-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 📋 Table of Contents

- [About the Project](#-about-the-project)
- [Key Features](#-key-features)
- [Screens & Navigation](#-screens--navigation)
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Data Models](#-data-models)
- [API Endpoints](#-api-endpoints)
- [Authentication Flow](#-authentication-flow)
- [Caching Strategy](#-caching-strategy)
- [Theme & Design System](#-theme--design-system)
- [Localization](#-localization)
- [Getting Started](#-getting-started)
- [Backend Setup](#-backend-setup)
- [Build & Release](#-build--release)
- [Platform Configuration](#-platform-configuration)
- [Troubleshooting](#-troubleshooting)

---

## 📖 About the Project

**CoU Bus Tracker** is a full-stack transport management solution designed specifically for **Comilla University**. It solves the everyday challenges faced by students, teachers, and staff in managing campus transportation by providing:

- **Real-time GPS tracking** of university buses via Leaflet maps
- **Intelligent schedule management** with automatic day-type detection
- **Emergency announcements** and transport notices
- **Role-based access** for Students and Teachers
- **Offline-first design** with local caching for instant data access

The app is built with a **Bengali-first** interface — all UI strings, error messages, and time formatting are in Bengali, making it accessible to all university members.

---

## ✨ Key Features

### 📍 Live Bus Tracking
- Real-time GPS location monitoring via high-performance WebView
- JavaScript injection to extract speed data from Leaflet tracker
- Auto-refresh capability with speed overlay widget
- In-app web view with hidden side panels for clean UX

### 📅 Smart Scheduling
- **Automatic day detection** — shows today's schedules by default
- **Three filter modes**: Today's List, Working Days (Sat–Thu), Weekend (Fri–Sat)
- **Direction filters**: All, Campus-bound (UP), From Campus (DOWN)
- **Search by time or route** with Bengali digit support
- Grouped by departure time with expandable tiles

### ⚡ Instant Loading (Cache-First)
- Data loaded from local cache instantly on app launch
- Network fetch happens in parallel in the background
- Cache validity checked via configurable `maxAge` timestamp
- Bus details pre-cached in background after bus list loads
- Offline banner displayed when network unavailable

### 🎨 Premium UI/UX
- Vibrant gradient headers (Indigo → Blue → Cyan)
- Glass-morphism elements with subtle shadows
- Smooth page transitions and staggered list animations
- Shimmer loading skeletons for all list views
- Animated counter widgets on dashboard stat cards

### 👤 Role-Based Authentication
- Separate login/registration flows for **Students** and **Teachers**
- JWT token-based authentication with encrypted storage
- Auto-restore session on app launch
- Automatic 401/403 handling with session clear

### 🔔 Emergency Notices
- Active university transport announcements
- Title, body, creation date, and expiry status
- Pull-to-refresh for latest updates

---

## 📱 Screens & Navigation

### Bottom Navigation (4 Tabs)

| Tab | Icon | Route | Description |
|-----|------|-------|-------------|
| **হোম** (Home) | Home | `/home` | Dashboard with stats, today's schedule, recent notices |
| **বাস** (Bus) | Bus | `/buses` | Searchable bus list with category filters |
| **সময়সূচি** (Schedule) | Schedule | `/schedules` | Tabbed schedule view (Student/Teacher) with filters |
| **প্রোফাইল** (Profile) | Person | `/profile` | Login prompt or user profile with logout |

### Full Screen Routes

| Screen | Route | Description |
|--------|-------|-------------|
| **Splash Screen** | `/splash` | Full-screen splash image, auto-navigates to home after 3s |
| **Bus Detail** | `/bus/:id` | Expanded bus info, driver details, schedules, live tracking button |
| **Live Tracking** | `/bus/live/:id` | WebView-based GPS tracker with speed overlay |
| **Role Selection** | `/auth/role` | Choose Student or Teacher role |
| **Login** | `/auth/login` | Email + password form with animated fields |
| **Registration** | `/auth/register` | Full registration with role-specific fields |
| **About Us** | `/about` | App info, CSE department credit, developer cards |

### Screen Descriptions

#### 🏠 Home Dashboard
The main screen displays:
- **Greeting header** with app logo on gradient background
- **4 stat cards**: Active Buses, Today's Trips, Live Tracking, Active Notices
- **Today's schedule preview** (up to 5 entries) with "See All" link
- **Recent notices** (up to 3 entries)
- **Error/offline card** with retry button when network fails
- **Pull-to-refresh** for manual data refresh

#### 🚌 Bus List
- **Search bar** to filter buses by name or number
- **Category filter chips**: All, Blue, Red, Teacher, Officer, Staff
- **Bus cards** showing: bus number, name, route, category badge, live indicator
- **Shimmer loading** skeleton while data loads
- **Tap to navigate** to bus detail page

#### 📅 Schedule Screen
- **Tabbed view**: Student Bus / Teacher Bus
- **Search bar** with Bengali hint text
- **Day type filter**: আজকের তালিকা (Today), কর্মদিবস (Working), শুক্র ও শনিবার (Weekend)
- **Direction filter**: সব (All), ক্যাম্পাস অভিমুখে (Campus-bound), ক্যাম্পাস থেকে (From Campus)
- **Expansion tiles** grouped by departure time with bus count
- **Schedule cards** with direction badge (UP=green, DOWN=amber)

#### 👤 Profile Screen
**Logged Out State:**
- Animated illustration with login prompt
- "Login / Register" button

**Logged In State:**
- Circular avatar with user initial
- Name, email, role badge (Student/Teacher)
- User info card
- Logout button with confirmation

---

## 🛠️ Tech Stack

### Mobile App (Flutter)

| Category | Package | Version | Purpose |
|----------|---------|---------|---------|
| **State** | flutter_riverpod | ^2.6.1 | Reactive state management with StateNotifier |
| **Routing** | go_router | ^14.8.1 | Declarative routing with ShellRoute |
| **Networking** | dio | ^5.7.0 | HTTP client with interceptors |
| **Networking** | connectivity_plus | ^6.1.2 | Network status detection |
| **Storage** | flutter_secure_storage | ^9.2.4 | Encrypted JWT token storage |
| **Storage** | shared_preferences | ^2.3.4 | Session data and cache |
| **UI** | google_fonts | ^6.2.1 | Inter + Plus Jakarta Sans fonts |
| **UI** | flutter_animate | ^4.5.2 | Page and widget animations |
| **UI** | shimmer | ^3.0.0 | Loading skeleton effects |
| **UI** | cached_network_image | ^3.4.1 | Network image caching |
| **UI** | badges | ^3.1.2 | Notification badge widgets |
| **UI** | flutter_staggered_animations | ^1.0.0 | Staggered list animations |
| **Image** | image_picker | ^1.1.2 | Camera/gallery image selection |
| **Web** | webview_flutter | ^4.9.0 | In-app GPS tracker WebView |
| **Utils** | url_launcher | ^6.3.1 | External URL launching |
| **Utils** | intl | 0.20.2 | Date formatting and i18n |
| **Utils** | equatable | ^2.0.7 | Value equality for Result types |
| **Code Gen** | json_annotation | ^4.9.0 | JSON serialization annotations |

### Code Generation (Dev Dependencies)

| Package | Version | Purpose |
|---------|---------|---------|
| build_runner | ^2.4.14 | Code generation runner |
| json_serializable | ^6.8.0 | Generates `.g.dart` model files |
| flutter_launcher_icons | ^0.13.1 | App icon generation |
| flutter_lints | ^5.0.0 | Lint rules |

### Backend (Spring Boot) — Separate Module

| Component | Technology |
|-----------|------------|
| **Framework** | Spring Boot 3.3 |
| **Language** | Java 21 |
| **Security** | JWT + BCrypt password hashing |
| **Database** | MySQL 8.0 |
| **Migrations** | Flyway |
| **ORM** | Spring Data JPA / Hibernate |
| **Documentation** | Swagger UI / OpenAPI 3 |
| **Server** | Embedded Tomcat (port 8080) |

---

## 🏗️ Architecture

### Overview

The app follows a **feature-first layered architecture** with clear separation of concerns:

```
┌─────────────────────────────────────────────────────┐
│                    UI Layer                          │
│  ConsumerWidget / ConsumerStatefulWidget            │
│  (ref.watch → rebuilds on state change)             │
├─────────────────────────────────────────────────────┤
│                 State Management                    │
│  StateNotifierProvider → StateNotifier              │
│  (manages state via copyWith pattern)               │
├─────────────────────────────────────────────────────┤
│                  Repository Layer                   │
│  BusRepository, ScheduleRepository, etc.            │
│  (handles API calls, returns Result<T>)             │
├─────────────────────────────────────────────────────┤
│                  Network Layer                      │
│  ApiClient (Dio) + AuthInterceptor                  │
│  (base URL, headers, JWT injection, error handling) │
├─────────────────────────────────────────────────────┤
│                  Storage Layer                      │
│  StorageService (SecureStorage + SharedPreferences) │
│  (tokens, session, cache)                           │
└─────────────────────────────────────────────────────┘
```

### Provider Hierarchy

```
storageServiceProvider (FutureProvider<StorageService>)
    │
    ▼
apiClientProvider (Provider<ApiClient>)
    │
    ├── busRepositoryProvider (Provider<BusRepository>)
    ├── scheduleRepositoryProvider (Provider<ScheduleRepository>)
    ├── noticeRepositoryProvider (Provider<NoticeRepository>)
    └── authRepositoryProvider (Provider<AuthRepository>)
```

### State Management Pattern

Each feature follows the same pattern:

```
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Widget     │────▶│   Provider   │────▶│   Notifier   │
│ (Consumer)   │     │ (StateNotifier│     │ (manages     │
│ ref.watch()  │     │  Provider)   │     │  state)      │
└──────────────┘     └──────────────┘     └──────┬───────┘
                                                  │
                                                  ▼
                                           ┌──────────────┐
                                           │  Repository  │
                                           │ (API calls)  │
                                           └──────┬───────┘
                                                  │
                                                  ▼
                                           ┌──────────────┐
                                           │  ApiClient   │
                                           │ (Dio + JWT)  │
                                           └──────────────┘
```

### Result Type Pattern

All repository methods return `Result<T>` — a sealed type:

```dart
sealed class Result<T> {}

class Success<T> extends Result<T> {
  final T data;
  Success({required this.data});
}

class Failure<T> extends Result<T> {
  final String message;
  Failure({required this.message});
}
```

Usage in widgets:

```dart
final result = await _busRepo.getBuses();
state = state.copyWith(
  buses: switch (result) {
    Success(:final data) => AsyncValue.data(data),
    Failure(:final message) => AsyncValue.error(message, StackTrace.current),
  },
);
```

---

## 📁 Project Structure

```
cou_bus_tracker/
├── android/                            # Android platform
│   └── app/
│       ├── build.gradle                # App config (namespace, SDK, signing)
│       └── src/main/
│           ├── AndroidManifest.xml     # Permissions, activities
│           └── res/
│               ├── mipmap-*/           # Launcher icons (mdpi → xxxhdpi)
│               ├── drawable-*/         # Adaptive icon foregrounds
│               └── values/
│                   └── colors.xml      # Icon background color
├── ios/                                # iOS platform
├── assets/
│   └── images/
│       ├── buslogo.jpeg               # App logo (used for icons + in-app)
│       ├── buslogo_padded.png         # Adaptive icon foreground (padded)
│       ├── splashpage.png             # Splash screen image
│       ├── deptlogo.jpg               # CSE department logo
│       ├── tareq.jpeg                 # Developer photo
│       └── atik_sir.jpg               # Advisor photo
├── lib/
│   ├── main.dart                      # Entry point + ProviderScope
│   │
│   ├── app/                           # App shell
│   │   ├── app.dart                   # MaterialApp.router (theme, locale, routes)
│   │   ├── router.dart                # GoRouter route definitions
│   │   ├── shell_screen.dart          # Bottom navigation shell
│   │   └── theme.dart                 # Material 3 theme (light + dark)
│   │
│   ├── core/                          # Shared infrastructure
│   │   ├── constants.dart             # API URLs, endpoints, storage keys
│   │   ├── api_client.dart            # Dio singleton + AuthInterceptor
│   │   ├── storage_service.dart       # Secure + SharedPreferences wrapper
│   │   ├── error_handler.dart         # Bengali error messages by status code
│   │   ├── result.dart                # Sealed Result<T> type
│   │   └── utils/
│   │       └── time_utils.dart        # Bengali time formatting, day detection
│   │
│   ├── shared/                        # Cross-feature shared code
│   │   ├── models/                    # 9 data models + .g.dart files
│   │   │   ├── bus.dart
│   │   │   ├── bus_detail.dart
│   │   │   ├── schedule.dart
│   │   │   ├── notice.dart
│   │   │   ├── auth_response.dart
│   │   │   ├── student.dart
│   │   │   ├── login_request.dart
│   │   │   ├── student_register_request.dart
│   │   │   └── teacher_register_request.dart
│   │   └── widgets/                   # Reusable UI components
│   │       ├── bus_card.dart
│   │       ├── schedule_card.dart
│   │       ├── stat_card.dart
│   │       └── live_indicator.dart
│   │
│   └── features/                      # Feature modules
│       ├── providers.dart             # Central provider registry
│       │
│       ├── auth/                      # Authentication
│       │   ├── auth_provider.dart     # AuthNotifier + AuthState
│       │   ├── auth_repository.dart   # Login/register API calls
│       │   ├── role_screen.dart       # Student/Teacher selection
│       │   ├── login_screen.dart      # Login form
│       │   └── register_screen.dart   # Registration form
│       │
│       ├── buses/                     # Bus management
│       │   ├── buses_provider.dart    # BusListNotifier
│       │   ├── bus_repository.dart    # Bus API calls
│       │   ├── bus_list_screen.dart   # Bus list with search/filter
│       │   └── bus_detail_screen.dart # Bus detail + live tracking
│       │
│       ├── schedules/                 # Schedule management
│       │   ├── schedules_provider.dart # ScheduleListNotifier + filters
│       │   ├── schedule_repository.dart # Schedule API calls
│       │   └── schedule_screen.dart   # Schedule list with tabs/filters
│       │
│       ├── notices/                   # Notice management
│       │   ├── notices_provider.dart  # NoticeListNotifier
│       │   ├── notice_repository.dart # Notice API calls
│       │   └── notice_screen.dart     # Notice list
│       │
│       ├── home/                      # Dashboard
│       │   ├── home_provider.dart     # DashboardNotifier (loads all data)
│       │   └── home_screen.dart       # Dashboard with stats/schedule/notice
│       │
│       ├── profile/                   # User profile
│       │   └── profile_screen.dart    # Login prompt or user info
│       │
│       └── about/                     # About page
│           └── about_screen.dart      # App info, department, developers
│
├── build/                             # Build artifacts (gitignored)
├── pubspec.yaml                       # Dependencies & assets
└── README.md                          # This file
```

---

## 📦 Data Models

### Bus

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int?` | Unique identifier |
| `busNumber` | `String?` | Bus registration number |
| `busName` | `String?` | Display name |
| `category` | `String?` | Blue / Red / Teacher / Officer / Staff |
| `route` | `String?` | Route description |
| `driverName` | `String?` | Assigned driver |
| `driverPhone` | `String?` | Driver contact |
| `busImageUrl` | `String?` | Bus photo URL |
| `trackerUrl` | `String?` | GPS tracker URL (Leaflet) |
| `isActive` | `bool` | Currently operational |

### Schedule

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int?` | Unique identifier |
| `busId` | `int?` | Associated bus |
| `busNumber` | `String?` | Bus number |
| `busName` | `String?` | Bus name |
| `category` | `String?` | Bus category |
| `departureTime` | `String?` | Departure time (HH:mm) |
| `arrivalTime` | `String?` | Arrival time (HH:mm) |
| `direction` | `String?` | UP (to campus) / DOWN (from campus) |
| `startPoint` | `String?` | Departure location |
| `endPoint` | `String?` | Destination |
| `days` | `String?` | Active days (SAT-THU, FRI-SAT, etc.) |

### Notice

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int?` | Unique identifier |
| `title` | `String?` | Notice title |
| `body` | `String?` | Notice content |
| `isActive` | `bool` | Currently active |
| `createdAt` | `String?` | Creation timestamp |
| `expiresAt` | `String?` | Expiry timestamp |

### AuthResponse

| Field | Type | Description |
|-------|------|-------------|
| `accessToken` | `String` | JWT token |
| `tokenType` | `String` | "Bearer" |
| `displayName` | `String?` | User display name |
| `name` | `String?` | Full name |
| `email` | `String?` | Email address |
| `role` | `String?` | STUDENT / TEACHER |

### Student

| Field | Type | Description |
|-------|------|-------------|
| `id` | `int?` | Unique identifier |
| `name` | `String?` | Full name |
| `email` | `String?` | University email |
| `studentId` | `String?` | Student ID number |
| `department` | `String?` | Department name |
| `varsityBatch` | `String?` | Batch year |
| `idCardImageUrl` | `String?` | ID card photo URL |
| `isEduMail` | `bool` | Educational email verified |
| `isVerified` | `bool` | Account verified |
| `isActive` | `bool` | Account active |

All models use `@JsonSerializable()` for automatic JSON serialization via `build_runner`.

---

## 🔌 API Endpoints

**Base URL**: Configurable via `--dart-define=API_BASE_URL=...`, defaults to `http://localhost:8080/api`

### Public Endpoints (No Auth)

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/buses` | `GET` | List all buses (optional `?category=` filter) |
| `/buses/{id}` | `GET` | Bus detail with embedded schedules |
| `/schedules` | `GET` | All schedules |
| `/schedules/bus/{busId}` | `GET` | Schedules filtered by bus |
| `/notices/active` | `GET` | Active notices |

### Auth Endpoints

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/auth/student/register` | `POST` | No | Register new student |
| `/auth/student/login` | `POST` | No | Student login (returns JWT) |
| `/auth/teacher/register` | `POST` | No | Register new teacher |
| `/auth/teacher/login` | `POST` | No | Teacher login (returns JWT) |

### Protected Endpoints (JWT Required)

| Endpoint | Method | Auth | Description |
|----------|--------|------|-------------|
| `/auth/student/me` | `GET` | ✅ | Get student profile |
| `/auth/student/upload-id-card` | `POST` | ✅ | Upload ID card image |

---

## 🔐 Authentication Flow

```
┌─────────────────────────────────────────────────────────────┐
│                    AUTHENTICATION FLOW                       │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  1. User opens Profile tab                                  │
│       │                                                      │
│       ▼                                                      │
│  2. Role Selection Screen                                   │
│     ┌──────────┐        ┌──────────┐                        │
│     │ Student  │        │ Teacher  │                        │
│     └────┬─────┘        └────┬─────┘                        │
│          │                    │                              │
│          ▼                    ▼                              │
│  3. Login / Register Screen                                │
│     (Email + Password + role-specific fields)               │
│          │                                                   │
│          ▼                                                   │
│  4. API Call → POST /auth/{role}/login                      │
│          │                                                   │
│          ▼                                                   │
│  5. JWT Token Received                                     │
│          │                                                   │
│          ├──▶ Stored in FlutterSecureStorage (encrypted)    │
│          └──▶ User data in SharedPreferences               │
│                                                              │
│  6. AuthInterceptor auto-attaches Bearer token              │
│     to all subsequent API requests                          │
│                                                              │
│  7. On 401/403 → Session cleared, state reset              │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Token Storage Keys

| Key | Storage | Description |
|-----|---------|-------------|
| `access_token` | SecureStorage | JWT access token |
| `user_role` | SharedPreferences | STUDENT / TEACHER |
| `display_name` | SharedPreferences | User display name |
| `user_email` | SharedPreferences | User email |
| `user_id` | SharedPreferences | User ID |

---

## 🔄 Caching Strategy

The app implements a **cache-first, network-second** pattern for optimal performance:

```
┌─────────────────────────────────────────────────────────────┐
│                    CACHING FLOW                              │
├─────────────────────────────────────────────────────────────┤
│                                                              │
│  App Launch                                                  │
│       │                                                      │
│       ▼                                                      │
│  ┌──────────────┐                                           │
│  │ Read Cache   │ ← Instant (SharedPreferences)            │
│  └──────┬───────┘                                           │
│         │                                                    │
│         ▼                                                    │
│  ┌──────────────┐                                           │
│  │ Show Cached  │ ← Immediate UI with data                 │
│  │ Data         │                                           │
│  └──────┬───────┘                                           │
│         │                                                    │
│         ├──▶ Network Fetch (parallel)                       │
│         │         │                                          │
│         │         ▼                                          │
│         │   ┌──────────────┐                                │
│         │   │ Update Cache │ ← Replace old data            │
│         │   └──────────────┘                                │
│         │                                                    │
│         └──▶ If network fails:                              │
│               Show "Offline" banner with cached data        │
│                                                              │
└─────────────────────────────────────────────────────────────┘
```

### Cache Keys

| Key | Content | Pre-cached? |
|-----|---------|-------------|
| `cached_buses` | Bus list JSON | No (fetched on load) |
| `cached_schedules` | Schedule list JSON | No (fetched on load) |
| `cached_notices` | Notice list JSON | No (fetched on load) |
| `cached_bus_detail_{id}` | Individual bus detail | ✅ Yes (background pre-cache) |
| `cache_timestamp` | Last cache update time | — |

### Cache Validity

- Configurable `maxAge` (default: 5 minutes via `ApiConstants.cacheMaxAge`)
- Checked via `StorageService.isCacheValid()`
- Stale cache still displayed with offline indicator

---

## 🎨 Theme & Design System

### Color Palette

| Color | Hex | Usage |
|-------|-----|-------|
| **Primary Blue** | `#3886D8` | Primary actions, selected states, links |
| **Secondary Blue** | `#5BA4FB` | Gradient endpoints, accents |
| **Primary Dark** | `#2C6BB1` | Gradient start, emphasis |
| **Accent Blue** | `#E1EBFD` | Light blue highlights |
| **Background Light** | `#F6F9FE` | Screen background |
| **Surface Light** | `#FFFFFF` | Card backgrounds |
| **Text Primary** | `#1E293B` | Headings, main text |
| **Text Secondary** | `#64748B` | Descriptions, subtitles |
| **Text Hint** | `#94A3B8` | Placeholder text |
| **Success Green** | `#10B981` | Success states, UP direction |
| **Warning Amber** | `#F59E0B` | Warnings, DOWN direction |
| **Error Red** | `#EF4444` | Errors, destructive actions |

### Gradient

```dart
// Primary gradient used across app bars, buttons, headers
LinearGradient(
  colors: [Color(0xFF20146B), Color(0xFF1D64C2), Color(0xFF19D0D8)],
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
)
```

### Typography

| Style | Font | Weight | Size | Usage |
|-------|------|--------|------|-------|
| Headline Large | Plus Jakarta Sans | Bold | 28px | Screen titles |
| Headline Medium | Plus Jakarta Sans | Bold | 22px | Section headers |
| Title Large | Plus Jakarta Sans | SemiBold | 18px | Card titles |
| Body Large | Inter | Regular | 16px | Body text |
| Body Medium | Inter | Regular | 14px | Descriptions |
| Body Small | Inter | Regular | 12px | Captions, labels |

### Spacing Scale

| Token | Value | Usage |
|-------|-------|-------|
| `space4` | 4px | Minimal gaps |
| `space8` | 8px | Tight spacing |
| `space12` | 12px | Small spacing |
| `space16` | 16px | Medium spacing |
| `space24` | 24px | Standard padding |
| `space32` | 32px | Section gaps |
| `space48` | 48px | Large section gaps |
| `space64` | 64px | Page-level gaps |

### Border Radius

| Token | Value | Usage |
|-------|-------|-------|
| `radiusSmall` | 8px | Small elements |
| `radiusMedium` | 12px | Cards, chips |
| `radiusLarge` | 16px | Large cards |
| `radiusExtraLarge` | 24px | Bottom sheets, modals |

---

## 🌐 Localization

### Language Support

- **Primary**: Bengali (`bn_BD`) — all UI strings hardcoded in Bengali
- **Secondary**: English (`en_US`) — supported locale

### Bengali Time Formatting

The app converts 24-hour time to Bengali format:

| Time Range | Bengali Period | Example |
|------------|----------------|---------|
| 05:00–11:59 | সকাল (Morning) | সকাল ৮:৩০ |
| 12:00–14:59 | দুপুর (Afternoon) | দুপুর ১:১৫ |
| 15:00–17:59 | বিকাল (Evening) | বিকাল ৪:৪৫ |
| 18:00–04:59 | রাত (Night) | রাত ৯:০০ |

### Bengali Error Messages

| Status Code | Bengali Message |
|-------------|-----------------|
| 400 | তথ্য সঠিক নয়। আবার চেষ্টা করুন। |
| 401 | সেশন শেষ হয়েছে। আবার সাইন ইন করুন। |
| 403 | অনুমতি নেই। |
| 404 | তথ্যটি পাওয়া যায়নি। |
| 409 | এই ইমেইল ইতিমধ্যে ব্যবহৃত হয়েছে। |
| 500 | সার্ভারে সমস্যা হয়েছে। কিছুক্ষণ পর আবার চেষ্টা করুন। |
| Timeout | সংযোগ সময় শেষ হয়েছে। আবার চেষ্টা করুন। |
| Network | ইন্টারনেট সংযোগ পরীক্ষা করুন। |

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** 3.5+ (`flutter --version` to check)
- **Dart SDK** 3.5+ (included with Flutter)
- **Android Studio** or **VS Code** with Flutter extension
- **Java 17** (for Android builds)
- **Spring Boot backend** running (see Backend Setup)

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/your-username/cou_bus_tracker.git
cd cou_bus_tracker

# 2. Install Flutter dependencies
flutter pub get

# 3. Generate model serialization files
dart run build_runner build --delete-conflicting-outputs

# 4. Generate app icons
dart run flutter_launcher_icons

# 5. Run the app
flutter run
```

### API Configuration

Configure the backend URL based on your setup:

```bash
# Android Emulator (default)
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api

# Physical device via USB (adb reverse)
adb reverse tcp:8080 tcp:8080
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8080/api

# Custom server
flutter run --dart-define=API_BASE_URL=http://192.168.1.100:8080/api
```

The default URL is configured in `lib/core/constants.dart`:

```dart
static String get baseUrl {
  const define = String.fromEnvironment('API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080/api');
  return define;
}
```

---

## ⚙️ Backend Setup

The Flutter app connects to a **Spring Boot 3** backend. The backend must:

### Requirements

- Run on **port 8080**
- Bind to `0.0.0.0` for emulator/device access
- Implement JWT authentication
- Use MySQL 8.0 with Flyway migrations

### Application Properties

```yaml
spring:
  profiles:
    active: dev
  jpa:
    hibernate:
      ddl-auto: none
    show-sql: false
  flyway:
    enabled: true
    locations: classpath:db/migration
    baseline-on-migrate: true

server:
  port: 8080
  address: 0.0.0.0

jwt:
  secret: YourSuperSecretKeyForJWTTokenGenerationMustBeLongEnough2024!
  expiration: 86400000

springdoc:
  api-docs:
    path: /api-docs
  swagger-ui:
    path: /swagger-ui.html
```

### Database Tables

The backend expects these tables (managed by Flyway):

- `admins` — Admin users (id, name, email, password, created_at)
- `buses` — Bus records (id, bus_number, bus_name, category, route, driver_name, driver_phone, bus_image_url, is_active, created_at)
- `tracker_links` — GPS tracker URLs (id, bus_id, tracker_url, expires_at, updated_at, updated_by)
- `schedules` — Bus schedules (id, bus_id, departure_time, arrival_time, direction, start_point, end_point, days, category)
- `notices` — Announcements (id, title, body, is_active, created_at, expires_at)
- `students` — Student accounts (id, name, email, password, student_id, department, varsity_batch, id_card_image_url, is_edu_mail, is_verified, is_active, created_at)
- `teachers` — Teacher accounts (id, name, email, password, designation, department, phone)

---

## 📦 Build & Release

### Android

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# Release App Bundle (for Play Store)
flutter build appbundle --release
```

### iOS

```bash
# Debug
flutter build ios --debug

# Release
flutter build ios --release
```

> **Note**: Release signing is currently using debug keys. Configure proper keystore signing before production release.

---

## 📱 Platform Configuration

### Android

| Setting | Value |
|---------|-------|
| Namespace | `com.cse.coubustracker.cou_bus_tracker` |
| Min SDK | Flutter default |
| Target SDK | Flutter default |
| Compile SDK | Flutter default |
| Java/Kotlin | Java 17 / JVM 17 |
| Cleartext | Enabled |
| Hardware Acceleration | Enabled |
| Launch Mode | singleTop |

### iOS

| Setting | Value |
|---------|-------|
| Display Name | CoU Bus Tracker |
| Bundle Name | cou_bus_tracker |
| Orientations | Portrait, Landscape |
| ProMotion | Enabled |
| Multiple Scenes | Not supported |

---

## 🔧 Troubleshooting

### Common Issues

#### 1. `No MaterialLocalizations found`
**Cause**: Missing localization delegates.
**Fix**: Ensure `localizationsDelegates` are added to `MaterialApp.router` in `app.dart`.

#### 2. Connection Timeout
**Cause**: Emulator/device can't reach the backend.
**Fix**:
- Emulator: Use `http://10.0.2.2:8080/api`
- Physical device: Use `adb reverse tcp:8080 tcp:8080` and `http://127.0.0.1:8080/api`
- Ensure backend binds to `0.0.0.0`

#### 3. App Icon Zoomed/Cropped
**Cause**: Adaptive icon foreground lacks transparent padding.
**Fix**: Use `flutter_launcher_icons` with properly padded foreground image.

#### 4. `build_runner` Errors
**Cause**: Conflicting generated files.
**Fix**:
```bash
dart run build_runner build --delete-conflicting-outputs
```

#### 5. White Screen on Launch
**Cause**: Backend not running or unreachable.
**Fix**: Start the Spring Boot backend and verify connectivity.

---

<div align="center">

**Built with ❤️ for Comilla University**

</div>
