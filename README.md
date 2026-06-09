# Pauselock - Deadlock Stats Tracker

A modern web application for tracking Deadlock game statistics, builds, and player profiles.

## Features

- **Player Stats**: View your stats and other players' stats
- **Hero Browser**: Browse all heroes with stats and meta information
- **Build System**: Discover, create, and save builds for any hero
- **Leaderboards**: Track top players across regions
- **Win Rates**: View hero win rates and meta snapshots
- **User Accounts**: Save favorite builds and track your progress
- **Modern Design**: Dark mode with glassmorphism aesthetic

## Tech Stack

### Backend
- **Dart HTTP server** - Lightweight JSON API with in-memory starter data
- **Deadlock API** - Data source (https://deadlock-api.com/)

### Frontend
- **Flutter Web** - Dart frontend framework
- **go_router** - Navigation
- **glassmorphism** - Glass effect widgets
- **google_fonts** - Typography

## Setup Instructions

### Prerequisites
- Flutter SDK (3.0+)
- Dart SDK

### Backend Setup

1. Navigate to the server directory:
```bash
cd pauselock-server
```

2. Install dependencies:
```bash
dart pub get
```

3. Run the server:
```bash
dart bin/server.dart
```

### Frontend Setup

1. Navigate to the app directory:
```bash
cd pauselock-app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the web app:
```bash
flutter run -d chrome
```

## Project Structure

```
pauselock/
├── pauselock-server/     # Dart JSON API backend
│   ├── lib/
│   │   ├── server.dart
│   │   └── src/
│   │       ├── endpoints/
│   │       ├── models/
│   │       └── services/
│   └── config/
│
└── pauselock-app/        # Flutter frontend
    ├── lib/
    │   ├── main.dart
    │   └── src/
    │       ├── pages/
    │       ├── widgets/
    │       ├── theme/
    │       └── services/
    └── pubspec.yaml
```

## API Endpoints

### Player Endpoints
- `GET /player/stats?accountId=<id>` - Get player stats
- `GET /player/search?query=<query>` - Search players

### Hero Endpoints
- `GET /hero/all` - Get all heroes
- `GET /hero/all?limit=<n>` - Get a limited hero list
- `GET /hero/<id>` - Get hero by ID
- `GET /hero/meta` - Get meta heroes

### Build Endpoints
- `GET /build/all` - Get all builds
- `GET /build/featured?limit=<n>` - Get featured builds
- `GET /build/<id>` - Get build by ID

### Stats Endpoints
- `GET /stats/global` - Get global stats
- `GET /stats/leaderboard` - Get leaderboard

## Environment Variables

Optional server environment:
```
PORT=8080
DEADLOCK_API_URL=https://api.deadlock-api.com
DEADLOCK_ASSETS_API_URL=https://assets.deadlock-api.com
```

## License

MIT License

## Disclaimer

This is an unofficial fan-made project. Deadlock is a trademark of Valve Corporation.
