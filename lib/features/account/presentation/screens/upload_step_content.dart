import 'package:flutter/material.dart';
import '../../../../core/theme/design_tokens.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../materials/presentation/widgets/youtube_search_picker.dart';
import 'upload_material_labels.dart';
import 'upload_material_manager.dart';
import 'upload_material_widgets.dart';

class UploadStepContent extends StatelessWidget {
  final UploadMaterialManager manager;
  final VoidCallback onStateChanged;

  const UploadStepContent({
    super.key,
    required this.manager,
    required this.onStateChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add your content',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(_contentSubtitle(),
              style: const TextStyle(
                  color: DesignTokens.textSecondary, fontSize: 13)),
          const SizedBox(height: 16),
          TextField(
            controller: manager.titleCtrl,
            decoration: InputDecoration(
              labelText: 'Title',
              hintText: UploadMaterialLabels.titlePlaceholder(
                  manager.contentType, manager.educationLevel),
              border: const OutlineInputBorder(),
            ),
            textInputAction: TextInputAction.next,
            onChanged: (_) => onStateChanged(),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: manager.descCtrl,
            decoration: InputDecoration(
              labelText: 'Description',
              hintText:
                  UploadMaterialLabels.descPlaceholder(manager.educationLevel),
              border: const OutlineInputBorder(),
              alignLabelWithHint: true,
            ),
            maxLines: 3,
            textInputAction: TextInputAction.next,
            onChanged: (_) => onStateChanged(),
          ),
          const SizedBox(height: 16),
          if (manager.contentType == 'video') ...[
            YouTubeSearchPicker(
              onSelected: (url) {
                manager.youtubeCtrl.text = url;
                onStateChanged();
              },
            ),
            const SizedBox(height: 12),
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: TextField(
                controller: manager.youtubeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Or paste YouTube URL',
                  hintText: 'https://www.youtube.com/watch?v=...',
                  isDense: true,
                ),
                onChanged: (_) => onStateChanged(),
              ),
            ),
          ],
          if (manager.contentType == 'text') ...[
            GlassCard(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Paste notes',
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w700)),
                  const SizedBox(height: 4),
                  Text(
                    'Paste notes, transcript text, or clean OCR text here.',
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: DesignTokens.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: manager.textCtrl,
                    decoration: const InputDecoration(
                      hintText: 'Paste your study content here...',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 8,
                    onChanged: (_) => onStateChanged(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (manager.requiresFile || manager.supportsOptionalFile) ...[
            FilePickerCard(
              fileButtonLabel:
                  UploadMaterialLabels.fileButtonLabel(manager.contentType),
              requiresFile: manager.requiresFile,
              selectedFile: manager.selectedFile,
              onPick: () {
                manager.pickFile();
                onStateChanged();
              },
            ),
          ],
          const SizedBox(height: 16),
          if (manager.canSuggestMetadata) _AiFillButton(manager: manager),
        ],
      ),
    );
  }

  String _contentSubtitle() {
    switch (manager.contentType) {
      case 'pdf':
        return 'Add a title, description, and upload your PDF file.';
      case 'text':
        return 'Add a title, description, and paste notes or attach a file.';
      case 'image':
        return 'Add a title, description, and upload your image.';
      case 'video':
        return 'Add a title, description, and link a YouTube video.';
      default:
        return 'Fill in the details below.';
    }
  }
}

class _AiFillButton extends StatelessWidget {
  final UploadMaterialManager manager;
  const _AiFillButton({required this.manager});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
        onTap: manager.suggesting
            ? null
            : () => manager.suggestMetadata(context),
        child: Ink(
          padding: const EdgeInsets.all(DesignTokens.spMd),
          decoration: BoxDecoration(
            gradient: DesignTokens.brandGradient,
            borderRadius: BorderRadius.circular(DesignTokens.radiusXl),
            boxShadow: DesignTokens.shadowMd(false),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(DesignTokens.radiusMd),
                ),
                child: manager.suggesting
                    ? const Padding(
                        padding: EdgeInsets.all(8),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.auto_awesome_rounded,
                        color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      manager.suggesting
                          ? 'Reading your material...'
                          : 'Fill with AI',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14),
                    ),
                    Text(
                      'Suggest title, subject & type \u00b7 1 credit',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
              if (!manager.suggesting)
                const Icon(Icons.chevron_right_rounded,
                    color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
