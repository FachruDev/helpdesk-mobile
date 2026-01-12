import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:helpdesk_mobile/config/app_colors.dart';
import 'package:helpdesk_mobile/data/models/ticket_model.dart';
import 'package:url_launcher/url_launcher.dart';

class AttachmentViewer extends StatelessWidget {
  final AttachmentModel attachment;
  final bool isSmall;

  const AttachmentViewer({
    super.key,
    required this.attachment,
    this.isSmall = false,
  });

  void _openAttachment(BuildContext context) async {
    if (attachment.isImage) {
      // Open image in full screen viewer
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(
              title: Text(attachment.fileName),
              backgroundColor: AppColors.black,
              actions: [
                IconButton(
                  icon: const Icon(Icons.download),
                  onPressed: () => _downloadFile(context),
                  tooltip: 'Download',
                ),
              ],
            ),
            backgroundColor: AppColors.black,
            body: Center(
              child: InteractiveViewer(
                child: CachedNetworkImage(
                  imageUrl: attachment.fileUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.error,
                    color: AppColors.error,
                    size: 50,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // For non-images, show options dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('File Options'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                attachment.fileName,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _formatFileSize(attachment.fileSize),
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                _downloadFile(context);
              },
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download/Open'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _downloadFile(BuildContext context) async {
    try {
      final uri = Uri.parse(attachment.fileUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot open file'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening file: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  String _formatFileSize(int? bytes) {
    if (bytes == null || bytes == 0) return 'Unknown size';
    
    const units = ['B', 'KB', 'MB', 'GB'];
    int unitIndex = 0;
    double size = bytes.toDouble();
    
    while (size >= 1024 && unitIndex < units.length - 1) {
      size /= 1024;
      unitIndex++;
    }
    
    return '${size.toStringAsFixed(1)} ${units[unitIndex]}';
  }

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 60.0 : 80.0;

    if (attachment.isImage) {
      return GestureDetector(
        onTap: () => _openAttachment(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CachedNetworkImage(
              imageUrl: attachment.fileUrl,
              fit: BoxFit.cover,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.broken_image,
                color: AppColors.error,
              ),
            ),
          ),
        ),
      );
    }

    // Non-image file
    return GestureDetector(
      onTap: () => _openAttachment(context),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.lightGray,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getFileIcon(attachment.fileName),
              color: AppColors.primary,
              size: isSmall ? 24 : 32,
            ),
            if (!isSmall) ...[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  _getFileExtension(attachment.fileName),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase();
    if (ext.endsWith('.pdf')) return Icons.picture_as_pdf;
    if (ext.endsWith('.doc') || ext.endsWith('.docx')) return Icons.description;
    if (ext.endsWith('.xls') || ext.endsWith('.xlsx')) return Icons.table_chart;
    if (ext.endsWith('.zip') || ext.endsWith('.rar')) return Icons.folder_zip;
    if (ext.endsWith('.txt')) return Icons.text_snippet;
    return Icons.insert_drive_file;
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    return parts.length > 1 ? parts.last.toUpperCase() : 'FILE';
  }
}
