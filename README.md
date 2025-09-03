[🎥 **Click here to watch the demo**](https://drive.google.com/file/d/1oOwJCeKk5FWWG3bFXaztnMBPR4a3Hn-m/view?usp=sharing)
# FitKnight - Fitness Community Platform

## Overview
FitKnight is a comprehensive fitness community platform that connects workout buddies and fitness groups. The application facilitates fitness enthusiasts in finding compatible workout partners and joining fitness groups based on shared interests, schedules, and locations.

## Features

### User Roles
1. **Workout Buddy**
   - Create and manage personal fitness profile
   - Set fitness goals and preferences
   - Specify workout availability
   - Connect with other workout buddies
   - Join fitness groups
   - Real-time chat with connections

2. **Group Organizer**
   - Create and manage fitness groups
   - Set group activities and schedules
   - Manage group members
   - View potential member suggestions
   - Communicate with group members

### Core Functionality

#### Authentication & Profile Management
- User registration with role selection
- Secure login/logout
- Profile customization
  - Profile picture upload
  - Personal information
  - Fitness goals
  - Workout preferences
  - Availability settings
  - Location settings

#### Workout Buddy Features
- Smart matching algorithm based on:
  - Location proximity
  - Schedule compatibility
  - Fitness interests
  - Workout preferences
- Match score calculation
- Recommended workout buddies list
- Detailed buddy profiles

#### Group Management
- Group creation with:
  - Group name
  - Activity type
  - Schedule
  - Description
  - Location
- Member management
  - Accept/reject join requests
  - Remove members
  - View member profiles
- Potential member suggestions based on:
  - Location matching
  - Schedule compatibility
  - Activity preferences

#### Communication
- Real-time chat functionality
  - Individual chats
  - Group chats
  - Message notifications
- Join request system
  - Send/receive group join requests
  - Accept/reject requests
  - Notification system

#### Search & Filtering
- Search workout buddies by:
  - Username
  - Location
  - Activity preferences
  - Availability
- Filter groups by:
  - Activity type
  - Location
  - Schedule

#### Notifications
- Real-time notifications for:
  - Chat messages
  - Join requests
  - Request responses
  - Group updates
- WebSocket connection for instant updates

### Technical Architecture

#### Frontend (Flutter)
- **State Management**: Provider pattern
- **Navigation**: Named routes
- **UI Components**:
  - Custom widgets for reusability
  - Material Design components
  - Responsive layouts
- **Asset Management**:
  - Image handling
  - Resource management

#### Backend Integration
- RESTful API communication
- WebSocket connections
- Token-based authentication
- Multipart form data handling
- Error handling and recovery

#### Data Management
- Secure token storage
- Shared preferences for user data
- File upload handling
- Cache management

### API Endpoints

#### Authentication
- POST `/api/login/` - User login
- POST `/api/register/` - User registration
- POST `/api/logout/` - User logout

#### Profile
- GET `/api/profile/` - Get user profile
- PUT `/api/profile/` - Update profile
- GET `/api/profile/?role=workout_buddy` - Get workout buddies
- GET `/api/profile/recommended-buddies/` - Get recommended buddies

#### Groups
- GET `/api/groups/` - List all groups
- POST `/api/groups/` - Create new group
- GET `/api/my-groups/` - List user's groups
- PUT `/api/groups/{id}/` - Update group
- DELETE `/api/groups/{id}/` - Delete group
- POST `/api/groups/{id}/join/` - Request to join group
- POST `/api/groups/{id}/leave/` - Leave group

#### Chat
- GET `/api/chat/rooms/` - List chat rooms
- POST `/api/chat/rooms/` - Create chat room
- GET `/api/chat/rooms/{id}/messages/` - Get room messages
- POST `/api/chat/rooms/{id}/messages/` - Send message
- WebSocket `/ws/chat/{room_id}/` - Real-time chat

#### Notifications
- GET `/api/notifications/` - List notifications
- PUT `/api/notifications/{id}/` - Mark as read
- WebSocket `/ws/notifications/` - Real-time notifications

### Security Features
- Token-based authentication
- Secure password handling
- Protected API endpoints
- WebSocket authentication
- Input validation
- Error handling

### Error Handling
- Network error recovery
- Token expiration handling
- Invalid input handling
- API error responses
- Graceful degradation

### Performance Optimization
- Lazy loading
- Caching strategies
- Image optimization
- Efficient API calls
- Background processes

## Installation

### Prerequisites
- Flutter SDK (latest stable version)
- Dart SDK
- Android Studio / Xcode
- Git

### Setup
1. Clone the repository:
   ```bash
   git clone [repository-url]
   ```

2. Install dependencies:
   ```bash
   flutter pub get
   ```

3. Configure environment:
   - Create `.env` file
   - Set API endpoints
   - Configure keys

4. Run the application:
   ```bash
   flutter run
   ```

### Development Commands
```bash
# Get packages
flutter pub get

# Update packages
flutter pub upgrade

# Clean build
flutter clean

# Run the app in debug mode
flutter run

# Run the app in release mode
flutter run --release

# Build APK
flutter build apk
```


## Development Guidelines

### Code Structure
- `lib/`
  - `models/` - Data models
  - `screens/` - UI screens
  - `widgets/` - Reusable widgets
  - `services/` - API services
  - `providers/` - State management
  - `utils/` - Utilities
  - `components/` - Complex components

### Detailed Folder Structure
```
fitknight/
├── android/                    # Android specific files
├── ios/                        # iOS specific files
├── lib/                        # Main source code
│   ├── components/             # Complex reusable components
│   │   ├── chat/              # Chat related components
│   │   │   ├── services/      # Chat services
│   │   │   ├── widgets/       # Chat UI components
│   │   │   └── group_chat.dart
│   │   └── edit_group_page.dart
│   ├── models/                # Data models
│   │   ├── buddy.dart        # Workout buddy model
│   │   ├── group.dart        # Group model
│   │   ├── profile.dart      # User profile model
│   │   ├── signup_form_data.dart
│   │   └── user_role.dart
│   ├── providers/            # State management
│   │   ├── auth_provider.dart
│   │   └── notification_provider.dart
│   ├── screens/              # App screens/pages
│   │   ├── buddy_finder_dashboard.dart
│   │   ├── group_organizer_dashboard.dart
│   │   ├── login_page.dart
│   │   ├── signup_page.dart
│   │   ├── profile_page.dart
│   │   └── notifications_page.dart
│   ├── services/             # API and business logic
│   │   ├── auth_service.dart
│   │   ├── buddy_finder_service.dart
│   │   ├── group_service.dart
│   │   ├── notification_service.dart
│   │   └── profile_service.dart
│   ├── utils/               # Utility functions and helpers
│   │   ├── dashboard_router.dart
│   │   └── constants.dart
│   └── widgets/             # Reusable UI components
│       ├── buddy/          # Buddy-related widgets
│       │   ├── buddy_card.dart
│       │   └── group_list_item.dart
│       ├── common/         # Common widgets
│       │   └── dashboard_app_bar.dart
│       ├── group/         # Group-related widgets
│       │   └── group_details/
│       ├── profile/       # Profile-related widgets
│       │   ├── profile_header.dart
│       │   ├── contact_info_card.dart
│       │   └── workout_preferences_card.dart
│       └── signup/        # Signup-related widgets
│           ├── workout_buddy_form.dart
│           └── group_organizer_form.dart
├── test/                  # Test files
│   ├── unit/             # Unit tests
│   ├── widget/           # Widget tests
│   └── integration/      # Integration tests
├── assets/               # Static assets
│   ├── images/          # Image assets
│   └── fonts/           # Font files
├── web/                  # Web-specific files
├── pubspec.yaml          # Project dependencies
├── pubspec.lock         # Lock file for dependencies
├── analysis_options.yaml # Dart analyzer settings
├── .gitignore           # Git ignore file
└── README.md            # Project documentation
```

### Best Practices
- Follow Flutter style guide
- Write meaningful comments
- Use consistent naming conventions
- Implement error handling
- Write unit tests
- Document code changes

### Contributing
1. Fork the repository
2. Create feature branch
3. Commit changes
4. Push to branch
5. Create Pull Request

## Testing
- Unit tests
- Widget tests
- Integration tests
- Manual testing checklist

## Deployment
- Version management
- Release process
- App store guidelines
- Backend deployment
- Monitoring setup

## Support
- Issue tracking
- Documentation
- Community guidelines
- Contact information

## License
[Add License Information]

## Authors
[Add Author Information]

## Acknowledgments
- Flutter team
- Contributors
- Third-party libraries




