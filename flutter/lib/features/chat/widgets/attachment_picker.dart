import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

/// Widget that provides options to pick files/images for chat attachments
class AttachmentPicker extends StatelessWidget {
  final Function(List<XFile> files) onFilesPicked;

  const AttachmentPicker({
    super.key,
    required this.onFilesPicked,
  });

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    final picker = ImagePicker();
    final images = source == ImageSource.camera
        ? [await picker.pickImage(source: source)]
        : await picker.pickMultiImage();

    if (images.isNotEmpty) {
      final validImages = images.whereType<XFile>().toList();
      if (validImages.isNotEmpty) {
        onFilesPicked(validImages);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  Future<void> _pickFiles(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.isNotEmpty) {
      final files = result.files
          .where((f) => f.path != null)
          .map((f) => XFile(f.path!, 
              name: f.name, 
              bytes: f.bytes,
              length: f.size))
          .toList();
      
      if (files.isNotEmpty) {
        onFilesPicked(files);
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              child: Text(
                'Add Attachment',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Options
            _buildOption(
              context,
              icon: Icons.photo_library_rounded,
              title: 'Photo Library',
              subtitle: 'Choose from your photos',
              onTap: () => _pickImage(context, ImageSource.gallery),
            ),
            _buildOption(
              context,
              icon: Icons.camera_alt_rounded,
              title: 'Camera',
              subtitle: 'Take a photo',
              onTap: () => _pickImage(context, ImageSource.camera),
            ),
            _buildOption(
              context,
              icon: Icons.insert_drive_file_rounded,
              title: 'Document',
              subtitle: 'PDF, Word, or text file',
              onTap: () => _pickFiles(context),
            ),
            
            const SizedBox(height: 8),
            
            // Cancel
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: colorScheme.onPrimaryContainer),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

