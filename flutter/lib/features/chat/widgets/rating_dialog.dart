import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../data/models/models.dart';

/// Input data for conversation rating
class ConversationRatingInput {
  final int rating;
  final String? notes;

  ConversationRatingInput({required this.rating, this.notes});
}

/// Dialog for rating a conversation
///
/// Allows users to:
/// - Rate conversations 1-5 stars for quality
/// - Add optional notes about what worked well or needs improvement
/// - Update existing ratings
class RatingDialog extends StatefulWidget {
  final ConversationRatings? existingRating;

  const RatingDialog({super.key, this.existingRating});

  @override
  State<RatingDialog> createState() => _RatingDialogState();
}

class _RatingDialogState extends State<RatingDialog> {
  late int _rating;
  late TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    _rating = widget.existingRating?.rating ?? 3;
    _notesController = TextEditingController(
      text: widget.existingRating?.notes ?? '',
    );
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AlertDialog(
      title: Text(
        widget.existingRating != null ? 'Update Rating' : 'Rate Conversation',
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Star rating
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starNumber = index + 1;
                final isSelected = starNumber <= _rating;

                return IconButton(
                  icon: Icon(
                    isSelected ? CupertinoIcons.star_fill : CupertinoIcons.star,
                    color: isSelected
                        ? Colors.amber
                        : colorScheme.onSurfaceVariant,
                    size: 36,
                  ),
                  onPressed: () {
                    setState(() => _rating = starNumber);
                  },
                  tooltip: '$starNumber ${starNumber == 1 ? 'star' : 'stars'}',
                );
              }),
            ),
            const SizedBox(height: 8),

            // Rating description
            Text(
              _getRatingDescription(_rating),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'What worked well or could be improved?',
                border: const OutlineInputBorder(),
                helperText: 'Your feedback helps us improve AI performance',
                helperMaxLines: 2,
                alignLabelWithHint: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(
              context,
              ConversationRatingInput(
                rating: _rating,
                notes: _notesController.text.isEmpty
                    ? null
                    : _notesController.text.trim(),
              ),
            );
          },
          child: const Text('Save'),
        ),
      ],
    );
  }

  String _getRatingDescription(int rating) {
    switch (rating) {
      case 1:
        return 'Poor - Not helpful';
      case 2:
        return 'Below Average - Some issues';
      case 3:
        return 'Average - Acceptable quality';
      case 4:
        return 'Good - Helpful and accurate';
      case 5:
        return 'Excellent - Very helpful';
      default:
        return '';
    }
  }
}
