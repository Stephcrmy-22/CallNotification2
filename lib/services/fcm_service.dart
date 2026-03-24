import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agora_voice_call/screens/invitation_screen.dart';

/// Top-level handler for FCM when app is in background or terminated.
/// Must be top-level (not a class method) for native background isolate.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (message.data.isNotEmpty) {
    // Payload will be read when app opens via getInitialMessage / onMessageOpenedApp
  }
}

/// FCM helpers and state for call-invite handling.
class FcmService {
  FcmService._();

  /// Callback to open invitation screen (set from main after navigator is ready).
  static void Function(IncomingCallPayload payload)? onOpenInvitationScreen;

  /// When app is opened from terminated state, getInitialMessage payload is stored here.
  /// Root widget should check this after first frame and push InvitationScreen.
  static IncomingCallPayload? initialCallPayload;
}

/// Call invite payload keys (must match backend/FCM payload)
const String kKeyType = 'type';
const String kKeyChannel = 'channel';
const String kKeyCaller = 'caller';
const String kKeyUid = 'uid';
const String kTypeCallInvite = 'call_invite';

/// Parsed incoming call from FCM data payload
class IncomingCallPayload {
  final String channel;
  final String caller;
  final int uid;

  const IncomingCallPayload({
    required this.channel,
    required this.caller,
    required this.uid,
  });

  static IncomingCallPayload? fromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    if (data[kKeyType] != kTypeCallInvite) return null;
    final channel = data[kKeyChannel] as String?;
    final caller = data[kKeyCaller] as String?;
    final uidRaw = data[kKeyUid];
    if (channel == null || channel.isEmpty || caller == null || caller.isEmpty) return null;
    final uid = uidRaw is int ? uidRaw : (uidRaw is String ? int.tryParse(uidRaw) : (uidRaw is num ? uidRaw.toInt() : null));
    if (uid == null) return null;
    return IncomingCallPayload(channel: channel, caller: caller, uid: uid);
  }
}

/// Setup FCM: request permission, set handlers for foreground/background/terminated.
Future<void> setupFcm(GlobalKey<NavigatorState> navigatorKey) async {
  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  FcmService.onOpenInvitationScreen = (IncomingCallPayload payload) {
    navigatorKey.currentState?.push(
      MaterialPageRoute(
        builder: (_) => InvitationScreen(
          channel: payload.channel,
          caller: payload.caller,
          uid: payload.uid,
        ),
      ),
    );
  };

  // Foreground: show invitation when data message arrives
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    final payload = IncomingCallPayload.fromRemoteMessage(message);
    if (payload != null) FcmService.onOpenInvitationScreen?.call(payload);
  });

  // App opened from background by tapping notification
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final payload = IncomingCallPayload.fromRemoteMessage(message);
    if (payload != null) FcmService.onOpenInvitationScreen?.call(payload);
  });

  // App opened from terminated state: store payload for root to handle after first frame
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    final payload = IncomingCallPayload.fromRemoteMessage(initialMessage);
    if (payload != null) FcmService.initialCallPayload = payload;
  }
}
