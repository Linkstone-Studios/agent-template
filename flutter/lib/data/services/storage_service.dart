import 'package:image_picker/image_picker.dart';
import 'package:logging/logging.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../providers/supabase_provider.dart';

part 'storage_service.g.dart';

final _log = Logger('StorageService');

class StorageBuckets {
  StorageBuckets._();
  static const String userPhotos = 'user-photos';
  static const String chatAttachments = 'chat-attachments';
}

class UploadResult {
  const UploadResult({required this.publicUrl, required this.path});
  final String publicUrl;
  final String path;
}

@Riverpod(keepAlive: true)
class StorageService extends _$StorageService {
  static const _uuid = Uuid();

  @override
  void build() {}

  SupabaseClient get _client => ref.read(supabaseClientProvider);

  Future<UploadResult> uploadImage({
    required String bucket,
    required XFile file,
    String? folder,
    String? fileName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = _getFileExtension(file);
      final finalFileName = fileName ?? '${_uuid.v4()}$extension';
      final path = folder != null ? '$folder/$finalFileName' : finalFileName;

      _log.info('Uploading image to $bucket/$path (${bytes.length} bytes)');

      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: file.mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      _log.info('Upload successful: $publicUrl');

      return UploadResult(publicUrl: publicUrl, path: path);
    } catch (e, st) {
      _log.severe('Failed to upload image to $bucket: $e', e, st);
      rethrow;
    }
  }

  /// Upload any file type (not just images)
  Future<UploadResult> uploadFile({
    required String bucket,
    required XFile file,
    String? folder,
    String? fileName,
  }) async {
    try {
      final bytes = await file.readAsBytes();
      final extension = _getFileExtension(file);
      final finalFileName = fileName ?? '${_uuid.v4()}$extension';
      final path = folder != null ? '$folder/$finalFileName' : finalFileName;

      _log.info('Uploading file to $bucket/$path (${bytes.length} bytes)');

      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(contentType: file.mimeType, upsert: true),
          );

      final publicUrl = _client.storage.from(bucket).getPublicUrl(path);
      _log.info('Upload successful: $publicUrl');

      return UploadResult(publicUrl: publicUrl, path: path);
    } catch (e, st) {
      _log.severe('Failed to upload file to $bucket: $e', e, st);
      rethrow;
    }
  }

  String _getFileExtension(XFile file) {
    final name = file.name;
    final dotIndex = name.lastIndexOf('.');
    if (dotIndex != -1) {
      return name.substring(dotIndex);
    }
    return '.jpg';
  }
}
