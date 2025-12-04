// lib/models/media_item.dart

class MediaItem {
  int? id;
  int observationId; // Foreign key linking to Observation
  String path; // File path (local file path)
  String type; // 'image' or 'video'

  MediaItem({
    this.id,
    required this.observationId,
    required this.path,
    required this.type,
  });

  // Convert MediaItem object to Map
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'observationId': observationId,
      'path': path,
      'type': type,
    };
  }

  // Create MediaItem object from Map
  factory MediaItem.fromMap(Map<String, dynamic> map) {
    return MediaItem(
      id: map['id'] as int?,
      observationId: map['observationId'] as int,
      path: map['path'] as String,
      type: map['type'] as String,
    );
  }
}
