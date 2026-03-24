import 'dart:async';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';

class RtcService {
  static final RtcService _instance = RtcService._internal();
  factory RtcService() => _instance;
  RtcService._internal();

  RtcEngine? _engine;
  String? _currentChannel;
  bool _isInitialized = false;
  String? _lastAppId;

  // Simple operation lock to serialize init/join/leave operations and avoid
  // racing the engine into an invalid state.
  Completer<void>? _operationLock;

  Future<void> init(String appId) async {
    print('🔊 RTC: Initializing with appId: $appId');
    print(
        '🔊 RTC: Current state - initialized: $_isInitialized, engine: $_engine');

    // serialize init calls
    while (_operationLock != null) {
      await _operationLock!.future;
    }
    _operationLock = Completer<void>();

    if (_isInitialized && _engine != null) {
      print('🔊 RTC: Already initialized, skipping');
      _operationLock?.complete();
      _operationLock = null;
      return;
    }

    // Clean up any existing engine
    await _cleanup();

    _engine = createAgoraRtcEngine();
    print('🔊 RTC: Engine created');

    await _engine!.initialize(
      RtcEngineContext(appId: appId),
    );
    print('🔊 RTC: Engine initialized successfully');

    // Set channel profile to Communication
    await _engine!
        .setChannelProfile(ChannelProfileType.channelProfileCommunication);
    print('🔊 RTC: Channel profile set to communication');

    await _engine!.enableAudio();
    print('🔊 RTC: Audio enabled');
    _isInitialized = true;
    _lastAppId = appId;
    _operationLock?.complete();
    _operationLock = null;
    print('🔊 RTC: Initialization complete');
  }

  Future<void> joinChannel({
    required String token,
    required String channel,
    required int uid,
  }) async {
    print('🔊 RTC: Joining channel: $channel with uid: $uid');
    print(
        '🔊 RTC: Current state - engine: $_engine, initialized: $_isInitialized, currentChannel: $_currentChannel');

    // serialize join/leave operations
    while (_operationLock != null) {
      await _operationLock!.future;
    }
    _operationLock = Completer<void>();

    if (_engine == null || !_isInitialized) {
      print('🔊 RTC: Engine not initialized, throwing exception');
      _operationLock?.complete();
      _operationLock = null;
      throw Exception('RTC engine not initialized');
    }

    // If already in a channel, leave it first
    if (_currentChannel != null) {
      print('🔊 RTC: Already in channel $_currentChannel, leaving first');
      await leaveChannel();
    }

    try {
      await _engine!.joinChannel(
        token: token,
        channelId: channel,
        uid: uid,
        options: const ChannelMediaOptions(),
      );
      _currentChannel = channel;
      print('🔊 RTC: Successfully joined channel: $channel');
    } catch (e) {
      print('🔊 RTC: Failed to join channel: $e');

      // If Agora reports invalid state (-8), attempt one retry: cleanup,
      // re-initialize (if we have the last appId) and re-join. This handles
      // transient invalid-state race conditions observed in some SDK flows.
      final isAgoraExc =
          e is AgoraRtcException || e.toString().contains('AgoraRtcException');
      final isInvalidState = e is AgoraRtcException && e.code == -8 ||
          e.toString().contains('-8') ||
          e.toString().toLowerCase().contains('invalid state');

      if (isAgoraExc && isInvalidState && _lastAppId != null) {
        print(
            '🔊 RTC: Detected invalid state (-8). Attempting recover: cleanup, re-init and retry join once');
        try {
          await _cleanup();
          await init(_lastAppId!);
          await _engine!.joinChannel(
            token: token,
            channelId: channel,
            uid: uid,
            options: const ChannelMediaOptions(),
          );
          _currentChannel = channel;
          print('🔊 RTC: Successfully joined channel on retry: $channel');
        } catch (e2) {
          print('🔊 RTC: Retry join failed: $e2');
          _operationLock?.complete();
          _operationLock = null;
          rethrow;
        }
      } else {
        _operationLock?.complete();
        _operationLock = null;
        rethrow;
      }
    }

    _operationLock?.complete();
    _operationLock = null;
  }

  Future<void> leaveChannel() async {
    if (_engine != null && _currentChannel != null) {
      try {
        await _engine!.leaveChannel();
        _currentChannel = null;
      } catch (e) {
        print('Error leaving channel: $e');
        _currentChannel = null;
      }
    }
  }

  Future<void> _cleanup() async {
    if (_engine != null) {
      try {
        await leaveChannel();
        await _engine!.release();
      } catch (e) {
        print('Error during cleanup: $e');
      } finally {
        _engine = null;
        _isInitialized = false;
        _currentChannel = null;
      }
    }
  }

  Future<void> dispose() async {
    await _cleanup();
  }

  // Get the engine for use in CallScreen
  RtcEngine? get engine => _engine;

  // Check if currently in a channel
  bool get isInChannel => _currentChannel != null;

  // Get current channel name
  String? get currentChannel => _currentChannel;
}
