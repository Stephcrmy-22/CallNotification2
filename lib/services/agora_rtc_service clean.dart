import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcService {

  late RtcEngine engine;

  Future init(String appId) async {

    engine = createAgoraRtcEngine();

    await engine.initialize(
      RtcEngineContext(appId: appId),
    );

    await engine.enableAudio();

  }

  Future joinChannel(
      String token, String channel, int uid) async {

    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: uid,
      options: const ChannelMediaOptions(),
    );

  }

  Future leave() async {

    await engine.leaveChannel();

  }

}