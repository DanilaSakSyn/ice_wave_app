import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:ice_wave_app/models/radio_station.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StationsService extends ChangeNotifier {
  static const String _storageKey = 'radio_stations';
  static const String _recentStationsKey = 'recent_stations';
  List<RadioStation> _stations = [];
  List<String> _recentStationIds = [];
  bool _isLoaded = false;

  List<RadioStation> get stations => List.unmodifiable(_stations);

  List<RadioStation> get favoriteStations {
    return _stations.where((station) => station.isFavorite).toList();
  }

  // Получение последних 3 подключенных станций
  List<RadioStation> get recentStations {
    return _recentStationIds
        .map(
          (id) => _stations.firstWhere(
            (station) => station.id == id,
            orElse: () => _stations.first,
          ),
        )
        .take(3)
        .toList();
  }

  bool get isLoaded => _isLoaded;

  // Дефолтные станции
  List<RadioStation> get _defaultStations => [
    RadioStation(
      id: '1',
      name: 'RTL - Elektro',
      url: 'https://stream.104.6rtl.com/elektro/mp3-128',
      icon: Icons.spa_rounded,
      artist: 'Electronic',
    ),
    RadioStation(
      id: '2',
      name: 'Reboot Art - Free Artists',
      url: 'https://stream.reboot.fm/listen/reboot.fm/radio.mp3',
      icon: Icons.radio_rounded,
      artist: 'Electronic',
    ),
    RadioStation(
      id: '3',
      name: 'FM - Chillout Lounge',
      url: 'https://strmreg.1.fm/chilloutlounge_mobile_mp3',
      icon: Icons.music_note_rounded,
      artist: 'Chillout',
    ),
    RadioStation(
      id: '4',
      name: '94.5 The Buzz',
      url: 'https://stream.revma.ihrhls.com/zc2281/hls.m3u8',
      icon: Icons.music_note_rounded,
      artist: 'Alternative',
    ),
    RadioStation(
      id: '5',
      name: 'The Rock FM',
      url: 'https://live.amperwave.net/direct/midwestern-wkltfmaac-ibc1',
      icon: Icons.music_note_rounded,
      artist: 'Rock',
    ),
    RadioStation(
      id: '6',
      name: '95.1 K-SKY',
      url: 'https://ice7.securenetsystems.net/KSKY',
      icon: Icons.music_note_rounded,
      artist: 'Rock',
    ),
    RadioStation(
      id: '7',
      name: 'Atlwebr',
      url: 'https://usa2.fastcast4u.com/proxy/atlwebra?mp=/;',
      icon: Icons.music_note_rounded,
      artist: 'Rap',
    ),
    RadioStation(
      id: '8',
      name: 'Regulator R',
      url: 'http://usa14.fastcast4u.com:5632/;',
      icon: Icons.music_note_rounded,
      artist: 'Rap',
    ),
  ];

  // Загрузка станций из хранилища
  Future<void> loadStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stationsJson = prefs.getString(_storageKey);

      if (stationsJson != null) {
        final List<dynamic> decoded = json.decode(stationsJson);
        _stations = decoded.map((item) => RadioStation.fromJson(item)).toList();
      } else {
        // Если нет сохраненных станций, используем дефолтные
        _stations = _defaultStations;
        await _saveStations(); // Сохраняем дефолтные станции
      }

      // Загружаем историю последних станций
      final recentJson = prefs.getString(_recentStationsKey);
      if (recentJson != null) {
        final List<dynamic> decoded = json.decode(recentJson);
        _recentStationIds = decoded.cast<String>();
        // Оставляем только существующие станции
        _recentStationIds = _recentStationIds
            .where((id) => _stations.any((station) => station.id == id))
            .toList();
      }
    } catch (e) {
      print('Ошибка загрузки станций: $e');
      _stations = _defaultStations;
    }

    _isLoaded = true;
    notifyListeners();
  }

  // Сохранение станций в хранилище
  Future<void> _saveStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final stationsJson = json.encode(
        _stations.map((station) => station.toJson()).toList(),
      );
      await prefs.setString(_storageKey, stationsJson);
    } catch (e) {
      print('Ошибка сохранения станций: $e');
    }
  }

  Future<void> addStation(RadioStation station) async {
    _stations.add(station);
    await _saveStations();
    notifyListeners();
  }

  Future<void> removeStation(String id) async {
    _stations.removeWhere((station) => station.id == id);
    _recentStationIds.remove(id);
    await _saveStations();
    await _saveRecentStations();
    notifyListeners();
  }

  Future<void> updateStation(RadioStation station) async {
    final index = _stations.indexWhere((s) => s.id == station.id);
    if (index != -1) {
      _stations[index] = station;
      await _saveStations();
      notifyListeners();
    }
  }

  RadioStation? getStationById(String id) {
    try {
      return _stations.firstWhere((station) => station.id == id);
    } catch (e) {
      return null;
    }
  }

  // Переключение статуса избранного
  Future<void> toggleFavorite(String id) async {
    final index = _stations.indexWhere((s) => s.id == id);
    if (index != -1) {
      // Создаем новый список с обновленным элементом
      final updatedStations = List<RadioStation>.from(_stations);
      updatedStations[index] = updatedStations[index].copyWith(
        isFavorite: !updatedStations[index].isFavorite,
      );
      _stations = updatedStations;
      await _saveStations();
      notifyListeners();
    }
  }

  // Добавление станции в историю последних подключенных
  Future<void> addToRecent(String stationId) async {
    // Удаляем станцию из списка, если она уже есть
    _recentStationIds.remove(stationId);
    // Добавляем в начало
    _recentStationIds.insert(0, stationId);
    // Оставляем только последние 3
    if (_recentStationIds.length > 3) {
      _recentStationIds = _recentStationIds.take(3).toList();
    }
    await _saveRecentStations();
    notifyListeners();
  }

  // Сохранение истории последних станций
  Future<void> _saveRecentStations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentJson = json.encode(_recentStationIds);
      await prefs.setString(_recentStationsKey, recentJson);
    } catch (e) {
      print('Ошибка сохранения истории станций: $e');
    }
  }

  // Сброс к дефолтным станциям
  Future<void> resetToDefault() async {
    _stations = _defaultStations;
    _recentStationIds.clear();
    await _saveStations();
    await _saveRecentStations();
    notifyListeners();
  }
}
