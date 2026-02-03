import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:audio_service/audio_service.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:ice_wave_app/firebase_options.dart';
import 'package:ice_wave_app/services/audio_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'core/services/sdk_initializer.dart';
import 'package:flutter/cupertino.dart';
import 'core/screens/splash_screen.dart';

late RadioAudioHandler audioHandler;
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  initTrackingAppTransparency();

  audioHandler = await AudioService.init(
    builder: () => RadioAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.icewave.app.channel.audio',
      androidNotificationChannelName: 'Ice Wave Radio',
      androidNotificationOngoing: true,
      androidNotificationIcon: 'mipmap/ic_launcher',
    ),
  );
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  SdkInitializer.prefs = await SharedPreferences.getInstance();
  await SdkInitializer.loadRuntimeStorageToDevice();
  var isFirstStart = !SdkInitializer.hasValue("isFirstStart");
  var isOrganic = SdkInitializer.getValue("Organic");
  if (kDebugMode) {
    print('add af2 $isFirstStart $isOrganic');
  }
  if (isFirstStart) SdkInitializer.initAppsFlyer();

  runApp(const App());
}

Future<void> initTrackingAppTransparency() async {
  try {
    final TrackingStatus status =
        await AppTrackingTransparency.requestTrackingAuthorization();
    if (kDebugMode) {
      print('App Tracking Transparency status: $status');
    }
    int timeout = 0;
    while (status == TrackingStatus.notDetermined && timeout < 10) {
      final TrackingStatus newStatus =
          await AppTrackingTransparency.requestTrackingAuthorization();
      await Future.delayed(const Duration(milliseconds: 200));
      timeout++;
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error requesting App Tracking Transparency authorization: $e');
    }
  }
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return const CupertinoApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
