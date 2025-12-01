# WhatsMocking

WhatsApp Mockup for testing Webhooks in your local environment.

## Overview

WhatsMocking is a Flutter MVP application that simulates a WhatsApp-like chat interface for testing REST API endpoints in your local development environment.

## Features

- 💬 Chat interface with message bubbles (WhatsApp-style)
- 📤 Send messages via POST requests
- 📥 Fetch messages from REST API
- 🔄 Automatic URL configuration for Android emulator and iOS simulator
- 📱 Material Design 3 with WhatsApp-inspired theme

## Architecture

The application follows the **Repository Pattern** for clean separation of concerns:

```
lib/
├── main.dart                           # App entry point
├── config/
│   └── api_config.dart                 # API URL configuration
├── data/
│   ├── models/
│   │   └── message.dart                # Message model with JSON serialization
│   └── repositories/
│       └── chat_repository.dart        # API operations using Dio
├── providers/
│   └── chat_provider.dart              # State management with Provider
└── screens/
    └── chat_screen.dart                # Chat UI with ListView
```

## Dependencies

- **Flutter/Dart**: UI framework
- **Provider**: State management
- **Dio**: HTTP client for networking

## API Configuration

The app automatically detects the platform and configures the API URL:

| Platform | Base URL |
|----------|----------|
| Android Emulator | `http://10.0.2.2:3000` |
| iOS Simulator | `http://localhost:3000` |
| Web | `http://localhost:3000` |

## API Endpoints

The app expects a REST API with the following endpoints:

### GET /messages
Fetches all messages.

**Response:**
```json
[
  {
    "id": "1",
    "content": "Hello!",
    "isSentByMe": true,
    "timestamp": "2024-01-15T10:30:00.000Z"
  }
]
```

### POST /messages
Sends a new message.

**Request:**
```json
{
  "content": "Hello World",
  "isSentByMe": true,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

**Response:**
```json
{
  "id": "2",
  "content": "Hello World",
  "isSentByMe": true,
  "timestamp": "2024-01-15T10:30:00.000Z"
}
```

## Getting Started

### Prerequisites

- Flutter SDK (3.0.0 or higher)
- A local REST API server running on port 3000

### Installation

1. Clone the repository:
```bash
git clone https://github.com/renatex333/whatsmocking.git
cd whatsmocking
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Running Tests

```bash
flutter test
```

## Example API Server

You can use a simple JSON server for testing:

```bash
npm install -g json-server
echo '{"messages":[]}' > db.json
json-server --watch db.json --port 3000
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
