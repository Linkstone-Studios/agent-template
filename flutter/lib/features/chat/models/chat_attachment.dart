import 'package:flutter/foundation.dart';

/// Type of attachment
enum AttachmentType {
  image,
  pdf,
  document,
  other;

  static AttachmentType fromMimeType(String? mimeType) {
    if (mimeType == null) return other;

    if (mimeType.startsWith('image/')) return image;
    if (mimeType == 'application/pdf') return pdf;
    if (mimeType.startsWith('application/') || mimeType.startsWith('text/')) {
      return document;
    }

    return other;
  }

  static AttachmentType fromExtension(String extension) {
    final ext = extension.toLowerCase();

    if (['.jpg', '.jpeg', '.png', '.gif', '.webp', '.heic'].contains(ext)) {
      return image;
    }
    if (ext == '.pdf') return pdf;
    if (['.doc', '.docx', '.txt', '.rtf', '.odt'].contains(ext)) {
      return document;
    }

    return other;
  }
}

/// Status of an attachment upload
enum AttachmentUploadStatus { pending, uploading, uploaded, failed }

/// A file attachment for a chat message
@immutable
class ChatAttachment {
  final String id;
  final String fileName;
  final AttachmentType type;
  final int? fileSizeBytes;
  final String? mimeType;
  final String? localPath; // Path on device before upload
  final String? storagePath; // Path in Supabase storage
  final String? publicUrl; // Public URL after upload
  final AttachmentUploadStatus uploadStatus;
  final double? uploadProgress;
  final String? thumbnailUrl; // For images/PDFs

  const ChatAttachment({
    required this.id,
    required this.fileName,
    required this.type,
    this.fileSizeBytes,
    this.mimeType,
    this.localPath,
    this.storagePath,
    this.publicUrl,
    this.uploadStatus = AttachmentUploadStatus.pending,
    this.uploadProgress,
    this.thumbnailUrl,
  });

  /// Create from local file (before upload)
  factory ChatAttachment.fromLocal({
    required String id,
    required String fileName,
    required String localPath,
    String? mimeType,
    int? fileSizeBytes,
  }) {
    final extension = fileName.contains('.')
        ? fileName.substring(fileName.lastIndexOf('.'))
        : '';

    return ChatAttachment(
      id: id,
      fileName: fileName,
      type: mimeType != null
          ? AttachmentType.fromMimeType(mimeType)
          : AttachmentType.fromExtension(extension),
      fileSizeBytes: fileSizeBytes,
      mimeType: mimeType,
      localPath: localPath,
      uploadStatus: AttachmentUploadStatus.pending,
    );
  }

  /// Copy with modifications
  ChatAttachment copyWith({
    String? id,
    String? fileName,
    AttachmentType? type,
    int? fileSizeBytes,
    String? mimeType,
    String? localPath,
    String? storagePath,
    String? publicUrl,
    AttachmentUploadStatus? uploadStatus,
    double? uploadProgress,
    String? thumbnailUrl,
  }) {
    return ChatAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      type: type ?? this.type,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      mimeType: mimeType ?? this.mimeType,
      localPath: localPath ?? this.localPath,
      storagePath: storagePath ?? this.storagePath,
      publicUrl: publicUrl ?? this.publicUrl,
      uploadStatus: uploadStatus ?? this.uploadStatus,
      uploadProgress: uploadProgress ?? this.uploadProgress,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
    );
  }

  /// Convert to JSON for storage/transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fileName': fileName,
      'type': type.name,
      'fileSizeBytes': fileSizeBytes,
      'mimeType': mimeType,
      'storagePath': storagePath,
      'publicUrl': publicUrl,
      'thumbnailUrl': thumbnailUrl,
    };
  }

  /// Create from JSON
  factory ChatAttachment.fromJson(Map<String, dynamic> json) {
    return ChatAttachment(
      id: json['id'] as String,
      fileName: json['fileName'] as String,
      type: AttachmentType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => AttachmentType.other,
      ),
      fileSizeBytes: json['fileSizeBytes'] as int?,
      mimeType: json['mimeType'] as String?,
      storagePath: json['storagePath'] as String?,
      publicUrl: json['publicUrl'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      uploadStatus:
          AttachmentUploadStatus.uploaded, // Assume uploaded if from JSON
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChatAttachment &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
