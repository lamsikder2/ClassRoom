import 'dart:async';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/bengali_utils.dart';

class CustomVideoControls extends StatefulWidget {
  final YoutubePlayerController controller;
  final String title;
  final bool isFullscreen;
  final VoidCallback onToggleFullscreen;
  final Duration? fallbackDuration;

  const CustomVideoControls({
    super.key,
    required this.controller,
    required this.title,
    required this.isFullscreen,
    required this.onToggleFullscreen,
    this.fallbackDuration,
  });

  @override
  State<CustomVideoControls> createState() => _CustomVideoControlsState();
}

class _CustomVideoControlsState extends State<CustomVideoControls> {
  bool _showControls = true;
  Timer? _hideTimer;
  double _currentPositionSec = 0;
  bool _isDragging = false;
  double _dragValue = 0;
  StreamSubscription? _videoStateSub;
  double _currentSpeed = 1.0;

  @override
  void initState() {
    super.initState();
    _startHideTimer();

    // Listen to continuous position updates
    _videoStateSub = widget.controller.videoStateStream.listen((state) {
      if (!_isDragging && mounted) {
        setState(() {
          _currentPositionSec = state.position.inMilliseconds / 1000.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _videoStateSub?.cancel();
    super.dispose();
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && _showControls && !_isDragging) {
        setState(() => _showControls = false);
      }
    });
  }

  void _toggleControls() {
    setState(() {
      _showControls = !_showControls;
    });
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _onUserInteraction() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _startHideTimer();
  }

  String _formatDuration(double seconds) {
    if (seconds.isNaN || seconds.isInfinite || seconds < 0) return '00:00';
    final int sec = seconds.round();
    final int hours = sec ~/ 3600;
    final int minutes = (sec % 3600) ~/ 60;
    final int remainingSec = sec % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${remainingSec.toString().padLeft(2, '0')}';
  }

  Future<void> _seekRelative(int seconds) async {
    _onUserInteraction();
    final total = _getTotalDurationSeconds();
    final cur = await widget.controller.currentTime;
    final target = (cur + seconds).clamp(0.0, total);
    widget.controller.seekTo(seconds: target);
    setState(() {
      _currentPositionSec = target;
    });
  }

  double _getTotalDurationSeconds() {
    final metaDuration = widget.controller.metadata.duration.inMilliseconds / 1000.0;
    if (metaDuration > 0) return metaDuration;
    if (widget.fallbackDuration != null && widget.fallbackDuration!.inSeconds > 0) {
      return widget.fallbackDuration!.inMilliseconds / 1000.0;
    }
    return 0.0;
  }

  void _showSpeedPicker() {
    _onUserInteraction();
    final speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.neutral900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'প্লেব্যাক স্পিড নির্বাচন করুন',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: AppColors.neutral700),
                ...speeds.map((s) {
                  final isSelected = (_currentSpeed - s).abs() < 0.05;
                  return ListTile(
                    dense: true,
                    leading: Icon(
                      isSelected ? LucideIcons.check : LucideIcons.circle,
                      color: isSelected ? AppColors.primary400 : AppColors.neutral500,
                      size: 18,
                    ),
                    title: Text(
                      '${s}x ${s == 1.0 ? "(স্বাভাবিক)" : ""}',
                      style: TextStyle(
                        color: isSelected ? AppColors.primary400 : Colors.white,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    onTap: () {
                      widget.controller.setPlaybackRate(s);
                      setState(() => _currentSpeed = s);
                      Navigator.pop(ctx);
                      _onUserInteraction();
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return YoutubeValueBuilder(
      controller: widget.controller,
      builder: (context, value) {
        final isPlaying = value.playerState == PlayerState.playing;
        final isBuffering = value.playerState == PlayerState.buffering;
        final totalDurationSec = _getTotalDurationSeconds();
        final currentPosition = _isDragging ? _dragValue : _currentPositionSec;
        final safeTotal = totalDurationSec > 0 ? totalDurationSec : 1.0;
        final progressVal = (currentPosition / safeTotal).clamp(0.0, 1.0);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _toggleControls,
          child: AnimatedOpacity(
            opacity: _showControls ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: IgnorePointer(
              ignoring: !_showControls,
              child: Container(
                color: Colors.black.withOpacity(0.55),
                child: Stack(
                  children: [
                    // Top Bar (Back button, Title, Speed)
                    Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        bottom: false,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Row(
                            children: [
                              if (widget.isFullscreen)
                                IconButton(
                                  icon: const Icon(LucideIcons.arrowLeft, color: Colors.white, size: 22),
                                  onPressed: widget.onToggleFullscreen,
                                ),
                              Expanded(
                                child: Text(
                                  widget.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(color: Colors.black, blurRadius: 4),
                                    ],
                                  ),
                                ),
                              ),
                              // Speed button
                              TextButton(
                                onPressed: _showSpeedPicker,
                                style: TextButton.styleFrom(
                                  backgroundColor: Colors.white.withOpacity(0.15),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                ),
                                child: Text(
                                  '${_currentSpeed}x',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Center Controls: Rewind 10s | Play/Pause | Forward 10s
                    Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // 10s Rewind
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(LucideIcons.rotateCcw, color: Colors.white),
                            tooltip: '১০ সেকেন্ড পেছনে',
                            onPressed: () => _seekRelative(-10),
                          ),
                          const SizedBox(width: 24),

                          // Play / Pause / Buffering
                          if (isBuffering)
                            const SizedBox(
                              width: 56,
                              height: 56,
                              child: CircularProgressIndicator(
                                strokeWidth: 3,
                                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary400),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.primary600.withOpacity(0.9),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: IconButton(
                                iconSize: 42,
                                icon: Icon(
                                  isPlaying ? LucideIcons.pause : LucideIcons.play,
                                  color: Colors.white,
                                ),
                                onPressed: () {
                                  _onUserInteraction();
                                  if (isPlaying) {
                                    widget.controller.pauseVideo();
                                  } else {
                                    widget.controller.playVideo();
                                  }
                                },
                              ),
                            ),
                          const SizedBox(width: 24),

                          // 10s Forward
                          IconButton(
                            iconSize: 36,
                            icon: const Icon(LucideIcons.rotateCw, color: Colors.white),
                            tooltip: '১০ সেকেন্ড সামনে',
                            onPressed: () => _seekRelative(10),
                          ),
                        ],
                      ),
                    ),

                    // Bottom Bar (Progress slider, time indicators, fullscreen toggle)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                        top: false,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withOpacity(0.8),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Slider
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.5,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                                  overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                                  activeTrackColor: AppColors.primary400,
                                  inactiveTrackColor: Colors.white.withOpacity(0.25),
                                  thumbColor: AppColors.primary400,
                                  overlayColor: AppColors.primary400.withOpacity(0.2),
                                ),
                                child: Slider(
                                  value: progressVal,
                                  onChanged: (val) {
                                    _onUserInteraction();
                                    setState(() {
                                      _isDragging = true;
                                      _dragValue = val * safeTotal;
                                    });
                                  },
                                  onChangeEnd: (val) {
                                    final target = val * safeTotal;
                                    widget.controller.seekTo(seconds: target);
                                    setState(() {
                                      _isDragging = false;
                                      _currentPositionSec = target;
                                    });
                                    _startHideTimer();
                                  },
                                ),
                              ),

                              // Time indicators and Fullscreen toggle
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  children: [
                                    Text(
                                      BengaliUtils.toBengaliNumerals(
                                          '${_formatDuration(currentPosition)} / ${_formatDuration(totalDurationSec)}'),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    const Spacer(),
                                    IconButton(
                                      iconSize: 20,
                                      icon: Icon(
                                        widget.isFullscreen
                                            ? LucideIcons.minimize2
                                            : LucideIcons.maximize2,
                                        color: Colors.white,
                                      ),
                                      tooltip: widget.isFullscreen
                                          ? 'ফুলস্ক্রিন বন্ধ করুন'
                                          : 'ফুলস্ক্রিন করুন',
                                      onPressed: () {
                                        _onUserInteraction();
                                        widget.onToggleFullscreen();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
