import 'package:flutter/material.dart';

class RadioStation {
  final String id;
  final String name;
  final String url;
  final IconData icon;
  final String artist;
  final bool isFavorite;

  RadioStation({
    required this.id,
    required this.name,
    required this.url,
    required this.icon,
    required this.artist,
    this.isFavorite = false,
  });

  // Конструктор для создания копии с изменениями
  RadioStation copyWith({
    String? id,
    String? name,
    String? url,
    IconData? icon,
    String? artist,
    bool? isFavorite,
  }) {
    return RadioStation(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      icon: icon ?? this.icon,
      artist: artist ?? this.artist,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  // Конвертация в Map для сохранения
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'iconCodePoint': icon.codePoint,
      'artist': artist,
      'isFavorite': isFavorite,
    };
  }

  // Создание из Map
  factory RadioStation.fromJson(Map<String, dynamic> json) {
    return RadioStation(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      icon: IconData(json['iconCodePoint'] as int, fontFamily: 'MaterialIcons'),
      artist: json['artist'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }
}
