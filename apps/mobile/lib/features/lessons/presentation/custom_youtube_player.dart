import 'dart:async';
import 'package:chewie/chewie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_colors.dart';

class CustomYoutubePlayer extends StatefulWidget {
  final String youtubeUrl;
  final bool autoPlay;
  final bool looping;
  final VoidCallback? onVideoEnd;
  final ValueChanged<Duration>? onPositionChanged;

  const CustomYoutubePlayer({
    super.key,
    required this.youtubeUrl,
    this.autoPlay = false,
    this.looping = false,
    this.onVideoEnd,
    this.onPositionChanged,
  });

  @override
  State<CustomYoutubePlayer> createState() => _CustomYoutubePlayerState();
}

class _CustomYoutubePlayerState extends State<CustomYoutubePlayer> {
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _webIframeController;
  YoutubeExplode? _ytExplode;

  bool _isLoading = true;
  String? _errorMessage;
  bool _useIframeFallback = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(CustomYoutubePlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.youtubeUrl != widget.youtubeUrl) {
      _disposeControllers();
      _initializePlayer();
    }
  }

  String _extractVideoId(String input) {
    String trimmed = input.trim();
    if (trimmed.contains('v=')) {
      return trimmed.split('v=')[1].split('&')[0];
    } else if (trimmed.contains('youtu.be/')) {
      return trimmed.split('youtu.be/')[1].split('?')[0];
    }
    return trimmed;
  }

  Future<void> _initializePlayer() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _useIframeFallback = false;
    });

    final videoId = _extractVideoId(widget.youtubeUrl);

    // Browser CORS Limitation:
    // Web browsers strictly enforce CORS and block direct stream chunks from googlevideo.com.
    // Therefore, in Web browsers, we use the YouTube HTML5 embed.
    // On Android/iOS Native (the installed APK), we extract and play the direct raw stream with ZERO YouTube branding!
    if (kIsWeb) {
      _initWebIframe(videoId);
      return;
    }

    _ytExplode = YoutubeExplode();

    try {
      final targetUrl = 'https://www.youtube.com/watch?v=$videoId';

      // 1. Fetch manifest with 8-second timeout to prevent infinite hang
      final manifest = await _ytExplode!.videos.streamsClient
          .getManifest(targetUrl)
          .timeout(const Duration(seconds: 8));

      // 2. Select highest bitrate muxed stream (audio + video combined)
      final streamInfo = manifest.muxed.withHighestBitrate();
      final streamUri = streamInfo.url;

      // Close explode client as soon as stream URL is obtained
      _ytExplode?.close();
      _ytExplode = null;

      if (!mounted) return;

      // 3. Initialize VideoPlayerController with raw direct stream URL
      _videoPlayerController = VideoPlayerController.networkUrl(streamUri);
      await _videoPlayerController!.initialize().timeout(const Duration(seconds: 10));

      if (!mounted) return;

      // 4. Initialize ChewieController with zero YouTube branding
      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController!,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController!.value.aspectRatio > 0
            ? _videoPlayerController!.value.aspectRatio
            : 16 / 9,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
        showControls: true,
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary500,
          handleColor: AppColors.primary600,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        cupertinoProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary500,
          handleColor: AppColors.primary600,
          backgroundColor: Colors.white24,
          bufferedColor: Colors.white38,
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    errorMessage,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        },
      );

      // Track progress
      int lastReportedSec = 0;
      _videoPlayerController!.addListener(() {
        if (_videoPlayerController == null || !_videoPlayerController!.value.isInitialized) return;
        final pos = _videoPlayerController!.value.position;
        if (widget.onPositionChanged != null) {
          final curSec = pos.inSeconds;
          if ((curSec - lastReportedSec).abs() >= 5) {
            lastReportedSec = curSec;
            widget.onPositionChanged!(pos);
          }
        }
        if (widget.onVideoEnd != null && pos >= _videoPlayerController!.value.duration) {
          widget.onVideoEnd!();
        }
      });

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Direct stream extraction error: $e. Falling back to embed player.');
      // Safe fallback to Iframe on mobile if stream extraction fails (e.g. YouTube cipher challenge)
      if (mounted) {
        _initWebIframe(videoId);
      }
    } finally {
      _ytExplode?.close();
      _ytExplode = null;
    }
  }

  void _initWebIframe(String videoId) {
    _webIframeController?.close();
    _webIframeController = YoutubePlayerController.fromVideoId(
      videoId: videoId,
      autoPlay: widget.autoPlay,
      params: const YoutubePlayerParams(
        showFullscreenButton: true,
        showControls: true,
        enableCaption: false,
        playsInline: true,
      ),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        _useIframeFallback = true;
      });
    }
  }

  void _disposeControllers() {
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _webIframeController?.close();
    _videoPlayerController = null;
    _chewieController = null;
    _webIframeController = null;
    _ytExplode?.close();
    _ytExplode = null;
  }

  @override
  void dispose() {
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: Colors.black,
          child: const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary500),
                ),
                SizedBox(height: 12),
                Text(
                  'ভিডিও স্ট্রিম প্রস্তুত হচ্ছে...',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_useIframeFallback && _webIframeController != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: YoutubePlayer(
          controller: _webIframeController!,
          aspectRatio: 16 / 9,
        ),
      );
    }

    if (_errorMessage != null) {
      return AspectRatio(
        aspectRatio: 16 / 9,
        child: Container(
          color: AppColors.neutral900,
          padding: const EdgeInsets.all(16),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(LucideIcons.alertTriangle, color: AppColors.error, size: 36),
                const SizedBox(height: 8),
                Text(
                  _errorMessage!,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('আবার চেষ্টা করুন'),
                  onPressed: _initializePlayer,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return AspectRatio(
        aspectRatio: _chewieController!.aspectRatio ?? 16 / 9,
        child: Chewie(controller: _chewieController!),
      );
    }

    return const AspectRatio(
      aspectRatio: 16 / 9,
      child: ColoredBox(color: Colors.black),
    );
  }
}
