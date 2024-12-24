# Picture Perfect

A social decision-making platform that allows users to create and participate in photo-based polls. Built with Flutter and Firebase, Picture Perfect helps users make better choices through community feedback.

## Features

- 📱 Cross-platform support (Web, iOS, Android, macOS, Windows)
- 📸 Create polls with two image options
- 🗳️ Vote on community polls
- 📊 View detailed poll results and statistics
- 👤 User profiles with voting history
- 🔒 Authentication and secure data storage
- 💾 Save favorite polls
- 📱 Responsive design for both mobile and web interfaces

## Architecture

Picture Perfect follows the Model-View-ViewModel (MVVM) architectural pattern for clean separation of concerns:

- **Models**: Data structures and business logic
- **ViewModels**: State management and business operations
- **Views**: UI components and user interaction

### Tech Stack

- **Frontend**: Flutter
- **Backend**: Firebase
- **Authentication**: Firebase Auth
- **Database**: Cloud Firestore
- **Storage**: Firebase Storage
- **State Management**: Provider

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- Firebase CLI
- Git

### Installation

1. Clone the repository

```bash
git clone https://github.com/yourusername/picture-perfect.git
cd picture-perfect
```

2. Install dependencies

```bash
flutter pub get
```

3. Configure Firebase

- Create a new Firebase project
- Add your Firebase configuration files:
  - `google-services.json` for Android
  - `GoogleService-Info.plist` for iOS
  - Configure web settings in `firebase_options.dart`

4. Run the app

```bash
flutter run
```

## Project Structure

```
lib/
├── main.dart
├── src/
│   ├── core/
│   │   ├── router/
│   │   ├── theme/
│   │   └── utils/
│   ├── data/
│   │   ├── models/
│   │   └── repositories/
│   └── presentation/
│       ├── pages/
│       ├── viewmodels/
│       └── widgets/
```

## Cloud Architecture

The app utilizes several Firebase services:

- **Authentication**: User management and secure access
- **Cloud Firestore**: NoSQL database for storing polls, user data, and votes
- **Cloud Storage**: Image storage for poll options
- **Security Rules**: Custom rules for data access control
- **Cloud Functions**: Serverless functions for background processing (optional)

## Responsive Design

Picture Perfect implements a responsive design strategy:

- Dynamic layouts that adapt to different screen sizes
- Optimized UI components for both mobile and web
- Different navigation patterns for mobile (bottom nav) and web (side nav)
- Appropriate image sizing and caching for different devices

## Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- Flutter team for the amazing framework
- Firebase team for the robust backend services
- All contributors and team members

## Contact

Donovan Harrison - donovan.harrison.swe@gmail.com
