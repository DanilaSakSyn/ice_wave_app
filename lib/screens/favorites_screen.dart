import 'package:flutter/material.dart';
import 'package:ice_wave_app/services/stations_service.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:ice_wave_app/main.dart';
import 'dart:async';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  bool _isPlaying = false;
  StreamSubscription<PlaybackState>? _playbackStateSubscription;

  @override
  void initState() {
    super.initState();
    _listenToPlaybackState();
  }

  void _listenToPlaybackState() {
    // Подписываемся на изменения состояния воспроизведения
    _playbackStateSubscription = audioHandler.playbackState.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state.playing;
        });
      }
    });
  }

  @override
  void dispose() {
    _playbackStateSubscription?.cancel();
    super.dispose();
  }

  Future<void> _playStation(BuildContext context, int stationIndex) async {
    try {
      final stationsService = Provider.of<StationsService>(
        context,
        listen: false,
      );
      final allStations = stationsService.stations;

      // Находим индекс станции в общем списке
      final favoriteStation = stationsService.favoriteStations[stationIndex];
      final globalIndex = allStations.indexWhere(
        (s) => s.id == favoriteStation.id,
      );

      if (globalIndex != -1) {
        await audioHandler.stop();

        final mediaItem = MediaItem(
          id: favoriteStation.url,
          title: favoriteStation.name,
          artist: favoriteStation.artist,
        );

        await audioHandler.playRadio(mediaItem, globalIndex);

        // Добавляем станцию в историю последних подключенных
        await stationsService.addToRecent(favoriteStation.id);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites'), centerTitle: true),
      body: Consumer<StationsService>(
        builder: (context, stationsService, child) {
          // Показываем индикатор загрузки, пока данные не загружены
          if (!stationsService.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final favoriteStations = stationsService.favoriteStations;
          final allStations = stationsService.stations;

          if (favoriteStations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFF6B6B), Color(0xFFFF9AA2)],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF6B6B).withOpacity(0.5),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_border_rounded,
                      size: 60,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No favorites',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Add stations to favorites',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            key: ValueKey(
              favoriteStations.length,
            ), // Принудительное обновление при изменении количества
            padding: const EdgeInsets.all(16),
            itemCount: favoriteStations.length,
            itemBuilder: (context, index) {
              final station = favoriteStations[index];
              final isCurrentStation =
                  audioHandler.currentStationIndex ==
                  allStations.indexWhere((s) => s.id == station.id);
              final isPlaying = isCurrentStation && _isPlaying;

              return Card(
                key: ValueKey(
                  station.id,
                ), // Уникальный ключ для каждой карточки
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: isCurrentStation
                          ? [const Color(0xFFE6F7FF), const Color(0xFFF0F8FF)]
                          : [Colors.white, const Color(0xFFF8FCFF)],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: isCurrentStation
                        ? Border.all(color: const Color(0xFF87CEEB), width: 2)
                        : null,
                    boxShadow: [
                      BoxShadow(
                        color: isCurrentStation
                            ? const Color(0xFF87CEEB).withOpacity(0.3)
                            : const Color(0xFFB0E0E6).withOpacity(0.15),
                        blurRadius: isCurrentStation ? 20 : 10,
                        spreadRadius: isCurrentStation ? 2 : 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () => _playStation(context, index),
                    leading: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF87CEEB), Color(0xFFB0E0E6)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF87CEEB).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Icon(station.icon, color: Colors.white, size: 32),
                    ),
                    title: Text(
                      station.name,
                      style: TextStyle(
                        fontWeight: isCurrentStation
                            ? FontWeight.bold
                            : FontWeight.w600,
                        fontSize: 16,
                        color: isCurrentStation
                            ? const Color(0xFF4A90A4)
                            : const Color(0xFF6B8E9E),
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          station.artist,
                          style: const TextStyle(color: Color(0xFFB0C4DE)),
                        ),
                        if (isPlaying) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(
                                Icons.volume_up_rounded,
                                size: 14,
                                color: Color(0xFF87CEEB),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Playing',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF87CEEB),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                    trailing: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF6B6B), Color(0xFFFF9AA2)],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF6B6B).withOpacity(0.4),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.favorite_rounded),
                        color: Colors.white,
                        onPressed: () {
                          stationsService.toggleFavorite(station.id);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
