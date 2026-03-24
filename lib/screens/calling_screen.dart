import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:agora_voice_call/services/agora_rtm_service.dart';
import 'package:agora_voice_call/services/agora_rtc_service.dart';
import 'package:agora_voice_call/services/call_manager.dart';
import 'package:agora_voice_call/screens/call_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:agora_rtm/agora_rtm.dart'; // Importing Agora RTM package

// app_settings not needed in caller flow

class CallingScreen extends StatefulWidget {
  final String channel;
  final String caller;
  final String calleeRtmChannel;
  final RtmService rtm;
  final int uid;

  const CallingScreen({
    super.key,
    required this.channel,
    required this.caller,
    required this.calleeRtmChannel,
    required this.rtm,
    required this.uid,
  });

  @override
  State<CallingScreen> createState() => _CallingScreenState();
}

class _CallingScreenState extends State<CallingScreen> {
  Timer? timeoutTimer;
  bool callAnswered = false;

  @override
  void initState() {
    super.initState();
    startCallTimeout();

    // Set up RTM listener for incoming messages
    _setupRtmListener();

    // Caller joins the RTC channel first
    _joinDemoChannel(Navigator.of(context)).then((_) {
      // Send invitation signaling messages to the callee after joining the channel
      _sendCallSignaling(widget.calleeRtmChannel);
    }).catchError((e) {
      print('📞 Caller: Failed to join RTC channel: $e');
    });
  }

  void startCallTimeout() {
    // Automatically reject after 30 seconds
    timeoutTimer = Timer(const Duration(seconds: 30), () {
      if (!callAnswered) {
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No response from user")),
          );
        }
      }
    });
  }

  void listenForResponse() {
    // Listen on caller's own RTM channel to receive responses
    final callerRtmChannel = CallManager.instance.localUserId;
    print('📞 Caller: Setting up listener on own channel: $callerRtmChannel');

    widget.rtm.client.addListener(
      message: (event) async {
        print('📞 Caller: Message received on channel ${event.channelName}');
        print('📞 Caller: Raw message bytes: ${event.message}');

        try {
          final msg = utf8.decode(event.message!);
          print('📞 Caller: Decoded message: $msg');
          final data = jsonDecode(msg);
          print('📞 Caller: Parsed data: $data');

          if (data['type'] == 'call_response') {
            if (!mounted) return;

            // Stop invitation timeout immediately when any response is received
            timeoutTimer?.cancel();

            if (data['response'] == 'accept') {
              print(
                  '📞 Caller: Received accept response - ending invitation screen then joining demo channel...');
              callAnswered = true;

              // Capture navigator so we can navigate after popping this route
              final nav = Navigator.of(context);
              // End the invitation/calling screen immediately
              nav.pop();

              // Join the 'demo' channel after the screen is ended. Use the
              // captured navigator to push the CallScreen even if this State
              // gets unmounted.
              _joinDemoChannel(nav);
            } else if (data['response'] == 'reject') {
              print('📞 Caller: Received reject response');
              callAnswered = true;
              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Call rejected")),
                );
              }
            }
          }
        } catch (e) {
          print('📞 Caller: Error parsing message: $e');
        }
      },
    );
  }

  // Adjusted RTM logic to align with RTM v1 workflow steps

  // Caller sends multiple signaling messages
  Future<void> _sendCallSignaling(String calleeRtmChannel) async {
    try {
      final setupPayload = jsonEncode({
        'type': 'call_setup',
        'channel': 'demo',
        'uid': widget.uid,
      });
      await widget.rtm.client.publish(calleeRtmChannel, setupPayload);
      print('📨 Caller: Sent call setup message');

      final invitePayload = jsonEncode({
        'type': 'call_invite',
        'channel': 'demo',
        'uid': widget.uid,
      });
      await widget.rtm.client.publish(calleeRtmChannel, invitePayload);
      print('📨 Caller: Sent call invite message');
    } catch (e) {
      print('📨 Caller: Failed to send signaling messages: $e');
    }
  }

  // Callee processes incoming messages
  void _handleIncomingMessages(MessageEvent event) {
    try {
      final msg = utf8.decode(event.message!);
      final data = jsonDecode(msg);

      if (data['type'] == 'call_setup') {
        print('📨 Callee: Received call setup message');
        // Handle call setup logic
      } else if (data['type'] == 'call_invite') {
        print('📨 Callee: Received call invite message');
        // Handle call invitation logic
      } else if (data['type'] == 'call_response') {
        print('📨 Caller: Received call response: ${data['response']}');
        if (data['response'] == 'accept') {
          _joinDemoChannel(Navigator.of(context));
        } else if (data['response'] == 'reject') {
          print('📨 Caller: Call rejected');
        }
      }
    } catch (e) {
      print('📨 Error processing incoming message: $e');
    }
  }

  // Add listener for incoming messages
  void _setupRtmListener() {
    widget.rtm.client.addListener(
      message: _handleIncomingMessages,
    );
  }

  // _handleAccept removed — accept flow now pops then uses _joinDemoChannel

  // NOTE: intentionally not keeping a fire-and-forget helper — we call
  // _joinDemoChannel via unawaited pattern directly where appropriate.

  Future<void> _joinDemoChannel(NavigatorState nav) async {
    print('📞 Caller: Joining demo channel after invitation ended...');

    // Check microphone permission
    var status = await Permission.microphone.status;
    if (status.isDenied) {
      status = await Permission.microphone.request();
    }
    if (!status.isGranted) {
      // Notify user via a snackbar on the captured navigator's context
      try {
        ScaffoldMessenger.of(nav.context).showSnackBar(
          const SnackBar(content: Text('Microphone permission required')),
        );
      } catch (e) {
        print('Could not show snackbar: $e');
      }
      return;
    }

    try {
      final rtc = RtcService();
      const appId = CallManager.agoraAppId;
      const token = 'YOUR RTC TOKEN';

      await rtc.init(appId);
      await rtc.joinChannel(token: token, channel: 'demo', uid: widget.uid);

      // Navigate to CallScreen using captured navigator
      nav.pushReplacement(MaterialPageRoute(
        builder: (_) => CallScreen(channel: 'demo', uid: widget.uid),
      ));
    } catch (e) {
      print('📞 Caller: Failed to join demo channel: $e');
      try {
        ScaffoldMessenger.of(nav.context).showSnackBar(
          SnackBar(content: Text('Failed to join demo channel: $e')),
        );
      } catch (_) {}
    }
  }

  // Legacy join helper removed — inviter uses _joinDemoChannel after
  // the calling screen is dismissed.

  void cancelCall() async {
    timeoutTimer?.cancel();
    await widget.rtm.sendCallResponse(widget.calleeRtmChannel, 'reject');
    if (mounted) Navigator.pop(context);
  }

  // Settings dialog is provided by Invitation screen; caller flow keeps it simple

  @override
  void dispose() {
    timeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Calling...")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Calling user on channel: ${widget.channel}"),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: cancelCall,
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),
    );
  }
}
