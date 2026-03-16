import 'package:flutter/foundation.dart';

class WorshipTeamModel {
  final int id;
  final String songname;
  final String? lyricsSi;
  final String? lyricsEn;
  final String? lyricsTa;
  final int artistId;
  final int? duration;
  final String? notes;
  final String? image;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? artistName;
  final String? artistImage;
  final List<String> artistLanguages;

  WorshipTeamModel({
    required this.id,
    required this.songname,
    this.lyricsSi,
    this.lyricsEn,
    this.lyricsTa,
    required this.artistId,
    this.duration,
    this.notes,
    this.image,
    this.createdAt,
    this.updatedAt,
    this.artistName,
    this.artistImage,
    this.artistLanguages = const [],
  });

  factory WorshipTeamModel.fromJson(Map<String, dynamic> json) {
    List<String> langs = [];
    try {
      if (json['artist_languages'] != null) {
        if (json['artist_languages'] is List) {
          langs = List<String>.from(json['artist_languages']);
        } else if (json['artist_languages'] is String) {
          langs = (json['artist_languages'] as String).split(',').map((s) => s.trim()).toList();
        }
      }
    } catch (e) {
      debugPrint('Error parsing artist languages: $e');
    }

    DateTime? parseDate(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.parse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return WorshipTeamModel(
      id: json['id'] ?? 0,
      songname: json['songname'] ?? json['songName'] ?? '',
      lyricsSi: json['lyrics_si'],
      lyricsEn: json['lyrics_en'],
      lyricsTa: json['lyrics_ta'],
      artistId: json['artist_id'] ?? 0,
      duration: json['duration'],
      notes: json['notes'],
      image: json['image'],
      createdAt: parseDate(json['created_at']),
      updatedAt: parseDate(json['updated_at']),
      artistName: json['artist_name'],
      artistImage: json['artist_image'],
      artistLanguages: langs,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'songname': songname,
      'lyrics_si': lyricsSi,
      'lyrics_en': lyricsEn,
      'lyrics_ta': lyricsTa,
      'artist_id': artistId,
      'duration': duration,
      'notes': notes,
      'image': image,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'artist_name': artistName,
      'artist_image': artistImage,
      'artist_languages': artistLanguages,
    };
  }
}
