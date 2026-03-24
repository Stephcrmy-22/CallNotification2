import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:agora_rtm/agora_rtm.dart';

class RtmService {
  late RtmClient client;

  Function(String channel, String caller, int uid)? onIncomingCall;

  /// Called when caller cancels (callee receives call_response reject).
  void Function()? onCallRejectedByCaller;

  /// Initialize RTM client and subscribe to own channel to receive invites/responses
  Future<void> init(String appId, String userId, [String? token]) async {
    try {
      final (status, rtmClient) = await RTM(appId, userId);
      if (status.error) {
        debugPrint('RTM init failed: ${status.reason} (${status.errorCode})');
        return;
      }

      client = rtmClient;
      debugPrint('RTM initialized as $userId');

      // Login with token if provided
      if (token != null && token.isNotEmpty) {
        await login(token);
      }

      // Subscribe to own channel so we receive call invites and call responses
      await subscribeChannel(userId);

      // Handle call invites globally (responses handled by individual screens)
      client.addListener(
        message: (MessageEvent event) {
          print('📨 RTM: Message received on channel ${event.channelName}');
          print('📨 RTM: Raw message bytes: ${event.message}');
          
          if (event.channelName == userId) {
            try {
              // Convert Uint8List to String first
              final messageString = utf8.decode(event.message!);
              print('📨 RTM: Decoded message string: $messageString');
              
              final data = jsonDecode(messageString) as Map<String, dynamic>;
              print('📨 RTM: Parsed data: $data');
              
              // Only handle call invites here (responses handled by screens)
              if (data['type'] == 'call_invite') {
                print('📨 RTM: Call invite received');
                final uid = data['uid'] is int
                    ? data['uid'] as int
                    : (data['uid'] as num).toInt();
                print('📨 RTM: Calling onIncomingCall with channel: ${data['channel']}, caller: ${data['caller']}, uid: $uid');
                onIncomingCall?.call(
                  data['channel'] as String,
                  data['caller'] as String,
                  uid,
                );
              }
            } catch (e) {
              print('📨 RTM: Error parsing message: $e');
            }
          }
        },
        linkState: (event) {
          debugPrint(
              'Link state: ${event.previousState} -> ${event.currentState}, reason: ${event.reason}');
        },
      );
    } catch (e) {
      debugPrint('RTM init exception: $e');
    }
  }

  Future<void> login(String token) async {
    try {
      final (status, _) = await client.login(token);
      if (status.error) {
        debugPrint('RTM login failed: ${status.reason}');
      } else {
        debugPrint('RTM login success');
      }
    } catch (e) {
      debugPrint('Login exception: $e');
    }
  }

  Future<void> subscribeChannel(String channelName) async {
    print('📨 RTM: Subscribing to channel: $channelName');
    try {
      final (status, _) = await client.subscribe(channelName);
      print('📨 RTM: Subscribe status: $status for channel: $channelName');
      if (status != 0) {
        print('📨 RTM: Failed to subscribe to channel $channelName, status: $status');
      }
    } catch (e) {
      print('📨 RTM: Exception subscribing to channel $channelName: $e');
    }
  }

  /// Send call invitation to a peer.
  /// [rtmTargetChannel] = callee's RTM channel (their userId).
  /// [rtcChannelName] = RTC channel name for the call.
  Future<void> sendCallInvite({
    required String rtmTargetChannel,
    required String rtcChannelName,
    required String caller,
    required int uid,
  }) async {
    final payload = jsonEncode({
      'type': 'call_invite',
      'channel': rtcChannelName,
      'caller': caller,
      'uid': uid,
    });

    print('📨 RTM: Sending call invite to $rtmTargetChannel');
    print('📨 RTM: Invite payload: $payload');

    try {
      final (status, _) = await client.publish(
        rtmTargetChannel,
        payload,
        channelType: RtmChannelType.message,
        customType: 'call',
      );
      print('📨 RTM: Send invite status: $status');
      if (status.error) {
        print('📨 RTM: Failed to send call invite: ${status.reason}');
      } else {
        print('📨 RTM: Call invite sent successfully');
      }
    } catch (e) {
      print('📨 RTM: Call invite exception: $e');
    }
  }

  /// Send call response (accept/reject) back to the caller.
  /// [callerRtmChannel] = caller's userId (their RTM channel).
  Future<void> sendCallResponse(
      String callerRtmChannel, String response) async {
    final payload = jsonEncode({
      'type': 'call_response',
      'response': response,
    });

    try {
      final (status, _) = await client.publish(
        callerRtmChannel,
        payload,
        channelType: RtmChannelType.message,
        customType: 'call',
      );
      if (status.error) {
        debugPrint('Call response failed: ${status.reason}');
      } else {
        debugPrint('Call response $response sent to $callerRtmChannel');
      }
    } catch (e) {
      debugPrint('Call response exception: $e');
    }
  }
}
