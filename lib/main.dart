import 'package:flutter/material.dart';
import 'package:ice_wave_app/app.dart';
import 'package:audio_service/audio_service.dart';
import 'package:ice_wave_app/services/audio_handler.dart';

late RadioAudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.icewave.app.channel.audio',
      androidNotificationChannelName: 'Ice Wave Radio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );

  runApp(const MainApp());
}
