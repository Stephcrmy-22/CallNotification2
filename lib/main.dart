import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:agora_voice_call/screens/home_screen.dart' as app_screens;
import 'package:agora_voice_call/screens/login_screen.dart';
import 'package:agora_voice_call/screens/invitation_screen.dart';
import 'package:agora_voice_call/services/fcm_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  final navigatorKey = GlobalKey<NavigatorState>();
  runApp(MyApp(navigatorKey: navigatorKey));

  // Set up FCM after the UI is up so permission dialogs and initial message
  // handling don't block the first frame.
  setupFcm(navigatorKey);
}

class MyApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;

  const MyApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Agora Voice Call',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      home: _AppWrapper(
        child: const LoginScreen(),
      ),
    );
  }
}

/// Checks for initial FCM payload (app opened from terminated state) after first frame.
class _AppWrapper extends StatefulWidget {
  final Widget child;

  const _AppWrapper({required this.child});

  @override
  State<_AppWrapper> createState() => _AppWrapperState();
}

class _AppWrapperState extends State<_AppWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final payload = FcmService.initialCallPayload;
      if (payload != null && mounted) {
        FcmService.initialCallPayload = null;
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => InvitationScreen(
              channel: payload.channel,
              caller: payload.caller,
              uid: payload.uid,
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
