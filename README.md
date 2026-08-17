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
- [Authentication & Registration](#-authentication--registration)
- [Caching Strategy](#-caching-strategy)
- [Theme & Design System](#-theme--design-system)
- [Getting Started](#-getting-started)
- [Backend Setup](#-backend-setup)

---

## 📖 About the Project

**CoU Bus Tracker** is a full-stack transport management solution designed specifically for **Comilla University**. It solves campus transport challenges by providing real-time tracking, intelligent scheduling, and public announcements via a **Bengali-first** premium interface.

---

## ✨ Key Features

### 📍 Smart Live Tracking
- **Real-time Status Detection**: Automatically identifies if a bus is **চলমান (Moving)** or **থেমে আছে (Stopped)**.
- **Live Distance Calculation**: Shows real-time distance from the user to the bus (e.g., **আপনার থেকে: ৪.৫ কিমি**) using GPS.
- **Stylish Dashboard**: Modern floating speedometer and status pulse animations.
- **In-app Map**: High-performance WebView with Leaflet integration and custom UI cleanup.

### 📅 Intelligent Scheduling
- **Automatic Day Detection**: Shows relevant schedules based on the current day.
- **Multiple Filter Views**: Switch between Today's list, Working Days (Sat–Thu), and Weekend (Fri–Sat).
- **Search & Filter**: Find buses by name, time, or route with full support for Bengali search.

### ⚡ Lightning-Fast Performance
- **Local Storage Caching**: Data loads instantly from local storage for zero wait time.
- **Bulk Pre-caching**: Automatically fetches and saves all bus details in the background upon app launch.
- **Background Sync**: Updates cached data silently when internet is available.

### 🎨 Premium Visuals & UX
- **Stylish Gradients**: Modern 3-tone vertical gradient (Dark Indigo → Vibrant Blue → Bright Cyan).
- **Interactive Animations**: Smooth transitions, scale effects, and heartbeat pulses for live states.
- **Clean Forms**: Redesigned Role Selection, Login, and Registration pages with modern cards.

---

## 🔐 Authentication & Registration

The app features a robust authentication module synchronized with the Spring Boot security layer:

- **Enhanced Registration**: Supports **Multipart/form-data** for Students and Teachers.
- **Mandatory ID Card Upload**: Users must upload a clear photo (JPG/PNG) of their University ID card.
- **Google Sign-In**: Seamless one-tap login with smart redirection for first-time users.
- **Detailed Validation**: Displays field-specific error messages directly from the backend (e.g., "Invalid Batch Format").
- **Secure Storage**: JWT tokens and session data are stored using `FlutterSecureStorage` with encryption.

---

## 📱 Screens & Navigation

| Tab/Screen | Description |
| :--- | :--- |
| **🏠 Home** | Overview stats (Active Buses, Trips), Today's schedule preview, and Transport Notices. |
| **🚌 Bus List** | Full directory of university buses with real-time "Running" indicators and category filtering. |
| **📅 Schedule** | Complete week-long schedule with tabbed views for Students and Teachers. |
| **👤 Profile** | Personal user info, verification status, and secure Logout functionality. |
| **📍 Tracking** | Interactive map with live speed, status, and distance from user location. |
| **ℹ️ About Us** | Project credits for CSE Dept, Advisor info, and developer profiles. |

---

## 🛠️ Tech Stack

- **Flutter 3.5+**: Cross-platform framework.
- **Riverpod**: Reactive state management and caching.
- **Dio & HTTP**: Networking with Multipart and Interceptor support.
- **Geolocator**: Real-time GPS distance calculation.
- **Flutter Animate**: Modern state-based animations.
- **Image Picker**: For mandatory ID card selection.
- **GoRouter**: Feature-rich declarative navigation.

---

## 🚀 Getting Started

### Prerequisites
- Flutter SDK 3.5+
- Spring Boot backend (Module-2) running on port 8080.

### Installation
1.  **Clone the repo**: `git clone https://github.com/your-username/cou_bus_tracker.git`
2.  **Install dependencies**: `flutter pub get`
3.  **Configure API**: Update `lib/core/constants.dart` with your server IP (defaults to `10.0.2.2` for emulator).
4.  **Run**: `flutter run`

---

<div align="center">

**Developed by Md. Tareq Hasan**  
*Dept. of CSE, Batch 16, Comilla University*  
*Project Consultant: Raihan Khan (CSE 10 Batch)*

</div>
