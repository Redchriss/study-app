import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/constants/api_endpoints.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/design_tokens.dart';

class CourseworkExportSheet extends StatefulWidget {
  final String topic;
  final String deliverable;
  final String referencing;
  final List<Map<String, String>> sections;

  const CourseworkExportSheet({
    super.key,
    required this.topic,
    required this.deliverable,
    required this.referencing,
    required this.sections,
  });

  @override
  State<CourseworkExportSheet> createState() => _CourseworkExportSheetState();
}

class _CourseworkExportSheetState extends State<CourseworkExportSheet> {
  String _format = 'docx';
  bool _exporting = false;
  String? _downloadUrl;
  String? _filename;
  String? _error;

  Future<void> _export() async {
    setState(() {
      _exporting = true;
      _error = null;
      _downloadUrl = null;
    });

    final token = await SecureStorage.getToken();
    if (token == null) {
      setState(() {
        _exporting = false;
        _error = 'Session expired. Please log in again.';
      });
      return;
    }

    try {
      final response = await http.post(
        Uri.parse(ApiEndpoints.agentExport),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'topic': widget.topic,
          'deliverable': widget.deliverable,
          'format': _format,
          'referencing': widget.referencing,
          'sections': widget.sections,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        if (data['success'] == true) {
          setState(() {
            _downloadUrl = data['url'] as String?;
            _filename = data['filename'] as String?;
            _exporting = false;
          });
        } else {
          setState(() {
            _error = data['error']?.toString() ?? 'Export failed.';
            _exporting = false;
          });
        }
      } else {
        setState(() {
          _error = 'Server error (${response.statusCode}).';
          _exporting = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Connection error. Please try again.';
        _exporting = false;
      });
    }
  }

  String get _formatLabel {
    switch (_format) {
      case 'pptx':
        return 'PowerPoint (.pptx)';
      case 'pdf':
        return 'PDF (.pdf)';
      default:
        return 'Word (.docx)';
    }
  }

  IconData get _formatIcon {
    switch (_format) {
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      default:
        return Icons.description_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF7C4DFF), Color(0xFF1B6CA8)]),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.file_download_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Export Coursework',
                          style: TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 18)),
                      Text('${widget.sections.length} sections ready',
                          style: const TextStyle(
                              fontSize: 12,
                              color: DesignTokens.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Topic preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: dark
                    ? DesignTokens.darkSurfaceVariant
                    : DesignTokens.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.topic,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                      '${widget.deliverable}${widget.referencing.isNotEmpty ? " • ${widget.referencing}" : ""}',
                      style: const TextStyle(
                          fontSize: 12,
                          color: DesignTokens.textSecondary)),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Format selector
            const Text('Export format',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _FormatChip(
                  label: 'Word',
                  icon: Icons.description_rounded,
                  selected: _format == 'docx',
                  onTap: _exporting ? null : () => setState(() => _format = 'docx'),
                ),
                const SizedBox(width: 8),
                _FormatChip(
                  label: 'Slides',
                  icon: Icons.slideshow_rounded,
                  selected: _format == 'pptx',
                  onTap: _exporting
                      ? null
                      : () => setState(() => _format = 'pptx'),
                ),
                const SizedBox(width: 8),
                _FormatChip(
                  label: 'PDF',
                  icon: Icons.picture_as_pdf_rounded,
                  selected: _format == 'pdf',
                  onTap: _exporting ? null : () => setState(() => _format = 'pdf'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DesignTokens.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        size: 18, color: DesignTokens.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style: const TextStyle(
                              fontSize: 13, color: DesignTokens.error)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            if (_downloadUrl != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: DesignTokens.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: DesignTokens.success.withValues(alpha: 0.2)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(_formatIcon,
                            size: 24, color: DesignTokens.success),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Document ready!',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14)),
                              Text(_filename ?? '',
                                  style: const TextStyle(
                                      fontSize: 11,
                                      color: DesignTokens.textSecondary)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          // Open download URL
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: const Text('Download'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: DesignTokens.success,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ] else
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _exporting ? null : _export,
                  icon: _exporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Icon(_formatIcon, size: 18),
                  label: Text(_exporting
                      ? 'Generating $_formatLabel...'
                      : 'Generate $_formatLabel'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FormatChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback? onTap;

  const _FormatChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? DesignTokens.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected
                  ? DesignTokens.primary
                  : (Theme.of(context).brightness == Brightness.dark
                      ? DesignTokens.darkBorder
                      : DesignTokens.border),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 20,
                  color: selected
                      ? DesignTokens.primary
                      : DesignTokens.textSecondary),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? DesignTokens.primary
                          : DesignTokens.textSecondary)),
            ],
          ),
        ),
      ),
    );
  }
}
