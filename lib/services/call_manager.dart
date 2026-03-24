import 'package:agora_voice_call/services/agora_rtm_service.dart';

class CallManager {
  CallManager._internal();

  static final CallManager instance = CallManager._internal();

  /// Integer user id chosen by the user (must be unique per device).
  int? localUserId;

  String? currentChannel;
  RtmService? rtmService;
  static const String agoraAppId =
      'YOUR APPID'; // Replace with your Agora App ID

  /// Initialize RTM for the current user (call once at app start).
  Future<void> initRtmIfNeeded(int userId, [String? token]) async {
    localUserId = userId;
    if (rtmService != null) return;
    rtmService = RtmService();
    await rtmService!.init(agoraAppId, userId.toString(), token);
  }
}
