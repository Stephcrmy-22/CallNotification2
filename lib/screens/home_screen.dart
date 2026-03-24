import 'package:flutter/material.dart';
import 'package:agora_voice_call/services/call_manager.dart';
import 'package:agora_voice_call/screens/calling_screen.dart';
import 'package:agora_voice_call/screens/invitation_screen.dart';
import 'package:agora_voice_call/screens/login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final CallManager _callManager = CallManager.instance;
  final TextEditingController _targetIdController =
      TextEditingController(text: '2');

  @override
  void initState() {
    super.initState();
    print('🏠 Home: initState - setting up RTM callbacks');
    _checkLoginStatus();
    _callManager.rtmService?.onIncomingCall = _onIncomingCall;
    print('🏠 Home: RTM onIncomingCall callback set');
  }

  void _checkLoginStatus() {
    if (_callManager.rtmService == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      });
    }
  }

  @override
  void dispose() {
    _callManager.rtmService?.onIncomingCall = null;
    _targetIdController.dispose();
    super.dispose();
  }

  void _onIncomingCall(String channel, String caller, int uid) {
    print(
        '🏠 Home: Incoming call received - channel: $channel, caller: $caller, uid: $uid');
    if (!mounted) {
      print('🏠 Home: Widget not mounted, ignoring call');
      return;
    }
    print('🏠 Home: Navigating to InvitationScreen');
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => InvitationScreen(
          channel: channel,
          caller: caller,
          uid: uid,
        ),
      ),
    );
    print('🏠 Home: Navigation to InvitationScreen completed');
  }

  Future<void> _sendCallInvite() async {
    final targetId = int.tryParse(_targetIdController.text.trim());
    final localUserId = _callManager.localUserId;

    if (targetId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Target User ID must be an integer')),
        );
      }
      return;
    }

    if (localUserId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please login first')),
        );
      }
      return;
    }

    if (localUserId == targetId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User IDs must be different')),
        );
      }
      return;
    }

    final rtm = _callManager.rtmService;
    if (rtm == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('RTM not ready')),
        );
      }
      return;
    }

    const String channelName = 'demo';

    await rtm.sendCallInvite(
      rtmTargetChannel: targetId.toString(),
      rtcChannelName: channelName,
      caller: localUserId.toString(),
      uid: localUserId,
    );

    if (!mounted) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CallingScreen(
          channel: channelName,
          caller: localUserId.toString(),
          calleeRtmChannel: targetId.toString(),
          rtm: rtm,
          uid: localUserId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Welcome, User ${_callManager.localUserId ?? 'Unknown'}',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'You are logged in and ready to make calls',
              style: TextStyle(
                color: Colors.grey,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _targetIdController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Target User ID (integer)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.phone_forwarded),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _sendCallInvite,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'Call User',
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () {
                _callManager.rtmService = null;
                _callManager.localUserId = null;
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              child: const Text('Logout'),
            ),
          ],
        ),
      ),
    );
  }
}
