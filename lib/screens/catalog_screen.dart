import 'package:flutter/material.dart';
import 'package:ice_wave_app/models/radio_station.dart';
import 'package:ice_wave_app/services/stations_service.dart';
import 'package:provider/provider.dart';
import 'package:audio_service/audio_service.dart';
import 'package:ice_wave_app/main.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  Future<void> _playStation(int stationIndex) async {
    try {
      final stationsService = Provider.of<StationsService>(
        context,
        listen: false,
      );
      final stations = stationsService.stations;
      final station = stations[stationIndex];

      await audioHandler.stop();

      final mediaItem = MediaItem(
        id: station.url,
        title: station.name,
        artist: station.artist,
      );

      await audioHandler.playRadio(mediaItem, stationIndex);

      // Добавляем станцию в историю последних подключенных
      await stationsService.addToRecent(station.id);

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playing: ${station.name}')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Playback error: $e')));
      }
    }
  }

  void _showAddStationDialog() {
    final nameController = TextEditingController();
    final urlController = TextEditingController();
    final artistController = TextEditingController();
    IconData selectedIcon = Icons.radio_rounded;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Add station'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Station name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'Stream URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: artistController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Choose icon:'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children:
                      [
                        Icons.radio_rounded,
                        Icons.music_note_rounded,
                        Icons.headphones_rounded,
                        Icons.spa_rounded,
                        Icons.favorite_rounded,
                        Icons.star_rounded,
                        Icons.audiotrack_rounded,
                        Icons.album_rounded,
                      ].map((icon) {
                        final isSelected = icon == selectedIcon;
                        return InkWell(
                          onTap: () {
                            setDialogState(() {
                              selectedIcon = icon;
                            });
                          },
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF87CEEB),
                                        Color(0xFFB0E0E6),
                                      ],
                                    )
                                  : null,
                              color: isSelected
                                  ? null
                                  : const Color(0xFFF0F8FF),
                              borderRadius: BorderRadius.circular(8),
                              border: isSelected
                                  ? Border.all(
                                      color: const Color(0xFF87CEEB),
                                      width: 2,
                                    )
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF87CEEB,
                                        ).withOpacity(0.3),
                                        blurRadius: 8,
                                        spreadRadius: 1,
                                      ),
                                    ]
                                  : null,
                            ),
                            child: Icon(
                              icon,
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF87CEEB),
                            ),
                          ),
                        );
                      }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty &&
                    urlController.text.isNotEmpty) {
                  final stationsService = Provider.of<StationsService>(
                    context,
                    listen: false,
                  );
                  final newStation = RadioStation(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    url: urlController.text,
                    icon: selectedIcon,
                    artist: artistController.text.isEmpty
                        ? 'Custom station'
                        : artistController.text,
                  );
                  stationsService.addStation(newStation);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Station added')),
                  );
                }
              },
              child: const Text('Add'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(RadioStation station) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete station?'),
        content: Text('Do you really want to delete "${station.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final stationsService = Provider.of<StationsService>(
                context,
                listen: false,
              );
              stationsService.removeStation(station.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Station deleted')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalog'),
        centerTitle: true,
        actions: [
          // Reset to default stations button
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'reset') {
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Reset list?'),
                    content: const Text(
                      'All custom stations will be deleted and the list will be restored to its original state.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          final stationsService = Provider.of<StationsService>(
                            context,
                            listen: false,
                          );
                          stationsService.resetToDefault();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('List restored')),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'reset',
                child: Row(
                  children: [
                    Icon(Icons.refresh_rounded),
                    SizedBox(width: 8),
                    Text('Reset to default'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Consumer<StationsService>(
        builder: (context, stationsService, child) {
          // Показываем индикатор загрузки, пока данные не загружены
          if (!stationsService.isLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          final stations = stationsService.stations;

          if (stations.isEmpty) {
            return Center(
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
                    'Add your first station',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: stations.length,
            itemBuilder: (context, index) {
              final station = stations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 0,
                color: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
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
                        color: const Color(0xFF87CEEB).withOpacity(0.15),
                        blurRadius: 15,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    onTap: () => _playStation(index),
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
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFF4A90A4),
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
                        const SizedBox(height: 4),
                        Text(
                          station.url,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFB0C4DE),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Кнопка избранного
                        Container(
                          decoration: BoxDecoration(
                            gradient: station.isFavorite
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFFF9AA2),
                                    ],
                                  )
                                : null,
                            shape: BoxShape.circle,
                            boxShadow: station.isFavorite
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFFFF6B6B,
                                      ).withOpacity(0.4),
                                      blurRadius: 10,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : null,
                          ),
                          child: IconButton(
                            icon: Icon(
                              station.isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                            ),
                            color: station.isFavorite
                                ? Colors.white
                                : const Color(0xFFB0C4DE),
                            onPressed: () {
                              stationsService.toggleFavorite(station.id);
                            },
                          ),
                        ),
                        // Кнопка удаления
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          color: const Color(0xFFB0C4DE),
                          onPressed: () => _showDeleteConfirmation(station),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF9AA2)],
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6B6B).withOpacity(0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: FloatingActionButton(
          onPressed: _showAddStationDialog,
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }
}
