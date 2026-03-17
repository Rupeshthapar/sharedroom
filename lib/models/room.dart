// models/room.dart
import 'dart:math';

class Room {
  final String code;
  final String name;
  final bool isOwner;
  final DateTime createdAt;
  final List<RoomMember> members;
  final List<SharedFile> files;

  const Room({
    required this.code,
    required this.name,
    required this.isOwner,
    required this.createdAt,
    this.members = const [],
    this.files = const [],
  });

  static String generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random.secure();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  Room copyWith({
    String? code,
    String? name,
    bool? isOwner,
    DateTime? createdAt,
    List<RoomMember>? members,
    List<SharedFile>? files,
  }) =>
      Room(
        code: code ?? this.code,
        name: name ?? this.name,
        isOwner: isOwner ?? this.isOwner,
        createdAt: createdAt ?? this.createdAt,
        members: members ?? this.members,
        files: files ?? this.files,
      );
}

class RoomMember {
  final String id;
  final String name;
  final String initials;
  final bool isOnline;
  final bool isOwner;

  const RoomMember({
    required this.id,
    required this.name,
    required this.initials,
    this.isOnline = false,
    this.isOwner = false,
  });
}

class SharedFile {
  final String id;
  final String name;
  final String extension;
  final int sizeBytes;
  final DateTime uploadedAt;
  final String uploadedBy;

  const SharedFile({
    required this.id,
    required this.name,
    required this.extension,
    required this.sizeBytes,
    required this.uploadedAt,
    required this.uploadedBy,
  });

  String get formattedSize {
    if (sizeBytes < 1024) return '${sizeBytes}B';
    if (sizeBytes < 1024 * 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)}KB';
    }
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(1)}MB';
  }

  String get fileIcon {
    switch (extension.toLowerCase()) {
      case 'pdf':
        return 'PDF';
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return 'IMG';
      case 'mp4':
      case 'mov':
      case 'avi':
        return 'VID';
      case 'zip':
      case 'rar':
      case '7z':
        return 'ZIP';
      case 'doc':
      case 'docx':
        return 'DOC';
      // FIX: xlsx and xls were missing — fell through to the default 'FILE'
      // which was misleading since the UI shows a green spreadsheet colour.
      case 'xlsx':
      case 'xls':
      case 'csv':
        return 'XLS';
      case 'ppt':
      case 'pptx':
        return 'PPT';
      case 'mp3':
      case 'wav':
      case 'aac':
        return 'AUD';
      default:
        return 'FILE';
    }
  }
}