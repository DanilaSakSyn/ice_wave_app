import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:ice_wave_app/main.dart';
import 'package:ice_wave_app/services/stations_service.dart';
import 'package:provider/provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isPlaying = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _listenToPlaybackState();
  }

  void _listenToPlaybackState() {
    // Подписываемся на изменения состояния воспроизведения
    audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
          _isLoading =
              state.processingState == AudioProcessingState.loading ||
              state.processingState == AudioProcessingState.buffering;
        });
      }
    });
  }

  Future<void> _playPause() async {
    final stationsService = Provider.of<StationsService>(
      context,
      listen: false,
    );
    final stations = stationsService.stations;

    if (stations.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No stations available')));
      }
      return;
    }

    try {
      if (_isPlaying) {
        await audioHandler.pause();
      } else {
        final station = stations[audioHandler.currentStationIndex];
        final mediaItem = MediaItem(
          id: station.url,
          title: station.name,
          artist: station.artist,
        );
        await audioHandler.playRadio(
          mediaItem,
          audioHandler.currentStationIndex,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  Future<void> _changeStation(int index) async {
    final stationsService = Provider.of<StationsService>(
      context,
      listen: false,
    );
    final stations = stationsService.stations;

    setState(() {
      _isLoading = true;
    });

    try {
      await audioHandler.stop();

      final station = stations[index];
      final mediaItem = MediaItem(
        id: station.url,
        title: station.name,
        artist: station.artist,
      );

      await audioHandler.playRadio(mediaItem, index);

      // Добавляем станцию в историю последних подключенных
      await stationsService.addToRecent(station.id);
    } catch (e) {
      print(e);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Station loading error: $e')));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<StationsService>(
      builder: (context, stationsService, child) {
        // Показываем индикатор загрузки, пока данные не загружены
        if (!stationsService.isLoaded) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home'), centerTitle: true),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        final stations = stationsService.stations;

        // Проверяем, что индекс не выходит за границы
        if (stations.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Home'), centerTitle: true),
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.radio_rounded,
                    size: 80,
                    color: Colors.grey.shade300,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No stations',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add stations in catalog',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            ),
          );
        }

        // Корректируем индекс, если он выходит за границы
        if (audioHandler.currentStationIndex >= stations.length) {
          audioHandler.currentStationIndex = 0;
        }

        final currentStation = stations[audioHandler.currentStationIndex];

        return Scaffold(
          appBar: AppBar(title: const Text('Home'), centerTitle: true),
          body: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  // Обложка плеера
                  Container(
                    width: double.infinity,
                    height: 280,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Color(0xFF87CEEB),
                          Color(0xFFB0E0E6),
                          Color(0xFFFFB6C1),
                          Color(0xFFFF9AA2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF87CEEB).withOpacity(0.6),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.8),
                          blurRadius: 15,
                          spreadRadius: -5,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          currentStation.icon,
                          size: 100,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          currentStation.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isPlaying ? 'Playing...' : 'Stopped',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Кнопка воспроизведения
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: const Color(0xFF87CEEB).withOpacity(0.3),
                          blurRadius: 40,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFFFE6E6)],
                        ),
                      ),
                      child: Material(
                        color: Colors.transparent,
                        shape: const CircleBorder(),
                        child: InkWell(
                          onTap: _isLoading ? null : _playPause,
                          customBorder: const CircleBorder(),
                          child: Container(
                            width: 80,
                            height: 80,
                            alignment: Alignment.center,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 40,
                                    height: 40,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Color(0xFF87CEEB),
                                    ),
                                  )
                                : Icon(
                                    _isPlaying
                                        ? Icons.pause_rounded
                                        : Icons.play_arrow_rounded,
                                    size: 50,
                                    color: const Color(0xFFFF6B6B),
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Заголовок списка
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.history_rounded,
                          size: 20,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Recent connections',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Список последних 3 станций
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Colors.white, Color(0xFFF8FCFF)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF87CEEB).withOpacity(0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: stationsService.recentStations.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.history_rounded,
                                    size: 48,
                                    color: Colors.grey.shade300,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No history',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Connect to a station',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade400,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(8),
                              itemCount: stationsService.recentStations.length,
                              separatorBuilder: (context, index) => Divider(
                                color: Colors.grey.shade200,
                                height: 1,
                              ),
                              itemBuilder: (context, index) {
                                final station =
                                    stationsService.recentStations[index];
                                final stationIndex = stations.indexWhere(
                                  (s) => s.id == station.id,
                                );
                                final isSelected =
                                    stationIndex ==
                                    audioHandler.currentStationIndex;

                                return ListTile(
                                  onTap: () => _changeStation(stationIndex),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      gradient: isSelected
                                          ? const LinearGradient(
                                              colors: [
                                                Color(0xFF87CEEB),
                                                Color(0xFFB0E0E6),
                                              ],
                                            )
                                          : const LinearGradient(
                                              colors: [
                                                Color(0xFFF0F8FF),
                                                Color(0xFFE6F3FF),
                                              ],
                                            ),
                                      borderRadius: BorderRadius.circular(12),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF87CEEB,
                                                ).withOpacity(0.4),
                                                blurRadius: 10,
                                                spreadRadius: 2,
                                              ),
                                            ]
                                          : null,
                                    ),
                                    child: Icon(
                                      station.icon,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF87CEEB),
                                    ),
                                  ),
                                  title: Text(
                                    station.name,
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? const Color(0xFF4A90A4)
                                          : const Color(0xFF6B8E9E),
                                    ),
                                  ),
                                  subtitle: Text(
                                    station.artist,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFB0C4DE),
                                    ),
                                  ),
                                  trailing: isSelected
                                      ? const Icon(
                                          Icons.volume_up_rounded,
                                          color: Color(0xFF87CEEB),
                                        )
                                      : null,
                                );
                              },
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
