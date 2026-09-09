# Gemma Test

A mini Flutter app for testing running a local AI model (Gemma) on mobile devices.

## Overview

This application demonstrates how to integrate and run the Gemma AI model locally on an Android device using Flutter. It's designed for development and testing purposes.

⚠️ **Note**: This app is for testing and development only. It should **not be shipped to production**.

## Prerequisites

- Flutter SDK installed
- Android SDK/Android Studio (for Android builds)
- A [HuggingFace](https://huggingface.co) account with API access

## Setup Instructions

### 1. Create Configuration File

The app requires a `config.json` file to run. Follow these steps:

1. Copy the example configuration file:
   ```bash
   cp config.json.example config.json
   ```

2. Edit the `config.json` file and add your HuggingFace token:
   ```json
   {
     "huggingface_token": "your_huggingface_token_here"
   }
   ```

### 2. Get Your HuggingFace Token

1. Go to [huggingface.co](https://huggingface.co)
2. Sign up or log in to your account
3. Navigate to your account settings → Access Tokens
4. Create a new token with read access
5. Copy the token and paste it into your `config.json` file

### 3. Compile the App

```bash
flutter pub get
flutter build apk --dart-define-from-file=config.json
```

## Features

- Downloads and runs the Gemma AI model locally
- No internet required after initial model download
- Demonstrates local AI inference on mobile devices

## Important Notes

- **Development Only**: This is a testing application and is not suitable for production use.
- **Model Size**: The Gemma model is large; ensure you have sufficient device storage and RAM.
- **Privacy**: Models run locally on your device; no data is sent to external servers.

## Troubleshooting

- Ensure your `config.json` file is properly formatted
- Verify your HuggingFace token has the necessary permissions
- Check that you have sufficient storage space for the Gemma model
- Review app permissions for file access and network access
