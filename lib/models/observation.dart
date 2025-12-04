// lib/models/observation.dart

import 'media_item.dart';

class Observation {
  int? id;
  int hikeId; // Foreign key linking to Hike
  String caption;
  String content;
  String time; // Observation timestamp

  List<MediaItem> media; // List of media (images/videos)

  Observation({
    this.id,
    required this.hikeId,
    required this.caption,
    required this.content,
    required this.time,
    this.media = const [], // Initialize as empty
  });

  // Convert Observation object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'hikeId': hikeId,
      'caption': caption,
      'content': content,
      'time': time,
      // Note: media is not saved directly here, but stored in a separate table.
    };
  }

  // Create Observation object from Map
  factory Observation.fromMap(Map<String, dynamic> map) {
    return Observation(
      id: map['id'] as int?,
      hikeId: map['hikeId'] as int,
      caption: map['caption'] as String,
      content: map['content'] as String,
      time: map['time'] as String,
      // media will be added after fetching from DbHelper
      media: [],
    );
  }
}