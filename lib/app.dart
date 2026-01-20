import 'package:flutter/material.dart';
import 'package:ice_wave_app/screens/main_screen.dart';
import 'package:ice_wave_app/screens/onboarding_screen.dart';
import 'package:ice_wave_app/services/stations_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  final StationsService _stationsService = StationsService();
  bool _isLoading = true;
  bool _showOnboarding = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    // Check if onboarding has been completed
    final prefs = await SharedPreferences.getInstance();
    final onboardingComplete = prefs.getBool('onboarding_complete') ?? false;

    // Load stations
    await _stationsService.loadStations();

    setState(() {
      _showOnboarding = !onboardingComplete;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _stationsService,
      child: MaterialApp(
        title: 'Ice Wave App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF87CEEB),
            brightness: Brightness.light,
            primary: const Color(0xFF87CEEB),
            secondary: const Color(0xFFB0E0E6),
            error: const Color(0xFFFF6B6B),
          ),
          scaffoldBackgroundColor: const Color(0xFFF0F8FF),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Color(0xFF4A90A4),
            surfaceTintColor: Colors.transparent,
          ),
        ),
        debugShowCheckedModeBanner: false,
        home: _isLoading
            ? const Scaffold(body: Center(child: CircularProgressIndicator()))
            : _showOnboarding
            ? const OnboardingScreen()
            : const MainScreen(),
      ),
    );
  }
}
