# FitKnight - Fitness Community App

FitKnight is a Flutter-based mobile application that connects fitness enthusiasts and group organizers, facilitating workout partnerships and group fitness activities.

## Features

### User Roles
1. **Workout Buddy**
   - Create personal fitness profile
   - Set workout preferences and availability
   - Join fitness groups
   - Connect with other fitness enthusiasts
   - Track fitness goals and activities

2. **Group Organizer**
   - Create and manage fitness groups
   - Organize group activities
   - Manage member requests
   - Set group schedules and locations
   - Communicate with group members

### Key Features
- **User Authentication**
  - Secure login/signup system
  - Role-based access control
  - Alphanumeric password requirements
  - Session management

- **Profile Management**
  - Profile picture upload
  - Contact information
  - Workout preferences
  - Availability settings
  - Location settings

- **Group Management**
  - Create fitness groups
  - Join request system
  - Member management
  - Group activity scheduling
  - Group chat functionality

- **Real-time Notifications**
  - Join request notifications
  - Group updates
  - Activity reminders
  - Chat notifications

- **Search and Discovery**
  - Find workout buddies
  - Discover fitness groups
  - Search by location
  - Filter by preferences

## Technical Requirements

### Prerequisites
- Flutter SDK (>=3.4.3)
- Dart SDK (>=3.0.0)
- Android Studio / VS Code
- Android SDK (for Android development)
- Xcode (for iOS development)

### Dependencies
```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0
  shared_preferences: ^2.2.2
  flutter_local_notifications: ^18.0.1
  timezone: ^0.9.2
  path_provider: ^2.1.1
  image_picker: ^1.0.4
  file_picker: ^6.0.0
  provider: ^6.1.2
  web_socket_channel: ^3.0.1
```

## Setup Instructions

1. **Clone the Repository**
   ```bash
   git clone [repository-url]
   cd fitknight
   ```

2. **Install Dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Backend URL**
   - Update the base URL in `lib/services/auth_service.dart`
   - Update WebSocket URL in `lib/services/notification_service.dart`

4. **Run the Application**
   ```bash
   flutter run
   ```

## Project Structure

```
lib/
├── components/
│   ├── chat/
│   └── ...
├── models/
│   ├── user_role.dart
│   ├── profile.dart
│   ├── group.dart
│   └── ...
├── screens/
│   ├── login_page.dart
│   ├── signup_page.dart
│   ├── profile_page.dart
│   └── ...
├── services/
│   ├── auth_service.dart
│   ├── notification_service.dart
│   ├── group_service.dart
│   └── ...
├── utils/
│   └── dashboard_router.dart
└── widgets/
    ├── common/
    ├── group/
    ├── profile/
    └── signup/
```

## Security Features

1. **Authentication**
   - Token-based authentication
   - Secure password storage
   - Session management
   - Automatic logout on session expiry

2. **Password Requirements**
   - Minimum 6 characters
   - Alphanumeric characters only
   - Password confirmation
   - Secure password visibility toggle

3. **Data Protection**
   - Secure API communication
   - WebSocket security
   - Local data encryption
   - Privacy settings for user data

## API Integration

The app communicates with a RESTful backend API for:
- User authentication
- Profile management
- Group operations
- Real-time notifications via WebSocket
- File uploads
- Chat functionality

## Error Handling

- Comprehensive error messages
- User-friendly error dialogs
- Network error handling
- Session expiration handling
- Automatic reconnection for WebSocket

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

[Add your license information here]

## Contact

[Add your contact information here]
