import 'dart:convert';
import 'package:agora_rtm/agora_rtm.dart';

class RtmService {

  late RtmClient client;

  Function(String channel, String caller)? onIncomingCall;

  Future init(String appId, String userId) async {

    final (status, rtmClient) = await RTM(appId, userId);

    if (status.error) {
      print("RTM init failed: ${status.reason}");
      return;
    }

    client = rtmClient;

    print("RTM initialized");

    client.addListener(

      message: (event) {

        final message = utf8.decode(event.message!);

        print("Message received: $message");

        final data = jsonDecode(message);

        if (data["type"] == "call_invite") {

          onIncomingCall?.call(
            data["channel"],
            data["caller"],
          );

        }

      },

      linkState: (event) {

        print(
            "Link state changed ${event.previousState} -> ${event.currentState}");

      },

    );

  }

  Future login(String token) async {

    final (status, response) = await client.login(token);

    if (status.error) {
      print("Login failed: ${status.reason}");
    } else {
      print("RTM login success");
    }

  }

  Future sendCallInvite(
      String peerChannel, String caller) async {

    final payload = jsonEncode({
      "type": "call_invite",
      "channel": peerChannel,
      "caller": caller
    });

    final (status, response) = await client.publish(
      peerChannel,
      payload,
      channelType: RtmChannelType.message,
      customType: "call",
    );

    if (status.error) {
      print("Publish failed: ${status.reason}");
    } else {
      print("Call invite sent");
    }

  }

  Future subscribeChannel(String channel) async {

    final (status, response) =
        await client.subscribe(channel);

    if (status.error) {
      print("Subscribe failed");
    } else {
      print("Subscribed to $channel");
    }

  }

}