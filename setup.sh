#!/bin/bash

# FoodSaver Project Setup Script
# This script automates the setup process for both backend and frontend

set -e

echo "🍎 FoodSaver Setup Script"
echo "========================="
echo ""

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if we're in the right directory
if [ ! -f "pubspec.yaml" ]; then
    echo -e "${RED}Error: pubspec.yaml not found. Please run this script from the FoodSaver root directory.${NC}"
    exit 1
fi

echo -e "${BLUE}Step 1: Installing Flutter Dependencies${NC}"
echo "========================================"
flutter pub get
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Flutter dependencies installed${NC}"
else
    echo -e "${RED}❌ Failed to install Flutter dependencies${NC}"
    exit 1
fi
echo ""

echo -e "${BLUE}Step 2: Installing Backend Dependencies${NC}"
echo "========================================"
if [ -d "backend/functions" ]; then
    cd backend/functions
    npm install
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ Backend dependencies installed${NC}"
    else
        echo -e "${RED}❌ Failed to install backend dependencies${NC}"
        exit 1
    fi
    cd ../..
else
    echo -e "${YELLOW}⚠️  backend/functions directory not found, skipping backend setup${NC}"
fi
echo ""

echo -e "${BLUE}Step 3: Checking Flutter Environment${NC}"
echo "======================================"
flutter doctor --no-analytics
echo ""

echo -e "${BLUE}Step 4: Configuring Firebase${NC}"
echo "============================="
echo -e "${YELLOW}Note: You need to configure Firebase separately.${NC}"
echo "Run: ${BLUE}flutterfire configure${NC}"
echo ""

echo -e "${BLUE}Step 5: Creating .env File${NC}"
echo "==========================="
if [ ! -f ".env" ]; then
    cat > .env << EOF
# Add your Gemini API Key here
GEMINI_API_KEY=your_api_key_here

# Firebase Configuration (auto-filled by flutterfire configure)
# FIREBASE_PROJECT_ID=your_project_id
EOF
    echo -e "${GREEN}✅ .env file created (update with your API keys)${NC}"
else
    echo -e "${YELLOW}⚠️  .env file already exists${NC}"
fi
echo ""

echo -e "${BLUE}Step 6: Checking Required Tools${NC}"
echo "================================="

# Check for required tools
tools=("flutter" "dart" "node" "npm" "firebase")
missing_tools=()

for tool in "${tools[@]}"; do
    if command -v $tool &> /dev/null; then
        version=$($tool --version 2>&1 | head -n 1)
        echo -e "${GREEN}✅${NC} $tool installed: $version"
    else
        echo -e "${RED}❌${NC} $tool not found"
        missing_tools+=("$tool")
    fi
done

if [ ${#missing_tools[@]} -eq 0 ]; then
    echo ""
    echo -e "${GREEN}All required tools are installed!${NC}"
else
    echo ""
    echo -e "${RED}Missing tools: ${missing_tools[*]}${NC}"
    echo "Please install the missing tools and run the script again."
fi
echo ""

echo -e "${BLUE}Step 7: Summary${NC}"
echo "==============="
echo ""
echo -e "${GREEN}Setup completed! Here's what you need to do next:${NC}"
echo ""
echo "1. Configure Firebase:"
echo -e "   ${BLUE}flutterfire configure${NC}"
echo ""
echo "2. Update your .env file with:"
echo -e "   ${BLUE}GEMINI_API_KEY=your_key_here${NC}"
echo ""
echo "3. Deploy backend functions:"
echo -e "   ${BLUE}cd backend/functions${NC}"
echo -e "   ${BLUE}npm run build${NC}"
echo -e "   ${BLUE}firebase deploy --only functions${NC}"
echo -e "   ${BLUE}cd ../..${NC}"
echo ""
echo "4. Run the app:"
echo -e "   ${BLUE}flutter run${NC}"
echo ""
echo "5. Read the documentation:"
echo -e "   ${BLUE}cat INTEGRATION_GUIDE.md${NC}"
echo -e "   ${BLUE}cat CONFIGURATION.md${NC}"
echo ""

echo -e "${GREEN}Happy coding! 🚀${NC}"
