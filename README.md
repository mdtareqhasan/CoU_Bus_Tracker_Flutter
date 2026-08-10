# 🚌 CoU Bus Tracker 
### Comilla University Transport Management System

[![Flutter](https://img.shields.io/badge/Flutter-3.5+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-00C7B7?logo=riverpod&logoColor=white)](https://riverpod.dev)
[![Backend](https://img.shields.io/badge/Backend-Spring_Boot_3-6DB33F?logo=springboot&logoColor=white)](https://spring.io/projects/spring-boot)
[![License](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

**CoU Bus Tracker** is a comprehensive transport management solution designed for the students, teachers, and staff of Comilla University. It provides real-time bus location tracking, intelligent scheduling, and emergency announcements in a beautiful, Bengali-first interface.

---

## ✨ Features

- 📍 **Live Bus Tracking**: Real-time location monitoring via high-performance WebView integration.
- 📅 **Smart Scheduling**: Automatically filters and displays bus timings based on the current day (Working days vs Weekends).
- ⚡ **Instant Loading (Local Caching)**: Data is cached locally for lightning-fast access and offline functionality.
- 🎨 **Premium UI/UX**: Modern design with vibrant gradients, glass-morphism elements, and smooth animations.
- 👤 **Role-Based Access**: Specialized views and login flows for Students and Teachers.
- 🔔 **Urgent Notices**: Instant access to administrative transport announcements.

---

## 🚀 Tech Stack

### Mobile App (Flutter)
- **State Management**: Riverpod (Reactive caching & updates)
- **Navigation**: GoRouter (Deep linking & query parameter support)
- **Networking**: Dio & HTTP (Parallel data fetching with error handling)
- **Persistence**: Flutter Secure Storage & SharedPreferences
- **Animations**: Flutter Animate (Modern entry & state-based transitions)

### Backend (Spring Boot) - *Separate Module*
- **Framework**: Spring Boot 3.3 (Java 21)
- **Security**: JWT (JSON Web Token) with BCrypt hashing
- **Database**: MySQL 8.0 with Flyway migrations
- **Documentation**: Swagger UI / OpenAPI 3

---

## 🛠️ Installation & Setup

1. **Clone the repository**:
   ```bash
   git clone https://github.com/your-username/cou_bus_tracker.git
   ```

2. **Install Dependencies**:
   ```bash
   flutter pub get
   ```

3. **Configure API Endpoints**:
   Update `lib/core/constants.dart` with your server IP:
   ```dart
   defaultValue: 'http://192.168.0.xxx:8080/api'
   ```

4. **Run the App**:
   ```bash
   flutter run
   ```

---

## 📸 Screenshots

| Home Dashboard | Bus List | Schedule Page | Live Tracking |
| :---: | :---: | :---: | :---: |
| ![Home](https://via.placeholder.com/200x400?text=Home) | ![Buses](https://via.placeholder.com/200x400?text=Bus+List) | ![Schedules](https://via.placeholder.com/200x400?text=Schedules) | ![Map](https://via.placeholder.com/200x400?text=Tracking) |

---

## 👨‍💻 Developer

**Md. Tareq Hasan**  
*Dept. of CSE, Batch 16*  
*Comilla University*

---

## ⚖️ License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
