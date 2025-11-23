# Server Integration Guide

## Setup Instructions

### 1. Start the Server

```bash
cd server
python3 -m pip install -r requirements.txt
python3 -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
```

Server will run at `http://localhost:8000`

### 2. Run Flutter App

```bash
flutter run
```

## How It Works

1. **User picks video** → Gemini generates captions with word timestamps
2. **User clicks Export** → App uploads video + captions to server
3. **Server processes** → Creates caption images with word highlighting → Uses FFmpeg to overlay on video
4. **App downloads** → Gets processed video and shares it

## Server Endpoints

- `POST /upload` - Upload video and captions
- `GET /status/{job_id}` - Check processing status
- `GET /download/{job_id}` - Download processed video

## Configuration

### Local Development
Server URL in `lib/main.dart`:
```dart
const String serverUrl = 'http://localhost:8000';
```

### Production
1. Deploy server to Railway/Render/Fly.io
2. Update server URL:
```dart
const String serverUrl = 'https://your-server.com';
```

## Testing

Use the test script to verify server:
```bash
cd server
python3 test_server.py
```

## Freemium Model

The server is ready for monetization:
- Free tier: Process videos up to 1 minute
- Premium: Unlimited video length + advanced effects

Add processing time limits in `processor.py` based on user subscription tier.
