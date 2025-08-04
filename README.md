# 🎓 QR Attendance System

<div align="center">
  
[![Flutter](https://img.shields.io/badge/Flutter-02569B?style=for-the-badge&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-039BE5?style=for-the-badge&logo=Firebase&logoColor=white)](https://firebase.google.com)
[![Dart](https://img.shields.io/badge/Dart-0175C2?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev)

A comprehensive, modern Flutter application for managing student attendance using QR codes with advanced location-based verification. This system provides an efficient, secure, and scalable solution for educational institutions to track student attendance across different classes and courses.

</div>

## ✨ Key Features

### 🎯 Multi-User System

#### 👨‍🎓 **Student Portal**
- 📊 **Personal Dashboard**: Comprehensive attendance overview with visual analytics
- 📱 **Smart QR Scanner**: Time-based attendance marking with GPS proximity checks
  - ⏰ **10-Minute Window**: Attendance valid only within 10 minutes from class start
  - 🌍 **Location Verification**: GPS-based proximity authentication (50m radius)
  - 🚫 **Late Prevention**: Automatic blocking after attendance window expires
- 👤 **Profile Management**: Complete academic and personal information management
- 📈 **Analytics**: Detailed attendance statistics, trends, and performance insights
- 🔔 **Notifications**: Real-time class reminders and attendance updates
- 📱 **Offline Support**: Mark attendance offline and sync when connected

#### 👨‍🏫 **Faculty Portal**
- 🏫 **Class Management**: Create, schedule, and manage class sessions
- 🎯 **Smart QR Generation**: Secure, time-limited QR codes with automatic expiration
- 📊 **Real-time Monitoring**: Live attendance tracking during class sessions
- 👥 **Manual Attendance**: Add late students manually after 10-minute window expires
  - 🔍 **Student Search**: Search by roll number to find and add students
  - ➕ **Quick Addition**: One-click addition for late arrivals
  - ➖ **Attendance Management**: Remove students if needed
- 📈 **Analytics Dashboard**: Detailed class performance and student engagement metrics
- 📋 **Reports**: Comprehensive attendance reports with export functionality
- 🔔 **Student Notifications**: Send reminders and updates to students

#### 👨‍💼 **Admin Portal**
- 👥 **User Management**: Complete student and faculty account management
- 📊 **System Analytics**: Institution-wide statistics and performance metrics
- 🎯 **Department Insights**: Branch-wise attendance patterns and trends
- ⚠️ **Low Attendance Alerts**: Automated identification of at-risk students
- 📈 **Dashboard**: Comprehensive overview of system usage and statistics
- 🔧 **System Configuration**: Manage system settings and configurations

### 🚀 Advanced Features

#### 🔐 **Security & Authentication**
- 🔒 **Multi-layer Authentication**: Secure email/password with role-based access
- 🛡️ **Input Validation**: Comprehensive data sanitization and validation
- 🔑 **Secure QR Codes**: Encrypted, time-limited QR codes with digital signatures
- 🌍 **Location Verification**: GPS-based proximity checks for attendance authenticity
- 🔄 **Session Management**: Secure session handling with automatic timeout

#### 📡 **Offline & Sync**
- 📱 **Offline Capability**: Full functionality without internet connection
- 🔄 **Auto Sync**: Automatic data synchronization when connection is restored
- 💾 **Local Caching**: Intelligent caching system for improved performance
- 📊 **Sync Status**: Visual indicators for data synchronization status

#### 🔔 **Notifications & Alerts**
- 📢 **Push Notifications**: Firebase Cloud Messaging integration
- ⏰ **Class Reminders**: Automated reminders 15 minutes before class
- 📊 **Attendance Updates**: Real-time attendance confirmation notifications
- ⚠️ **System Alerts**: Important system updates and announcements

#### 📊 **Analytics & Reporting**
- 📈 **Advanced Analytics**: Comprehensive attendance insights and trends
- 📊 **Visual Charts**: Beautiful charts powered by FL Chart
- 📅 **Time-based Analysis**: Daily, weekly, monthly attendance patterns
- 🎯 **Subject-wise Reports**: Detailed performance by subject/course
- 🏆 **Performance Metrics**: Attendance streaks, percentages, and rankings

## 🏗️ Technical Architecture

### 🔧 **Technology Stack**

| Category | Technology | Purpose |
|----------|------------|----------|
| **Framework** | Flutter 3.8+ | Cross-platform mobile development |
| **Language** | Dart | Primary programming language |
| **Backend** | Firebase | Authentication, database, and messaging |
| **Database** | Cloud Firestore | NoSQL document database |
| **Authentication** | Firebase Auth | User authentication and authorization |
| **Messaging** | Firebase Messaging | Push notifications |
| **State Management** | Provider | Application state management |
| **Local Storage** | Hive | Offline data storage |
| **Networking** | Connectivity Plus | Network connectivity monitoring |
| **Location** | Geolocator | GPS location services |
| **QR Codes** | Mobile Scanner, QR Flutter | QR code scanning and generation |
| **Charts** | FL Chart | Data visualization |
| **Permissions** | Permission Handler | Device permissions management |

### 📁 **Project Structure**

```
qr_attendance_system/
├── 📁 lib/
│   ├── 📁 core/                    # Core utilities and services
│   │   ├── 📁 components/          # Reusable UI components
│   │   │   └── bottom_navigation_bar.dart
│   │   └── 📁 services/            # Core business services
│   │       ├── notification_service.dart    # Push & local notifications
│   │       ├── security_service.dart        # Security utilities
│   │       ├── offline_service.dart         # Offline functionality
│   │       └── analytics_service.dart       # Analytics & reporting
│   ├── 📁 data/                    # Data layer
│   │   ├── model.dart              # Data models (Student, Faculty, Class)
│   │   ├── attendance_provider.dart # Attendance state management
│   │   └── classes_provider.dart   # Classes state management
│   ├── 📁 features/                # Feature-specific code
│   │   └── 📁 authentication/      # Authentication services
│   │       └── firabse_auth_servise.dart
│   ├── 📁 screens/                 # UI screens
│   │   ├── 📁 admin/               # Admin interface
│   │   │   ├── admin_dashboard.dart
│   │   │   ├── faculty_management.dart
│   │   │   ├── student_management.dart
│   │   │   ├── statistics_screen.dart
│   │   │   ├── faculty_signin_screen.dart
│   │   │   └── student_signin.dart
│   │   ├── 📁 faculty/             # Faculty interface
│   │   │   ├── faculty_dashboard.dart
│   │   │   ├── add_class_screen.dart
│   │   │   ├── class_attendance_screen.dart
│   │   │   └── faculty_profile.dart
│   │   ├── 📁 student/             # Student interface
│   │   │   ├── student_app.dart    # Main student app with QR scanning
│   │   │   ├── student_dashboard.dart
│   │   │   └── student_profile.dart
│   │   └── 📁 auth/                # Authentication screens
│   │       └── login_screen.dart
│   ├── firebase_options.dart       # Firebase configuration
│   └── main.dart                   # Application entry point
├── 📁 android/                     # Android-specific configuration
│   └── 📁 app/src/main/
│       ├── AndroidManifest.xml     # Android permissions & config
│       └── google-services.json    # Firebase Android config
├── 📁 ios/                         # iOS-specific configuration
├── 📱 pubspec.yaml                 # Project dependencies
├── 🔥 firebase.json                # Firebase configuration
├── 🔥 firestore.indexes.json       # Firestore database indexes
└── 📄 README.md                    # Project documentation
```

## ⏰ Time-Based Attendance Workflow

### 🔄 **Attendance Process**

1. **📅 Class Creation**
   - Faculty creates a scheduled class with start and end times
   - System generates a unique, secure QR code for the class

2. **⏰ Attendance Window**
   - **Before Class**: QR scanner shows "Class hasn't started yet" with start time
   - **During Window** (0-10 minutes after start): Valid attendance marking period
   - **After Window** (>10 minutes): "You are late! Contact teacher" message

3. **🎯 Smart Validation**
   ```
   Class Start Time: 09:00 AM
   ├── 08:45 AM: ❌ Too Early ("Class hasn't started")
   ├── 09:00 AM: ✅ Valid Window Opens
   ├── 09:05 AM: ✅ Still Valid (within 10 minutes)
   ├── 09:10 AM: ✅ Last Valid Moment
   └── 09:11 AM: ❌ Too Late ("Contact teacher")
   ```

4. **📍 Location Verification**
   - GPS proximity check (50-meter radius)
   - Ensures physical presence at class location
   - Prevents remote attendance marking

5. **👨‍🏫 Faculty Override**
   - Manual addition of late students via attendance screen
   - Search by roll number for quick student lookup
   - Full control over final attendance list

### 🚦 **Student Experience**

| Scenario | Message | Action Available |
|----------|---------|------------------|
| **Too Early** | 🕐 "Class starts at [time]" | Wait for class to begin |
| **Valid Window** | ✅ Location verification → Success | Attendance marked |
| **Too Late** | ⏰ "You are late! Contact teacher" | Speak to faculty for manual addition |
| **Wrong Location** | 📍 "Too far from class ([distance]m)" | Move closer to classroom |

### 🎯 **Benefits**

- **⏰ Enforces Punctuality**: Students must arrive on time
- **🛡️ Prevents Fraud**: Location and time-based validation
- **🔄 Maintains Flexibility**: Faculty can manually add late students
- **📊 Better Analytics**: Accurate attendance timing data
- **🎓 Educational Value**: Teaches time management

## Setup Instructions

1. **Prerequisites**

   - Flutter SDK
   - Firebase account
   - Android Studio/VS Code

2. **Installation**

   ```bash
   # Clone the repository
   git clone https://github.com/Eshwar-ui/qr_attendance_system.git

   # Navigate to project directory
   cd qr_attendance_system

   # Install dependencies
   flutter pub get
   ```

3. **Firebase Setup**

   - Create a new Firebase project
   - Add Android/iOS apps in Firebase console
   - Download and add configuration files
   - Enable Authentication and Firestore

4. **Running the App**

   ```bash
   # Run in debug mode
   flutter run

   # Build release version
   flutter build apk  # For Android
   flutter build ios  # For iOS
   ```

## Security Features

- Secure authentication flow
- Protected routes and screens
- Data validation and sanitization
- Real-time data synchronization
- Error handling and logging

## Performance Optimizations

- Efficient state management
- Cached data handling
- Optimized database queries
- Minimal network requests
- Responsive UI design

## Contributing
```
https://github.com/Eshwar-ui/qr_attendance_system.git
```

Contributions are welcome! Please feel free to submit pull requests.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Support

For support, please contact [srirameshwarchandra@gmail.com] or raise an issue in the repository.
