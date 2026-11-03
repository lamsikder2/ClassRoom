import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/security/screen_protection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/components/empty_state.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  List<FileSystemEntity> _downloadedFiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDownloads();
  }

  Future<void> _loadDownloads() async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (await downloadDir.exists()) {
        final files = downloadDir.listSync().where((f) => f.path.endsWith('.pdf')).toList();
        setState(() {
          _downloadedFiles = files;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteDownload(FileSystemEntity file) async {
    try {
      await file.delete();
      _loadDownloads();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ডাউনলোড মুছে ফেলা হয়েছে')),
        );
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ডাউনলোডসমূহ', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _downloadedFiles.isEmpty
              ? const EmptyStateWidget(
                  icon: LucideIcons.downloadCloud,
                  title: 'কোনো ডাউনলোডকৃত শিট নেই',
                  description: 'ক্লাসের লেকচার শিট থেকে ডাউনলোড বাটনে চাপলে এখানে অফলাইনে পড়তে পারবে।',
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: _downloadedFiles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final file = _downloadedFiles[index];
                    final fileName = file.uri.pathSegments.last;

                    return Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.neutral200),
                      ),
                      child: ListTile(
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.errorContainer,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(LucideIcons.fileText, color: AppColors.error, size: 22),
                        ),
                        title: Text(
                          fileName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        subtitle: const Text('অফলাইন PDF ফাইল', style: TextStyle(fontSize: 12, color: AppColors.neutral500)),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.trash2, color: AppColors.error, size: 18),
                          onPressed: () => _deleteDownload(file),
                        ),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => OfflinePdfViewScreen(filePath: file.path, title: fileName),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),
    );
  }
}

class OfflinePdfViewScreen extends StatefulWidget {
  final String filePath;
  final String title;

  const OfflinePdfViewScreen({super.key, required this.filePath, required this.title});

  @override
  State<OfflinePdfViewScreen> createState() => _OfflinePdfViewScreenState();
}

class _OfflinePdfViewScreenState extends State<OfflinePdfViewScreen> {
  @override
  void initState() {
    super.initState();
    ScreenProtectionService.enableProtection();
  }

  @override
  void dispose() {
    ScreenProtectionService.disableProtection();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: PdfViewer.file(widget.filePath),
    );
  }
}

