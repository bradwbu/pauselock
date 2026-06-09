#!/bin/bash
# Pauselock Setup Script

echo "Setting up Pauselock - Deadlock Stats Tracker"
echo "============================================"

# Check if Dart is installed
if ! command -v dart &> /dev/null; then
    echo "Dart is not installed. Please install Dart SDK first."
    exit 1
fi

# Check if Flutter is installed
if ! command -v flutter &> /dev/null; then
    echo "Flutter is not installed. Please install Flutter SDK first."
    exit 1
fi

echo "Setting up Serverpod backend..."
cd pauselock-server
dart pub get
echo "Serverpod dependencies installed."

echo "Setting up Flutter frontend..."
cd ../pauselock-app
flutter pub get
echo "Flutter dependencies installed."

echo ""
echo "Setup complete!"
echo ""
echo "Next steps:"
echo "1. Set up MySQL database 'pauselock' and update pauselock-server/config/server.yaml"
echo "2. Run 'dart run serverpod create-migrations' in pauselock-server"
echo "3. Run 'dart run serverpod apply-migrations' in pauselock-server"
echo "4. Start server: cd pauselock-server && dart bin/server.dart"
echo "5. Start frontend: cd pauselock-app && flutter run -d chrome"
echo ""
echo "Visit http://localhost:8080 for the API and http://localhost:3000 for the web app"
