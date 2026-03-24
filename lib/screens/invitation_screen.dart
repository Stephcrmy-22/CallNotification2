import 'package:flutter/material.dart';
import 'package:agora_voice_call/services/agora_rtc_service.dart';
import 'package:agora_voice_call/services/call_manager.dart';
import 'package:agora_voice_call/screens/call_screen.dart';
import 'package:agora_voice_call/screens/home_screen.dart' as app_screens;
import 'package:permission_handler/permission_handler.dart';
import 'package:app_settings/app_settings.dart';

/// Shown when User B receives a call invite (from RTM or FCM).
/// Accept → join RTC and go to CallScreen. Decline → send reject and pop.
class InvitationScreen extends StatefulWidget {
  final String channel;
  final String caller;
  final int uid;

  const InvitationScreen({
    super.key,
    required this.channel,
    required this.caller,
    required this.uid,
  });

  @override
  State<InvitationScreen> createState() => _InvitationScreenState();
}

class _InvitationScreenState extends State<InvitationScreen> {
  bool _isResponding = false;

  Future<void> _accept() async {
    if (_isResponding) return;
    setState(() => _isResponding = true);

    // Request microphone permission immediately when user accepts
    var status = await Permission.microphone.status;
    print('Current microphone permission status: $status');

    if (status.isDenied) {
      status = await Permission.microphone.request();
      print('After request microphone permission status: $status');
    }

    if (status.isPermanentlyDenied) {
      if (mounted) {
        _showSettingsDialog();
      }
      setState(() => _isResponding = false);
      return;
    }

    if (!status.isGranted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Microphone permission is required to make voice calls'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() => _isResponding = false);
      return;
    }

    final rtm = CallManager.instance.rtmService;
    final localId = CallManager.instance.localUserId;
    if (rtm == null) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('RTM not ready')));
      setState(() => _isResponding = false);
      return;
    }
    if (localId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Local user ID not set')),
        );
      }
      setState(() => _isResponding = false);
      return;
    }

    await rtm.sendCallResponse(widget.caller, 'accept');

    if (!mounted) return;

    try {
      final rtc = RtcService();
      const appId = 'YOUR APPID';
      const token = 'YOUR RTC TOKEN';
      await rtc.init(appId);
      await rtc.joinChannel(
          token: token, channel: widget.channel, uid: localId);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CallScreen(channel: widget.channel, uid: localId),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to join call: $e')),
        );
      }
      setState(() => _isResponding = false);
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Microphone Permission Required'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Microphone permission was permanently denied. To make voice calls, please enable microphone access in app settings.',
              ),
              const SizedBox(height: 16),
              const Text(
                'For iOS:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'When Settings opens:\n'
                '1. Scroll down and tap "Privacy & Security"\n'
                '2. Tap "Microphone"\n'
                '3. Find "Agora Voice Call" in the list\n'
                '4. Toggle the switch ON\n'
                '5. Return to app and try again',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'If app is NOT in microphone list:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'The app needs to be reinstalled:\n'
                '1. Delete this app from your device\n'
                '2. Run the app again\n'
                '3. Accept a call and tap "OK" when prompted',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 8),
              const Text(
                'Quick navigation:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'Settings → Privacy & Security → Microphone',
                style: TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() => _isResponding = false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Try to open app settings first, then guide user to microphone
                AppSettings.openAppSettings(type: AppSettingsType.settings);
              },
              child: const Text('Open Settings'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _decline() async {
    if (_isResponding) return;
    setState(() => _isResponding = true);

    final rtm = CallManager.instance.rtmService;
    if (rtm != null) await rtm.sendCallResponse(widget.caller, 'reject');

    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const app_screens.HomeScreen()),
        (route) => false,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    CallManager.instance.rtmService?.onCallRejectedByCaller = () {
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const app_screens.HomeScreen()),
          (route) => false,
        );
      }
    };
  }

  @override
  void dispose() {
    CallManager.instance.rtmService?.onCallRejectedByCaller = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Incoming Call')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.call, size: 80, color: Colors.green),
              const SizedBox(height: 24),
              Text(
                'Incoming call from',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                widget.caller,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isResponding ? null : _decline,
                    child: const Text('Decline'),
                  ),
                  const SizedBox(width: 24),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 16),
                    ),
                    onPressed: _isResponding ? null : _accept,
                    child: _isResponding
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : const Text('Accept'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
