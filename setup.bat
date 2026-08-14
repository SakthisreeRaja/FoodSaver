@echo off
REM FoodSaver Project Setup Script for Windows
REM This script automates the setup process for both backend and frontend

setlocal enabledelayedexpansion

echo.
echo 🍎 FoodSaver Setup Script
echo =========================
echo.

REM Check if we're in the right directory
if not exist "pubspec.yaml" (
    echo Error: pubspec.yaml not found. Please run this script from the FoodSaver root directory.
    exit /b 1
)

echo [1/6] Installing Flutter Dependencies
echo ======================================
flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo Failed to install Flutter dependencies
    exit /b 1
)
echo ✅ Flutter dependencies installed
echo.

echo [2/6] Installing Backend Dependencies
echo ======================================
if exist "backend\functions" (
    cd backend\functions
    call npm install
    if %ERRORLEVEL% NEQ 0 (
        echo Failed to install backend dependencies
        cd ..\..
        exit /b 1
    )
    echo ✅ Backend dependencies installed
    cd ..\..
) else (
    echo ⚠️ backend\functions directory not found, skipping backend setup
)
echo.

echo [3/6] Checking Flutter Environment
echo ===================================
flutter doctor --no-analytics
echo.

echo [4/6] Configuring Firebase
echo ==========================
echo Note: You need to configure Firebase separately.
echo Run: flutterfire configure
echo.

echo [5/6] Creating .env File
echo =========================
if not exist ".env" (
    (
        echo # Add your Gemini API Key here
        echo GEMINI_API_KEY=your_api_key_here
        echo.
        echo # Firebase Configuration (auto-filled by flutterfire configure^)
        echo # FIREBASE_PROJECT_ID=your_project_id
    ) > .env
    echo ✅ .env file created (update with your API keys^)
) else (
    echo ⚠️ .env file already exists
)
echo.

echo [6/6] Summary
echo =============
echo.
echo Setup completed! Here's what you need to do next:
echo.
echo 1. Configure Firebase:
echo    flutterfire configure
echo.
echo 2. Update your .env file with:
echo    GEMINI_API_KEY=your_key_here
echo.
echo 3. Deploy backend functions:
echo    cd backend\functions
echo    npm run build
echo    firebase deploy --only functions
echo    cd ..\..
echo.
echo 4. Run the app:
echo    flutter run
echo.
echo 5. Read the documentation:
echo    INTEGRATION_GUIDE.md
echo    CONFIGURATION.md
echo.
echo Happy coding! 🚀
echo.

pause
