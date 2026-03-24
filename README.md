# Agora Voice Call with RTM and RTC Integration

This project demonstrates the integration of Agora's Real-Time Messaging (RTM) and Real-Time Communication (RTC) SDKs with Firebase Cloud Messaging (FCM) for a voice call application. It allows users to make and receive voice calls with real-time signaling and communication.

---

## Features
- **RTM v2.2.x**: Used for signaling and messaging between caller and callee.
- **RTC v6.5.2**: Used for real-time voice communication.
- **FCM Integration**: Firebase Cloud Messaging for push notifications.
- **Call Invitation Workflow**: Includes call setup, invitation, and response handling.
- **Community-Supported**: Agora provides support for basic functionality, but the implementation is community-driven.

---

## Setup Instructions

### 1. Change the Agora App ID
- Open the file `lib/services/call_manager.dart`.
- Replace `<YOUR_AGORA_APP_ID>` with your Agora App ID:
  ```dart
  static const String agoraAppId = '<YOUR_AGORA_APP_ID>';


### 2. Implement a Token Server or Use a Hardcoded Token
- Production: Implement a token server to generate dynamic tokens. Refer to the Agora Token Server Guide.
- Testing: Hardcode a temporary token in the lib/screens/call_screen.dart file:
  ```dart
  final rtcToken = '<YOUR_TEMPORARY_TOKEN>';


### 3. Use RTM v2.2.x and RTC v6.5.2
- Ensure that you are using the following versions of the Agora SDKs:
- RTM: v2.2.x
- RTC: v6.5.2
- Update your pubspec.yaml file if necessary.


### 4. Add Firebase Configuration Files
- Place your google-services.json file in the android/app directory.
- Place your GoogleService-Info.plist file in the ios/Runner directory.

### Notes
Implementing Background Calling with FCM
To enable background calling functionality, follow these steps:

### 1. Set Up Firebase Cloud Messaging (FCM):

Configure FCM in your project by adding the google-services.json (Android) and GoogleService-Info.plist (iOS) files.
Ensure that your Firebase project is properly linked to your app.

### 2. Send Call Notifications:

When a user initiates a call, send a push notification to the callee's device using FCM.
Include the necessary data in the notification payload, such as:
  ```{
  "callerId": "12345",
  "channelName": "test_channel",
  "type": "call_invitation"
  }

### 3. Handle Notifications in the Background:

Use the onBackgroundMessage handler in Flutter to process notifications when the app is in the background or terminated.
Example:
  ```dart 
    Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    if (message.data['type'] == 'call_invitation') {
    // Extract call details
    final callerId = message.data['callerId'];
    final channelName = message.data['channelName'];

    // Show an incoming call UI or navigate to the call screen
  }}


### 4. Show Incoming Call UI:

Use packages like flutter_callkit_incoming or flutter_voip_push_notification to display an incoming call screen, even when the app is in the background.

### 5. Join the RTC Channel:

Once the user accepts the call, join the RTC channel using the provided channelName and token.

### 6. Permissions:

Ensure the app has the necessary permissions for notifications, background tasks, and microphone access.
    
### License
This project is licensed under the MIT License.

