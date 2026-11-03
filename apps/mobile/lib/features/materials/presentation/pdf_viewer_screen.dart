import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../../core/security/screen_protection.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/drive_utils.dart';
import '../../../shared/components/empty_state.dart';
import '../../lessons/data/lessons_repository.dart';

class PdfViewerScreen extends ConsumerStatefulWidget {
  final String materialId;
  final LessonMaterialItem? initialMaterial;

  const PdfViewerScreen({
    super.key,
    required this.materialId,
    this.initialMaterial,
  });

  @override
  ConsumerState<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends ConsumerState<PdfViewerScreen> {
  LessonMaterialItem? _material;
  bool _isLoading = true;
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _localPdfPath;
  bool _useWebviewFallback = false;
  late WebViewController _webViewController;

  @override
  void initState() {
    super.initState();
    ScreenProtectionService.enableProtection();
    _material = widget.initialMaterial;
    _initPdf();
  }

  @override
  void dispose() {
    ScreenProtectionService.disableProtection();
    super.dispose();
  }

  Future<void> _initPdf() async {
    if (_material == null) {
      // Fetch material from repository if not passed in extra
      try {
        _material = await ref
            .read(lessonsRepositoryProvider)
            .getMaterialById(widget.materialId);
      } catch (e) {
        setState(() => _isLoading = false);
        return;
      }
    }

    final fileId = _material?.driveFileId;
    if (fileId == null || fileId.isEmpty) {
      setState(() => _isLoading = false);
      return;
    }

    // Initialize WebViewController fallback
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..loadRequest(Uri.parse(DriveUtils.getPreviewEmbedUrl(fileId)));

    // Check if file is already cached locally
    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      final localFile = File('${downloadDir.path}/${widget.materialId}.pdf');
      if (await localFile.exists()) {
        setState(() {
          _localPdfPath = localFile.path;
          _isLoading = false;
        });
        return;
      }
    } catch (_) {}

    setState(() => _isLoading = false);
  }

  Future<void> _downloadPdf() async {
    final fileId = _material?.driveFileId;
    if (fileId == null) return;

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
    });

    try {
      final dir = await getApplicationDocumentsDirectory();
      final downloadDir = Directory('${dir.path}/downloads');
      if (!await downloadDir.exists()) {
        await downloadDir.create(recursive: true);
      }
      final filePath = '${downloadDir.path}/${widget.materialId}.pdf';
      final downloadUrl = DriveUtils.getDirectDownloadUrl(fileId);

      final dio = Dio();
      await dio.download(
        downloadUrl,
        filePath,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            setState(() {
              _downloadProgress = received / total;
            });
          }
        },
      );

      setState(() {
        _localPdfPath = filePath;
        _isDownloading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('লেকচার শিট অফলাইনে সফলভাবে ডাউনলোড হয়েছে!'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isDownloading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text('ডাউনলোডে ত্রুটি: $e'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_material == null || _material!.driveFileId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('লেকচার শিট')),
        body: const EmptyStateWidget(
          title: 'শিট পাওয়া যায়নি',
          description: 'এই লেকচার শিটটির ফাইল আইডি বা লিঙ্ক পাওয়া যায়নি।',
        ),
      );
    }

    final fileId = _material!.driveFileId!;
    final directUrl = DriveUtils.getDirectDownloadUrl(fileId);

    return Scaffold(
      appBar: AppBar(
        title: Text(_material!.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          // Fallback toggle
          IconButton(
            tooltip: _useWebviewFallback ? 'নেটিভ রিডারে যান' : 'ওয়েব ভিউ ফলব্যাক',
            icon: Icon(_useWebviewFallback ? LucideIcons.fileText : LucideIcons.globe),
            onPressed: () => setState(() => _useWebviewFallback = !_useWebviewFallback),
          ),
          if (_material!.allowDownload) ...[
            if (_isDownloading)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      value: _downloadProgress > 0 ? _downloadProgress : null,
                    ),
                  ),
                ),
              )
            else
              IconButton(
                tooltip: _localPdfPath != null ? 'ইতিমধ্যে সেভ হয়েছে' : 'ডাউনলোড করুন',
                icon: Icon(
                  _localPdfPath != null ? LucideIcons.checkCircle2 : LucideIcons.download,
                  color: _localPdfPath != null ? AppColors.success : null,
                ),
                onPressed: _downloadPdf,
              ),
          ],
        ],
      ),
      body: _useWebviewFallback
          ? WebViewWidget(controller: _webViewController)
          : _localPdfPath != null
              ? PdfViewer.file(_localPdfPath!)
              : PdfViewer.uri(
                  Uri.parse(directUrl),
                  params: PdfViewerParams(
                    errorBannerBuilder: (context, error, stackTrace, documentRef) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'নেটিভ রিডারে ফাইল লোড করা যায়নি',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 12),
                            ElevatedButton.icon(
                              onPressed: () => setState(() => _useWebviewFallback = true),
                              icon: const Icon(LucideIcons.globe, size: 16),
                              label: const Text('ড্রাইভ ওয়েবভিউতে খুলুন'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
