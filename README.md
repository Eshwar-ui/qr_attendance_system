# QR Attendance System

A modern Flutter application for managing student attendance using QR codes. This system provides an efficient way for educational institutions to track student attendance across different classes and courses.

## Features

### Multi-User System

- **Student Portal**

  - View personal attendance records
  - Scan QR codes to mark attendance
  - Access personal profile and academic details
  - View attendance statistics and reports

- **Faculty Portal**

  - Create and manage classes
  - Generate QR codes for attendance
  - Monitor real-time attendance
  - View class-wise attendance reports
  - Track student participation

- **Admin Portal**
  - Manage student registrations
  - Handle faculty accounts
  - View system-wide statistics
  - Monitor attendance patterns
  - Generate comprehensive reports

### Core Functionalities

#### Authentication

- Secure email/password authentication
- Role-based access control (Student/Faculty/Admin)
- Automatic role detection and routing
- Secure session management

#### Student Management

- Complete student profile management
- Academic details tracking
  - Branch/Department
  - Year and Semester
  - Section allocation
- Contact information management

#### Class Management

- Dynamic class creation
- Scheduling system
- Real-time attendance tracking
- QR code generation for each session
- Attendance status monitoring (Active/Upcoming/Completed)

#### Attendance System

- QR code-based attendance marking
- Real-time attendance updates
- Attendance verification system
- Historical attendance records
- Statistical analysis and reporting

## Technical Details

### Architecture

The application follows a clean architecture pattern with:

- Provider pattern for state management
- Firebase services for backend operations
- Modular code organization

### Technology Stack

- **Frontend**: Flutter
- **Backend**: Firebase
  - Firebase Authentication
  - Cloud Firestore
  - Firebase Core
- **State Management**: Provider

### Project Structure

```
lib/
├── data/
│   ├── model.dart           # Data models
│   ├── attendance_provider.dart  # Attendance state management
│   └── classes_provider.dart     # Class state management
├── features/
│   └── authentication/      # Authentication services
├── screens/
│   ├── admin/              # Admin interface screens
│   ├── faculty/            # Faculty interface screens
│   ├── student/            # Student interface screens
│   └── auth/               # Authentication screens
└── main.dart               # Application entry point
```

## Setup Instructions

1. **Prerequisites**

   - Flutter SDK
   - Firebase account
   - Android Studio/VS Code

2. **Installation**

   ```bash
   # Clone the repository
   git clone [repository-url]

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
