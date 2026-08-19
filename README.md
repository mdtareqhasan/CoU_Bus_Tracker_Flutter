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
- [Tech Stack](#-tech-stack)
- [Architecture](#-architecture)
- [Project Structure](#-project-structure)
- [Screens & Navigation](#-screens--navigation)
- [Authentication & Registration](#-authentication--registration)
- [API Endpoints](#-api-endpoints)
- [State Management](#-state-management)
- [Theme & Design System](#-theme--design-system)
- [Error Handling](#-error-handling)
- [Storage & Caching](#-storage--caching)
- [Interceptor Setup](#-interceptor-setup)
- [Getting Started](#-getting-started)
- [Backend Setup](#-backend-setup)
- [Models](#-models)
- [Shared Widgets](#-shared-widgets)

---

## 📖 About the Project

**CoU Bus Tracker** is a full-stack transport management solution designed specifically for **Comilla University**. It solves campus transport challenges by providing real-time tracking, intelligent scheduling, and public announcements via a **Bengali-first** premium interface.

The app serves three user roles — **Students**, **Teachers**, and **Staff** — with role-based bus filtering, ensuring each user sees only the buses relevant to them.

---

## ✨ Key Features

### 📍 Smart Live Tracking
- **Real-time Status Detection**: Automatically identifies if a bus is **চলমান (Moving)** or **থেমে আছে (Stopped)**.
- **Live Distance Calculation**: Shows real-time distance from the user to the bus (e.g., **আপনার থেকে: ৪.৫ কিমি**) using GPS.
- **Stylish Dashboard**: Modern floating speedometer and status pulse animations.
- **In-app Map**: High-performance WebView with Leaflet integration and custom UI cleanup.

### 📅 Intelligent Scheduling
- **Automatic Day Detection**: Shows relevant schedules based on the current day (working days vs. weekend).
- **Role-Based Filtering**: Students see only student buses (BLUE, RED, STAFF); teachers see only teacher buses (TEACHER, OFFICER).
- **Multiple Filter Views**: Switch between Today's list, Working Days (Sat–Thu), and Weekend (Fri–Sat).
- **Search & Filter**: Find buses by name, time, or route with full support for Bengali search.
- **Direction Filters**: Filter by ক্যাম্পাস অভিমুখে (Campus-bound) or ক্যাম্পাস থেকে (Campus-departing).

### 🔐 Secure Authentication
- **Email OTP Verification**: 6-digit OTP sent to email, 5-minute expiry, 60-second resend cooldown.
- **Google Sign-In**: Seamless one-tap login with smart redirection for first-time users.
- **Multipart Registration**: ID card upload with client-side compression to ≤300 KB.
- **Session Validation**: Token verified against backend on every app launch.
- **Auto-Logout**: Automatic logout when admin deletes/rejects a user (401/403 handling).

### ⚡ Lightning-Fast Performance
- **Local Storage Caching**: Data loads instantly from local storage for zero wait time.
- **Bulk Pre-caching**: Automatically fetches and saves all bus details in the background upon app launch.
- **Background Sync**: Updates cached data silently when internet is available.
- **Offline-First**: App works with cached data when backend is unreachable.

### 🎨 Premium Visuals & UX
- **Stylish Gradients**: Modern 3-tone vertical gradient (Dark Indigo → Vibrant Blue → Bright Cyan).
- **Interactive Animations**: Smooth transitions, scale effects, and heartbeat pulses for live states.
- **Clean Forms**: Redesigned Role Selection, Login, and Registration pages with modern cards.
- **Bengali-First UI**: All labels, error messages, and notifications in Bengali with English fallback.

---

## 🛠️ Tech Stack

### Frontend (Flutter)
| Package | Version | Purpose |
|---|---|---|
| `flutter_riverpod` | ^2.6.1 | State management |
| `dio` | ^5.7.0 | HTTP client with interceptors |
| `go_router` | ^14.8.1 | Declarative routing |
| `flutter_secure_storage` | ^9.2.4 | Encrypted storage (tokens) |
| `shared_preferences` | ^2.3.4 | Key-value local storage |
| `google_sign_in` | ^6.2.1 | Google OAuth |
| `image_picker` | ^1.1.2 | Camera/gallery image selection |
| `flutter_image_compress` | ^2.5.1 | Client-side image compression |
| `geolocator` | ^13.0.1 | Device GPS location |
| `webview_flutter` | ^4.9.0 | In-app WebView (live tracking) |
| `connectivity_plus` | ^6.1.2 | Network connectivity detection |
| `flutter_animate` | ^4.5.2 | Animation framework |
| `flutter_staggered_animations` | ^1.0.0 | Staggered list animations |
| `cached_network_image` | ^3.4.1 | Network image caching |
| `google_fonts` | ^6.2.1 | Custom typography (Inter, Plus Jakarta Sans) |
| `shimmer` | ^3.0.0 | Loading shimmer effects |
| `url_launcher` | ^6.3.1 | Open URLs in browser |
| `mime` | ^2.0.0 | MIME type detection |
| `http_parser` | ^4.0.0 | HTTP media type parsing |
| `intl` | 0.20.2 | Internationalization utilities |
| `equatable` | ^2.0.7 | Value equality for models |
| `json_annotation` | ^4.9.0 | JSON serialization annotations |

### Backend (Spring Boot)
- **Java 17+** with Spring Boot 3
- **JWT Authentication** with role-based access control
- **Cloudinary** for image storage
- **SMTP** for OTP email delivery
- **PostgreSQL** database

---

## 🏗️ Architecture

The project follows a **feature-first clean architecture** pattern:

```
lib/
  app/        → Shell layer (routing, theming, localization, global navigation)
  core/       → Infrastructure layer (API client, storage, error handling, constants)
  features/   → Feature modules, each self-contained:
                  - Screen(s) (UI)
                  - Provider (Riverpod StateNotifier)
                  - Repository (data access, API calls)
  shared/     → Cross-feature layer:
                  - models/   (data classes shared across features)
                  - widgets/  (reusable UI components shared across features)
```

### Key Patterns

- **State Management**: Riverpod with `StateNotifier` + `StateNotifierProvider`
- **Data Flow**: `Screen → Provider → Repository → ApiClient (Dio) → Backend`
- **Result Pattern**: Sealed `Result<T>` class (`Success`, `Failure`, `Loading`, `Empty`) propagates through the repository layer
- **Dependency Injection**: All providers centralized in `lib/features/providers.dart`
- **Caching**: Every provider loads from local cache first, then refreshes from network
- **Localization**: Bengali-first UI with English locale support

---

## 📁 Project Structure

```
lib/
├── main.dart                    # Entry point; initializes StorageService
├── app/
│   ├── app.dart                 # MaterialApp.router with session-expiry wiring
│   ├── shell_screen.dart        # Bottom navigation shell (4 tabs)
│   ├── router.dart              # GoRouter configuration with all routes
│   └── theme.dart               # Full design system (colors, spacing, typography)
├── core/
│   ├── api_client.dart          # Dio HTTP client with 3 interceptors
│   ├── constants.dart           # Base URL, API endpoints, storage keys, timeouts
│   ├── error_handler.dart       # Centralized Bengali error messages
│   ├── result.dart              # Sealed Result<T> class
│   ├── storage_service.dart     # Dual-storage (SecureStorage + SharedPreferences)
│   └── utils/
│       └── time_utils.dart      # Bengali time formatting
├── features/
│   ├── providers.dart           # Central Riverpod provider definitions
│   ├── auth/                    # Login, Register, OTP, Google Sign-In, Upload ID
│   ├── home/                    # Dashboard home screen + provider
│   ├── buses/                   # Bus list, bus detail, live tracking + provider
│   ├── schedules/               # Schedule screen + provider + repository
│   ├── notices/                 # Notice screen + provider + repository
│   ├── splash/                  # Splash screen with server warm-up
│   ├── profile/                 # Profile screen
│   └── about/                   # About Us screen
├── shared/
│   ├── models/                  # 9 data models (AuthResponse, Bus, Schedule, etc.)
│   └── widgets/                 # 4 reusable widgets (BusCard, ScheduleCard, etc.)
└── assets/
    └── images/                  # App images (logo, splash, developer photos)
```

---

## 📱 Screens & Navigation

| Route | Screen | Description |
|---|---|---|
| `/splash` | `SplashScreen` | Initial route with 3s animation + server warm-up |
| `/auth/role` | `RoleScreen` | Role selection (Student / Teacher) |
| `/auth/login` | `LoginScreen` | Email/password + Google Sign-In |
| `/auth/register` | `RegisterScreen` | Full registration with ID card upload |
| `/auth/otp` | `EmailOtpVerificationScreen` | 6-digit OTP verification |
| `/home` | `HomeScreen` | Dashboard with stats, today's schedule, notices |
| `/buses` | `BusListScreen` | Bus directory with role-based category filtering |
| `/schedules` | `ScheduleScreen` | Role-filtered schedule with day/direction filters |
| `/notices` | `NoticeScreen` | Active transport notices |
| `/profile` | `ProfileScreen` | User info, verification status, logout |
| `/bus/:id` | `BusDetailScreen` | Bus detail with embedded schedules |
| `/bus/live/:id` | `LiveTrackingScreen` | WebView GPS tracking map |
| `/about` | `AboutScreen` | Project credits and developer profiles |

**Shell Route**: Bottom navigation with 4 tabs — Home, Buses, Schedules, Profile. Uses `NoTransitionPage` for instant tab switching.

---

## 🔐 Authentication & Registration

### Registration Flow
1. **Role Selection** → Student or Teacher
2. **ID Card Upload** → Pick from gallery, auto-compress to ≤300 KB
3. **Form Submission** → Multipart/form-data with image + fields
4. **Email OTP** → 6-digit code sent to email
5. **Verification** → Enter OTP → Account activated

### Login Flow
1. **Role Selection** → Student or Teacher
2. **Credentials** → Email + Password, or Google Sign-In
3. **Token Storage** → JWT stored in encrypted FlutterSecureStorage
4. **Session Validation** → Token verified against backend on every app launch

### Session Security
- **Token Validation**: Profile endpoint called on startup to verify token validity
- **Auto-Logout**: Dio interceptor catches 401/403 → clears all data → navigates to role screen
- **Admin Deletion**: When admin deletes/rejects a user, next API call triggers automatic logout
- **No Duplicate Requests**: Retry interceptor never retries POST/PUT/DELETE

### Image Compression
- **Target**: ≤300 KB per image
- **Algorithm**: Iterative quality + dimension reduction (up to 10 passes)
- **Format Preservation**: PNG stays PNG when possible; falls back to JPEG for size
- **MIME Validation**: Only JPG, JPEG, PNG allowed

---

## 🌐 API Endpoints

**Base URL**: `https://cou-bus-tracker-backend-admin-frontend.onrender.com/api`

| Endpoint | Method | Description |
|---|---|---|
| `/buses` | GET | List all buses |
| `/buses/{id}` | GET | Bus detail with schedules |
| `/schedules` | GET | List all schedules |
| `/schedules/bus/{busId}` | GET | Schedules for a specific bus |
| `/notices/active` | GET | Active notices |
| `/auth/student/register` | POST | Student registration (multipart) |
| `/auth/student/login` | POST | Student login |
| `/auth/teacher/register` | POST | Teacher registration (multipart) |
| `/auth/teacher/login` | POST | Teacher login |
| `/auth/admin/login` | POST | Admin login |
| `/auth/google/login` | POST | Google Sign-In |
| `/auth/student/me` | GET | Student profile (token validation) |
| `/auth/teacher/me` | GET | Teacher profile (token validation) |
| `/auth/student/upload-id-card` | POST | Upload student ID card |
| `/auth/teacher/upload-id-card` | POST | Upload teacher ID card |
| `/auth/email-verification/verify` | POST | Verify OTP |
| `/auth/email-verification/resend` | POST | Resend OTP |

**Timeouts**: Connect: 30s | Send: 60s | Receive: 90s

---

## 📊 State Management

### Central Providers (`lib/features/providers.dart`)

| Provider | Type | Purpose |
|---|---|---|
| `storageServiceProvider` | `Provider<StorageService>` | Root-level storage injection |
| `apiClientProvider` | `Provider<ApiClient>` | Singleton Dio client |
| `busRepositoryProvider` | `Provider<BusRepository>` | Bus API calls |
| `scheduleRepositoryProvider` | `Provider<ScheduleRepository>` | Schedule API calls |
| `noticeRepositoryProvider` | `Provider<NoticeRepository>` | Notice API calls |
| `authRepositoryProvider` | `Provider<AuthRepository>` | Auth API calls |

### Feature Providers

| Provider | Feature | State Class |
|---|---|---|
| `authProvider` | Auth | `AuthState` (status, role, email, error) |
| `dashboardProvider` | Home | Dashboard aggregation state |
| `busListProvider` | Buses | Bus list with filtering/search |
| `scheduleListProvider` | Schedules | Schedule list with filters |
| `noticeListProvider` | Notices | Active notices list |

---

## 🎨 Theme & Design System

### Colors
| Name | Hex | Usage |
|---|---|---|
| `primaryBlue` | `#3886D8` | Primary brand color |
| `secondaryBlue` | `#5BA4FB` | Secondary accent |
| `primaryDark` | `#2C6BB1` | Darker variant |
| `accentBlue` | `#E1EBFD` | Light accent backgrounds |
| `backgroundLight` | `#F6F9FE` | Scaffold background |
| `surfaceLight` | `#FFFFFF` | Card surfaces |
| `textPrimary` | `#1E293B` | Primary text |
| `textSecondary` | `#64748B` | Secondary text |
| `textHint` | `#94A3B8` | Hint text |
| `successGreen` | `#10B981` | Success states |
| `warningAmber` | `#F59E0B` | Warning states |
| `errorRed` | `#EF4444` | Error states |

### Gradient
```
Deep Indigo #20146B → Vibrant Blue #1D64C2 → Bright Cyan #19D0D8
```

### Typography
- **Headlines**: Plus Jakarta Sans (bold, tight letter-spacing)
- **Body**: Inter (regular weight)

### Spacing Scale
`space4` (4) → `space8` (8) → `space12` (12) → `space16` (16) → `space24` (24) → `space32` (32) → `space40` (40) → `space48` (48) → `space64` (64)

### Border Radii
`radiusSmall` (8) → `radiusMedium` (12) → `radiusLarge` (16) → `radiusExtraLarge` (32)

---

## ⚠️ Error Handling

### HTTP Status Code Mapping
| Code | Bengali Message |
|---|---|
| 400 | তথ্য সঠিক নয়। আবার চেষ্টা করুন। |
| 401 | সেশন শেষ হয়েছে। আবার সাইন ইন করুন। |
| 403 | অনুমতি নেই। |
| 404 | তথ্য পাওয়া যায়নি। |
| 409 | এই ইমেইল ইতিমধ্যে ব্যবহৃত হচ্ছে। |
| 500 | সার্ভারে সমস্যা। পরে আবার চেষ্টা করুন। |
| 502/503/504 | সার্ভার চালু হচ্ছে বা সাময়িকভাবে ব্যস্ত। ১–২ মিনিট পরে আবার চেষ্টা করুন। |

### Error Types
- `serverBusyMessage` — Render cold-start / overload
- `timeoutMessage` — Connection timeout
- `networkMessage` — No internet connection
- `sessionExpired` — Token expired
- `otpInvalid` / `otpExpired` / `otpExceeded` — OTP-specific errors

### `friendly()` Method
Translates English backend errors to Bengali by pattern matching (e.g., "invalid otp" → "কোডটি সঠিক নয়। আবার চেষ্টা করুন।").

---

## 💾 Storage & Caching

### Dual-Storage Architecture

**FlutterSecureStorage** (encrypted):
- `access_token` — JWT token
- `token_type` — Bearer token type
- `pending_verification_email` — Email awaiting OTP
- `pending_verification_role` — Role awaiting OTP

**SharedPreferences** (plain):
- `user_role`, `display_name`, `user_email`, `user_id`
- `is_verified`, `is_edu_mail`
- `_has_token` — Boolean flag for quick auth check
- `cached_buses`, `cached_schedules`, `cached_notices` — JSON string caches
- Cache timestamps for 24-hour validity

### Caching Strategy
- **Cache-first**: Every provider loads from local cache first
- **Network refresh**: Fetches from API and updates cache in background
- **Offline-first**: App works with cached data when backend is unreachable
- **Pre-caching**: All bus details pre-cached on app launch

---

## 🔧 Interceptor Setup

Three interceptors are configured on the Dio instance:

### 1. AuthInterceptor
- **onRequest**: Reads JWT from secure storage, injects `Authorization: Bearer` header
- **onError**: On 401/403 with auth header → clears all storage + caches → fires `onSessionExpired` callback → force logout + SnackBar + navigate to `/auth/role`
- **Guard**: `_handlingExpiry` flag prevents duplicate expiry handling

### 2. RetryOnColdStartInterceptor
- **Purpose**: Handles Render.com free-tier cold starts (server sleeps after inactivity)
- **Scope**: Only retries **GET/HEAD** requests (never POST/PUT/DELETE)
- **Logic**: Up to 2 retries with 3s/6s exponential backoff
- **Safety**: Skips requests already retried (`extra['_retryCount']`)

### 3. LogInterceptor
- **Body logging disabled**: `requestBody: false`, `responseBody: false`
- **Security**: OTPs, Google ID tokens, passwords, JWTs never written to logs

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Dart SDK 3.5+
- Spring Boot backend running on port 8080

### Installation

1. **Clone the repo**:
   ```bash
   git clone https://github.com/your-username/cou_bus_tracker.git
   cd cou_bus_tracker
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API** (optional):
   ```bash
   # Default: https://cou-bus-tracker-backend-admin-frontend.onrender.com/api
   # For local development:
   flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8080/api
   ```

4. **Run**:
   ```bash
   flutter run
   ```

### Build

```bash
# Android APK
flutter build apk --release

# iOS
flutter build ios --release
```

---

## ⚙️ Backend Setup

The backend is a **Spring Boot 3** application with:

- **Java 17+**
- **Spring Security** with JWT authentication
- **PostgreSQL** database
- **Cloudinary** for image storage
- **SMTP server** for OTP email delivery

### Required Backend Endpoints
- `POST /auth/student/register` — Multipart registration
- `POST /auth/student/login` — Email/password login
- `POST /auth/teacher/register` — Multipart registration
- `POST /auth/teacher/login` — Email/password login
- `POST /auth/google/login` — Google OAuth
- `GET /auth/student/me` — Token validation (must return 401 for deleted users)
- `GET /auth/teacher/me` — Token validation (must return 401 for deleted users)
- `POST /auth/email-verification/verify` — OTP verification
- `POST /auth/email-verification/resend` — OTP resend
- `GET /buses` — Public bus list
- `GET /buses/{id}` — Bus detail with schedules
- `GET /schedules` — Public schedule list
- `GET /notices/active` — Active notices

### Important Notes
- The profile endpoints (`/auth/student/me`, `/auth/teacher/me`) **must validate JWT tokens** and return 401 for deleted/rejected users
- The bus, schedule, and notice endpoints are **public** and do not require authentication
- Cloudinary is server-side only; no Cloudinary keys in Flutter

---

## 📦 Models

| Model | Fields | Description |
|---|---|---|
| `AuthResponse` | accessToken, tokenType, role, id, name, email, isVerified, isEduMail | Auth response from all endpoints |
| `LoginRequest` | email, password | Login request body |
| `Bus` | id, busNumber, busName, category, route, driverName, driverPhone, busImageUrl, trackerUrl, isActive | Bus entity |
| `BusDetail` | extends Bus + schedules | Bus with embedded schedules |
| `Schedule` | id, busId, busNumber, busName, category, departureTime, arrivalTime, direction, startPoint, endPoint, days | Schedule entity |
| `Notice` | id, title, body, isActive, createdAt, expiresAt | Notice entity |
| `Student` | id, name, email, studentId, department, varsityBatch, idCardImageUrl, isEduMail, isVerified, isActive, createdAt | Student profile |

---

## 🧩 Shared Widgets

| Widget | Description |
|---|---|
| `BusCard` | Bus card with category color coding, bus number, route, and live indicator |
| `ScheduleCard` | Schedule card with direction badge, route display, and Bengali time |
| `StatCard` | Dashboard stat card with animated counter and icon |
| `LiveIndicator` | Green pulsing dot indicating real-time tracking availability |

---

## 📄 License

This project is licensed under the MIT License.

---

<div align="center">

**Developed by Md. Tareq Hasan**
*Dept. of CSE, Batch 16, Comilla University*
*Project Consultant: Raihan Khan (CSE 10 Batch)*

</div>
