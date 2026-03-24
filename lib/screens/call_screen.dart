import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart'
    show StatefulWidget, State, Widget, BuildContext;
import 'package:agora_voice_call/services/agora_rtc_service.dart';
import 'package:permission_handler/permission_handler.dart';

class CallScreen extends StatefulWidget {
  final String channel;
  final int uid;

  const CallScreen({
    super.key,
    required this.channel,
    required this.uid,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final rtc = RtcService(); // Singleton instance
  final appId = "YOUR APPID"; // Your Agora App ID
  final rtcToken =
      "YOUR RTC TOKEN"; // RTC token for the channel (can be generated server-side)
  @override
  void initState() {
    super.initState();
    // RTC is already initialized by invitation/calling screen
    // Just set up event handlers
    setupEventHandlers();
  }

  void setupEventHandlers() {
    // Set up any event handlers for the RTC engine
    // The engine is already initialized and joined to channel
  }

  Future endCall() async {
    await rtc.leaveChannel();
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("In Call")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Channel: ${widget.channel}"),
            const SizedBox(height: 40),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: endCall,
              child: const Text("End Call"),
            ),
          ],
        ),
      ),
    );
  }
}
